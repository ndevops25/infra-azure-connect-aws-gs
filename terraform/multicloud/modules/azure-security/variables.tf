# modules/azure-security/variables.tf

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "location" {
  description = "Localização Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

# Azure Firewall
variable "enable_firewall" {
  description = "Habilitar Azure Firewall (caro ~$544/mês)"
  type        = bool
  default     = false
}

variable "firewall_subnet_id" {
  description = "ID do subnet do firewall"
  type        = string
  default     = ""
}

variable "firewall_sku" {
  description = "SKU do Azure Firewall"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku)
    error_message = "Firewall SKU deve ser Standard ou Premium."
  }
}

variable "firewall_zones" {
  description = "Availability zones para Azure Firewall"
  type        = list(string)
  default     = []
}

variable "threat_intelligence_mode" {
  description = "Modo de threat intelligence"
  type        = string
  default     = "Alert"
  
  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.threat_intelligence_mode)
    error_message = "Threat intelligence mode deve ser Off, Alert ou Deny."
  }
}

variable "intrusion_detection_mode" {
  description = "Modo de detecção de intrusão (apenas Premium SKU)"
  type        = string
  default     = "Off"  # Padrão Off para compatibilidade com Standard
  
  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.intrusion_detection_mode)
    error_message = "Intrusion detection mode deve ser Off, Alert ou Deny."
  }
}

variable "dns_proxy_enabled" {
  description = "Habilitar DNS proxy no firewall"
  type        = bool
  default     = false
}

variable "custom_dns_servers" {
  description = "Servidores DNS customizados"
  type        = list(string)
  default     = []
}

# Endereços permitidos para regras de firewall
variable "azure_source_cidrs" {
  description = "CIDRs de origem Azure permitidos"
  type        = list(string)
  default     = ["10.1.0.0/16", "10.1.10.0/24"]
}

variable "azure_destination_cidrs" {
  description = "CIDRs de destino Azure permitidos"
  type        = list(string)
  default     = ["10.1.0.0/16", "10.1.10.0/24"]
}

variable "aws_source_cidrs" {
  description = "CIDRs de origem AWS permitidos"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "aws_destination_cidrs" {
  description = "CIDRs de destino AWS permitidos"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

# DNAT Rules
variable "enable_dnat_rules" {
  description = "Habilitar regras DNAT"
  type        = bool
  default     = false
}

variable "dnat_rules" {
  description = "Regras DNAT para o firewall"
  type = list(object({
    name               = string
    source_addresses   = list(string)
    destination_ports  = list(string)
    translated_address = string
    translated_port    = string
    protocols          = list(string)
  }))
  default = []
}

# Network Watcher
variable "enable_network_watcher" {
  description = "Habilitar Network Watcher para diagnósticos"
  type        = bool
  default     = true
}

# Flow Logs
variable "enable_flow_logs" {
  description = "Habilitar Flow Logs"
  type        = bool
  default     = false
}

variable "nsg_id_for_flow_logs" {
  description = "ID do NSG para Flow Logs"
  type        = string
  default     = ""
}

variable "storage_account_id_for_logs" {
  description = "ID da Storage Account para logs"
  type        = string
  default     = ""
}

variable "flow_logs_retention_days" {
  description = "Dias de retenção para Flow Logs"
  type        = number
  default     = 30
}

variable "enable_traffic_analytics" {
  description = "Habilitar Traffic Analytics"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace"
  type        = string
  default     = ""
}

variable "log_analytics_workspace_resource_id" {
  description = "Resource ID do Log Analytics Workspace"
  type        = string
  default     = ""
}

# DDoS Protection
variable "enable_ddos_protection" {
  description = "Habilitar DDoS Protection Plan (caro ~$2944/mês)"
  type        = bool
  default     = false
}

# Azure Bastion
variable "enable_bastion" {
  description = "Habilitar Azure Bastion (~$140/mês)"
  type        = bool
  default     = false
}

variable "vnet_name" {
  description = "Nome da VNET para Bastion (se habilitado)"
  type        = string
  default     = ""
}

variable "bastion_subnet_cidr" {
  description = "CIDR para Bastion Subnet"
  type        = string
  default     = "10.1.5.0/26"
}

variable "bastion_sku" {
  description = "SKU do Azure Bastion"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "Bastion SKU deve ser Basic ou Standard."
  }
}

# Application Security Groups
variable "create_application_security_groups" {
  description = "Criar Application Security Groups"
  type        = bool
  default     = false
}

# Configurações herdadas (compatibilidade)
variable "allowed_source_cidrs" {
  description = "CIDRs de origem permitidos (compatibilidade)"
  type        = list(string)
  default     = ["10.1.0.0/16", "10.1.10.0/24"]
}

variable "allowed_destination_cidrs" {
  description = "CIDRs de destino permitidos (compatibilidade)"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}