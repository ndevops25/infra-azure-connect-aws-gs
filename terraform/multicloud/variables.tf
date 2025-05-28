# variables.tf - Variáveis principais do projeto

# ==========================================
# CONFIGURAÇÕES BÁSICAS DO PROJETO
# ==========================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "xpto-corp"
  
  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 15
    error_message = "Project name deve ter entre 3 e 15 caracteres."
  }
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser dev, staging ou prod."
  }
}

variable "cost_center" {
  description = "Centro de custo para billing"
  type        = string
  default     = "IT-Infrastructure"
}

# ==========================================
# CONFIGURAÇÕES DE REGIÃO
# ==========================================

variable "azure_location" {
  description = "Região do Azure"
  type        = string
  default     = "Brazil South"
  
  validation {
    condition = contains([
      "Brazil South", "East US", "East US 2", "West Europe", "North Europe"
    ], var.azure_location)
    error_message = "Azure location deve ser uma região válida."
  }
}

variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "sa-east-1"
  
  validation {
    condition = contains([
      "sa-east-1", "us-east-1", "us-east-2", "eu-west-1", "eu-central-1"
    ], var.aws_region)
    error_message = "AWS region deve ser uma região válida."
  }
}

# ==========================================
# CONFIGURAÇÕES DE COMPUTE
# ==========================================

variable "azure_vm_size" {
  description = "Tamanho da VM Azure (sobrescreve configuração do ambiente)"
  type        = string
  default     = "Standard_B1s"
}

variable "aws_instance_type" {
  description = "Tipo da instância EC2 (sobrescreve configuração do ambiente)"
  type        = string
  default     = "t3.medium"
  
#   validation {
#     condition = var.aws_instance_type == "" || contains([
#       "t3.micro", "t3.small", "t3.medium", "t3.large"
#     ], var.aws_instance_type)
#     error_message = "AWS instance type deve ser um tipo válido."
#   }
}

variable "azure_vm_admin_username" {
  description = "Username admin para VM Azure"
  type        = string
  default     = "azureuser"
  
#   validation {
#     condition     = length(var.azure_vm_admin_username) >= 3
#     error_message = "Admin username deve ter pelo menos 3 caracteres."
#   }
}

variable "aws_key_pair_name" {
  description = "Nome do Key Pair AWS (deve existir)"
  type        = string
  default     = "xpto-corp-keypair"
}

# ==========================================
# CONFIGURAÇÕES SSH E SEGURANÇA
# ==========================================

variable "ssh_public_key_path" {
  description = "Caminho para chave SSH pública"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs permitidos para SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
#   validation {
#     condition     = length(var.allowed_ssh_cidrs) > 0
#     error_message = "Deve haver pelo menos um CIDR permitido para SSH."
#   }
}

# ==========================================
# FEATURES TOGGLEÁVEIS (CONTROLE DE CUSTOS)
# ==========================================

variable "enable_vpn_connection" {
  description = "Habilitar VPN Site-to-Site (Azure ~$142/mês + AWS ~$36/mês)"
  type        = bool
  default     = false
}

variable "enable_aws_dns" {
  description = "Habilitar DNS privado na AWS Route53"
  type        = bool
  default     = true
}

variable "enable_firewall" {
  description = "Habilitar Azure Firewall (Standard ~$544/mês, Premium ~$625/mês)"
  type        = bool
  default     = null  # Será definido pelo ambiente
}

variable "enable_bastion" {
  description = "Habilitar Azure Bastion (~$140/mês)"
  type        = bool
  default     = null  # Será definido pelo ambiente
}

variable "enable_ddos_protection" {
  description = "Habilitar DDoS Protection Plan (~$2944/mês)"
  type        = bool
  default     = null  # Será definido pelo ambiente
}

variable "enable_monitoring" {
  description = "Habilitar monitoramento avançado"
  type        = bool
  default     = null  # Será definido pelo ambiente
}

variable "enable_backup" {
  description = "Habilitar backup automático"
  type        = bool
  default     = null  # Será definido pelo ambiente
}

# ==========================================
# CONFIGURAÇÕES VPN
# ==========================================

variable "vpn_gateway_sku" {
  description = "SKU do VPN Gateway Azure (sobrescreve configuração do ambiente)"
  type        = string
  default     = "VpnGw1"
  
#   validation {
#     condition = var.vpn_gateway_sku == "" || contains([
#       "VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5"
#     ], var.vpn_gateway_sku)
#     error_message = "VPN Gateway SKU deve ser válido."
#   }
}

variable "vpn_bgp_asn" {
  description = "BGP ASN para Customer Gateway"
  type        = number
  default     = 65000
  
#   validation {
#     condition     = var.vpn_bgp_asn >= 1 && var.vpn_bgp_asn <= 4294967294
#     error_message = "BGP ASN deve estar entre 1 e 4294967294."
#   }
}

