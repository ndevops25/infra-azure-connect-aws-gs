# modules/azure-networking/variables.tf

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Localização dos recursos Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "hub_vnet_config" {
  description = "Configuração da VNET Hub"
  type = object({
    address_space = list(string)
    subnets       = map(string)
  })
  
  default = {
    address_space = ["10.1.0.0/16"]
    subnets = {
      hub_subnet = "10.1.1.0/24"
    }
  }
}

variable "spoke_vnet_config" {
  description = "Configuração da VNET Spoke"
  type = object({
    address_space = list(string)
    subnets       = map(string)
  })
  
  default = {
    address_space = ["10.1.10.0/24"]
    subnets = {
      spoke_subnet = "10.1.10.0/25"
    }
  }
}

variable "gateway_subnet_cidr" {
  description = "CIDR para Gateway Subnet"
  type        = string
  default     = "10.1.3.0/27"
}

variable "firewall_subnet_cidr" {
  description = "CIDR para Azure Firewall Subnet"
  type        = string
  default     = "10.1.4.0/26"
}

variable "enable_gateway_transit" {
  description = "Habilitar transit de gateway no hub"
  type        = bool
  default     = true
}

variable "use_remote_gateways" {
  description = "Usar gateways remotos no spoke"
  type        = bool
  default     = false
}

# Route Tables
variable "create_hub_route_table" {
  description = "Criar route table para hub"
  type        = bool
  default     = false
}

variable "create_spoke_route_table" {
  description = "Criar route table para spoke"
  type        = bool
  default     = false
}

variable "hub_custom_routes" {
  description = "Rotas customizadas para hub"
  type = map(object({
    address_prefix = string
    next_hop_type  = string
    next_hop_ip    = string
  }))
  default = {}
}

variable "spoke_custom_routes" {
  description = "Rotas customizadas para spoke"
  type = map(object({
    address_prefix = string
    next_hop_type  = string
    next_hop_ip    = string
  }))
  default = {}
}

# Network Security Groups
variable "create_hub_nsg" {
  description = "Criar NSG para hub"
  type        = bool
  default     = false
}

variable "create_spoke_nsg" {
  description = "Criar NSG para spoke"
  type        = bool
  default     = false
}

variable "aws_cidr_block" {
  description = "CIDR da AWS para regras NSG"
  type        = string
  default     = "10.2.0.0/16"
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}