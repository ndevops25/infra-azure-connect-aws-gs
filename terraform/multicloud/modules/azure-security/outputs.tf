# modules/azure-security/outputs.tf

output "firewall_id" {
  description = "ID do Azure Firewall (se habilitado)"
  value       = var.enable_firewall ? azurerm_firewall.main[0].id : null
}

output "firewall_name" {
  description = "Nome do Azure Firewall (se habilitado)"
  value       = var.enable_firewall ? azurerm_firewall.main[0].name : null
}

output "firewall_private_ip" {
  description = "IP privado do Azure Firewall (se habilitado)"
  value       = var.enable_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
}

output "firewall_public_ip" {
  description = "IP público do Azure Firewall (se habilitado)"
  value       = var.enable_firewall ? azurerm_public_ip.firewall[0].ip_address : null
}

output "firewall_policy_id" {
  description = "ID da Firewall Policy (se habilitada)"
  value       = var.enable_firewall ? azurerm_firewall_policy.main[0].id : null
}

output "network_watcher_id" {
  description = "ID do Network Watcher (se habilitado)"
  value       = var.enable_network_watcher ? azurerm_network_watcher.main[0].id : null
}

output "network_watcher_name" {
  description = "Nome do Network Watcher (se habilitado)"
  value       = var.enable_network_watcher ? azurerm_network_watcher.main[0].name : null
}

output "flow_log_id" {
  description = "ID do Flow Log (se habilitado)"
  value       = var.enable_flow_logs && var.enable_network_watcher ? azurerm_network_watcher_flow_log.main[0].id : null
}

output "ddos_protection_plan_id" {
  description = "ID do DDoS Protection Plan (se habilitado)"
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.main[0].id : null
}

output "bastion_id" {
  description = "ID do Azure Bastion (se habilitado)"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].id : null
}

output "bastion_dns_name" {
  description = "DNS name do Azure Bastion (se habilitado)"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].dns_name : null
}

output "bastion_public_ip" {
  description = "IP público do Azure Bastion (se habilitado)"
  value       = var.enable_bastion ? azurerm_public_ip.bastion[0].ip_address : null
}

output "application_security_groups" {
  description = "IDs dos Application Security Groups (se criados)"
  value = var.create_application_security_groups ? {
    web        = azurerm_application_security_group.web[0].id
    database   = azurerm_application_security_group.database[0].id
    management = azurerm_application_security_group.management[0].id
  } : {}
}

output "security_status" {
  description = "Status da configuração de segurança"
  value = {
    firewall_enabled               = var.enable_firewall
    firewall_sku                  = var.enable_firewall ? var.firewall_sku : null
    network_watcher_enabled       = var.enable_network_watcher
    flow_logs_enabled             = var.enable_flow_logs && var.enable_network_watcher
    traffic_analytics_enabled     = var.enable_traffic_analytics
    ddos_protection_enabled       = var.enable_ddos_protection
    bastion_enabled              = var.enable_bastion
    application_security_groups_created = var.create_application_security_groups
    threat_intelligence_mode     = var.enable_firewall ? var.threat_intelligence_mode : null
    intrusion_detection_mode     = var.enable_firewall ? var.intrusion_detection_mode : null
    security_level              = var.enable_firewall && var.enable_ddos_protection ? "Enterprise" : var.enable_firewall ? "Enhanced" : "Basic"
  }
}

output "security_components" {
  description = "Componentes de segurança criados"
  value = {
    firewall = var.enable_firewall ? {
      id         = azurerm_firewall.main[0].id
      name       = azurerm_firewall.main[0].name
      private_ip = azurerm_firewall.main[0].ip_configuration[0].private_ip_address
      public_ip  = azurerm_public_ip.firewall[0].ip_address
    } : null
    
    network_watcher = var.enable_network_watcher ? {
      id   = azurerm_network_watcher.main[0].id
      name = azurerm_network_watcher.main[0].name
    } : null
    
    bastion = var.enable_bastion ? {
      id        = azurerm_bastion_host.main[0].id
      dns_name  = azurerm_bastion_host.main[0].dns_name
      public_ip = azurerm_public_ip.bastion[0].ip_address
    } : null
  }
}

output "cost_estimation" {
  description = "Estimativa de custos dos componentes de segurança"
  value = {
    monthly_cost_usd = (
      (var.enable_firewall ? (var.firewall_sku == "Premium" ? 625 : 544) : 0) +
      (var.enable_ddos_protection ? 2944 : 0) +
      (var.enable_bastion ? 140 : 0) +
      (var.enable_flow_logs ? 5 : 0)
    )
    breakdown = {
      firewall         = var.enable_firewall ? "${var.firewall_sku == "Premium" ? 625 : 544} USD" : "0 USD"
      ddos_protection  = var.enable_ddos_protection ? "2944 USD" : "0 USD"
      bastion         = var.enable_bastion ? "140 USD" : "0 USD"
      flow_logs       = var.enable_flow_logs ? "5 USD" : "0 USD"
      network_watcher = var.enable_network_watcher ? "Included" : "0 USD"
    }
    recommendation = (
      (var.enable_firewall ? (var.firewall_sku == "Premium" ? 625 : 544) : 0) +
      (var.enable_ddos_protection ? 2944 : 0) +
      (var.enable_bastion ? 140 : 0)
    ) > 500 ? "Consider disabling expensive features for development" : "Cost-effective configuration"
  }
}