# ==========================================
# CONFIGURAÇÕES DNS
# ==========================================

variable "private_dns_zone_name" {
  description = "Nome da zona DNS privada"
  type        = string
  default     = "xpto.local"
  
#   validation {
#     condition     = can(regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.private_dns_zone_name))
#     error_message = "DNS zone name deve ser um FQDN válido."
#   }
}

# ==========================================
# CONFIGURAÇÕES DE REDE CUSTOMIZÁVEIS
# ==========================================

variable "custom_azure_cidrs" {
  description = "CIDRs customizados para Azure"
  type = object({
    hub_vnet         = optional(string, "10.1.0.0/16")
    spoke_vnet       = optional(string, "10.1.10.0/24")
    gateway_subnet   = optional(string, "10.1.3.0/27")
    firewall_subnet  = optional(string, "10.1.4.0/26")
  })
  default = {}
  
#   validation {
#     condition = alltrue([
#       can(cidrhost(var.custom_azure_cidrs.hub_vnet, 1)),
#       can(cidrhost(var.custom_azure_cidrs.spoke_vnet, 1)),
#       can(cidrhost(var.custom_azure_cidrs.gateway_subnet, 1)),
#       can(cidrhost(var.custom_azure_cidrs.firewall_subnet, 1))
#     ])
#     error_message = "Todos os CIDRs Azure devem ser válidos."
#   }
}

variable "custom_aws_cidrs" {
  description = "CIDRs customizados para AWS"
  type = object({
    vpc_cidr    = optional(string, "10.2.0.0/16")
    subnet_cidr = optional(string, "10.2.1.0/24")
  })
  default = {}
  
#   validation {
#     condition = alltrue([
#       can(cidrhost(var.custom_aws_cidrs.vpc_cidr, 1)),
#       can(cidrhost(var.custom_aws_cidrs.subnet_cidr, 1))
#     ])
#     error_message = "Todos os CIDRs AWS devem ser válidos."
#   }
}

# ==========================================
# CONFIGURAÇÕES DE COMPLIANCE
# ==========================================

variable "compliance_requirements" {
  description = "Requisitos de compliance"
  type = object({
    encrypt_at_rest     = optional(bool, true)
    encrypt_in_transit  = optional(bool, true)
    audit_logging       = optional(bool, true)
    data_residency      = optional(string, "Brazil")
    retention_period    = optional(number, 90)
  })
  default = {}
}

variable "governance_policies" {
  description = "Políticas de governança"
  type = object({
    require_tags        = optional(bool, true)
    allowed_regions     = optional(list(string), ["Brazil South", "sa-east-1"])
    resource_naming     = optional(bool, true)
    cost_controls       = optional(bool, true)
  })
  default = {}
}

# ==========================================
# CONFIGURAÇÕES DE DISASTER RECOVERY
# ==========================================

variable "disaster_recovery" {
  description = "Configurações de disaster recovery"
  type = object({
    enable_cross_region_backup = optional(bool, false)
    rpo_hours                  = optional(number, 24)
    rto_hours                  = optional(number, 4)
    secondary_region           = optional(string, "East US")
  })
  default = {}
}

# ==========================================
# CONFIGURAÇÕES AVANÇADAS DE REDE
# ==========================================

variable "advanced_networking" {
  description = "Configurações avançadas de rede"
  type = object({
    enable_accelerated_networking = optional(bool, false)
    enable_ip_forwarding         = optional(bool, false)
    enable_flow_logs             = optional(bool, true)
    enable_ddos_protection       = optional(bool, false)
    custom_dns_servers           = optional(list(string), [])
  })
  default = {}
}

# ==========================================
# CONFIGURAÇÕES DE CUSTO
# ==========================================

variable "cost_alert_threshold" {
  description = "Limite de custo mensal para alertas (USD)"
  type        = number
  default     = 300  # Será definido pelo ambiente
  
#   validation {
#     condition     = var.cost_alert_threshold == "" || var.cost_alert_threshold > 0
#     error_message = "Cost alert threshold deve ser maior que 0."
#   }
}

variable "enable_cost_optimization" {
  description = "Habilitar otimizações de custo automáticas"
  type        = bool
  default     = true
}

# ==========================================
# FEATURES TOGGLES AVANÇADOS
# ==========================================

variable "enable_spoke_gateway_transit" {
  description = "Habilitar uso de gateway remoto no spoke após VPN estar ativa"
  type        = bool
  default     = true
}

variable "enable_spoke_aws_routing" {
  description = "Habilitar roteamento do spoke para AWS via firewall"
  type        = bool
  default     = true
}