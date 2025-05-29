# modules/azure-security/main.tf
# Módulo Azure Security - Versão Completa

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Public IP para Azure Firewall
resource "azurerm_public_ip" "firewall" {
  count = var.enable_firewall ? 1 : 0
  
  name                = "pip-fw-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.firewall_zones
  
  tags = var.tags
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  count = var.enable_firewall ? 1 : 0
  
  name                = "fw-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku
  firewall_policy_id  = azurerm_firewall_policy.main[0].id
  zones               = var.firewall_zones

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  tags = var.tags
}

# Firewall Policy
resource "azurerm_firewall_policy" "main" {
  count = var.enable_firewall ? 1 : 0
  
  name                     = "fp-${var.project_name}-${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.firewall_sku
  threat_intelligence_mode = var.threat_intelligence_mode
  
  dns {
    proxy_enabled = var.dns_proxy_enabled
    servers       = var.custom_dns_servers
  }

  # Intrusion Detection só funciona com SKU Premium
  dynamic "intrusion_detection" {
    for_each = var.firewall_sku == "Premium" ? [1] : []
    content {
      mode = var.intrusion_detection_mode
    }
  }

  tags = var.tags
}

# Firewall Policy Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "main" {
  count = var.enable_firewall ? 1 : 0
  
  name               = "frcg-${var.project_name}-${var.environment}"
  firewall_policy_id = azurerm_firewall_policy.main[0].id
  priority           = 500

  # Network Rules Collection
  network_rule_collection {
    name     = "network_rules"
    priority = 400
    action   = "Allow"

    # Permitir tráfego entre Azure e AWS
    rule {
      name                  = "allow_azure_to_aws"
      protocols             = ["TCP", "UDP", "ICMP"]
      source_addresses      = var.azure_source_cidrs
      destination_addresses = var.aws_destination_cidrs
      destination_ports     = ["*"]
    }

    rule {
      name                  = "allow_aws_to_azure"
      protocols             = ["TCP", "UDP", "ICMP"]
      source_addresses      = var.aws_source_cidrs
      destination_addresses = var.azure_destination_cidrs
      destination_ports     = ["*"]
    }

    # Permitir tráfego interno do Azure
    rule {
      name                  = "allow_azure_internal"
      protocols             = ["TCP", "UDP", "ICMP"]
      source_addresses      = var.azure_source_cidrs
      destination_addresses = var.azure_destination_cidrs
      destination_ports     = ["*"]
    }

    # Permitir DNS
    rule {
      name                  = "allow_dns"
      protocols             = ["TCP", "UDP"]
      source_addresses      = var.azure_source_cidrs
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    # Permitir NTP
    rule {
      name                  = "allow_ntp"
      protocols             = ["UDP"]
      source_addresses      = var.azure_source_cidrs
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }

  # Application Rules Collection
  application_rule_collection {
    name     = "application_rules"
    priority = 300
    action   = "Allow"

    # Permitir HTTP/HTTPS básico
    rule {
      name = "allow_web_browsing"
      source_addresses = var.azure_source_cidrs

      protocols {
        type = "Http"
        port = 80
      }
      
      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "*.microsoft.com",
        "*.ubuntu.com",
        "*.debian.org",
        "security.ubuntu.com",
        "archive.ubuntu.com",
        "*.amazonaws.com"
      ]
    }

    # Permitir atualizações do sistema
    rule {
      name = "allow_system_updates"
      source_addresses = var.azure_source_cidrs

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "download.microsoft.com",
        "*.windowsupdate.com",
        "update.microsoft.com",
        "*.download.windowsupdate.com"
      ]
    }
  }

  # DNAT Rules Collection (se necessário)
  dynamic "nat_rule_collection" {
    for_each = var.enable_dnat_rules ? [1] : []
    content {
      name     = "dnat_rules"
      priority = 200
      action   = "Dnat"

      dynamic "rule" {
        for_each = var.dnat_rules
        content {
          name                = rule.value.name
          source_addresses    = rule.value.source_addresses
          destination_address = azurerm_public_ip.firewall[0].ip_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_port     = rule.value.translated_port
          protocols           = rule.value.protocols
        }
      }
    }
  }
}

# Network Watcher para diagnósticos
resource "azurerm_network_watcher" "main" {
  count = var.enable_network_watcher ? 1 : 0
  
  name                = "nw-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Flow Logs (se habilitado)
resource "azurerm_network_watcher_flow_log" "main" {
  count = var.enable_flow_logs && var.enable_network_watcher ? 1 : 0
  
  network_watcher_name = azurerm_network_watcher.main[0].name
  resource_group_name  = var.resource_group_name
  name                 = "fl-${var.project_name}-${var.environment}"

  network_security_group_id = var.nsg_id_for_flow_logs
  storage_account_id       = var.storage_account_id_for_logs
  enabled                  = true
  version                  = 2

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  traffic_analytics {
    enabled               = var.enable_traffic_analytics
    workspace_id          = var.log_analytics_workspace_id
    workspace_region      = var.location
    workspace_resource_id = var.log_analytics_workspace_resource_id
    interval_in_minutes   = 10
  }

  tags = var.tags
}

# Azure DDoS Protection Plan (se habilitado e ambiente prod)
resource "azurerm_network_ddos_protection_plan" "main" {
  count = var.enable_ddos_protection ? 1 : 0
  
  name                = "ddos-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Azure Bastion (se habilitado)
resource "azurerm_subnet" "bastion" {
  count = var.enable_bastion ? 1 : 0
  
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.bastion_subnet_cidr]
}

resource "azurerm_public_ip" "bastion" {
  count = var.enable_bastion ? 1 : 0
  
  name                = "pip-bastion-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_bastion_host" "main" {
  count = var.enable_bastion ? 1 : 0
  
  name                = "bastion-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.bastion_sku

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = var.tags
}

# Application Security Groups
resource "azurerm_application_security_group" "web" {
  count = var.create_application_security_groups ? 1 : 0
  
  name                = "asg-web-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_application_security_group" "database" {
  count = var.create_application_security_groups ? 1 : 0
  
  name                = "asg-db-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_application_security_group" "management" {
  count = var.create_application_security_groups ? 1 : 0
  
  name                = "asg-mgmt-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}