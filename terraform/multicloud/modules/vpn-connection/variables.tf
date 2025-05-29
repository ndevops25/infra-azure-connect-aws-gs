# modules/vpn-connection/variables.tf

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

# Configurações Azure
variable "azure_location" {
  description = "Localização dos recursos Azure"
  type        = string
}

variable "azure_resource_group_name" {
  description = "Nome do Resource Group Azure"
  type        = string
}

variable "azure_gateway_subnet_id" {
  description = "ID do Gateway Subnet Azure"
  type        = string
}

variable "azure_hub_cidr" {
  description = "CIDR da VNET Hub Azure"
  type        = string
  default     = "10.1.0.0/16"
}

variable "azure_spoke_cidr" {
  description = "CIDR da VNET Spoke Azure"
  type        = string
  default     = "10.1.10.0/24"
}

# Configurações AWS
variable "aws_vpn_gateway_id" {
  description = "ID do VPN Gateway AWS"
  type        = string
  default     = ""
}

variable "aws_vpc_cidr" {
  description = "CIDR da VPC AWS"
  type        = string
  default     = "10.2.0.0/16"
}

# Configurações VPN
variable "enable_vpn_connection" {
  description = "Habilitar VPN Connection (precisa de VPN Gateway AWS)"
  type        = bool
  default     = true
}

variable "vpn_gateway_sku" {
  description = "SKU do VPN Gateway Azure"
  type        = string
  default     = "VpnGw1"
  
  validation {
    condition     = contains(["VpnGw1", "VpnGw2", "VpnGw3"], var.vpn_gateway_sku)
    error_message = "VPN Gateway SKU deve ser VpnGw1, VpnGw2 ou VpnGw3."
  }
}

variable "bgp_asn" {
  description = "BGP ASN para Customer Gateway"
  type        = number
  default     = 65000
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}