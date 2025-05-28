# modules/dns-private/variables.tf

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "dns_zone_name" {
  description = "Nome da zona DNS privada"
  type        = string
  default     = "2tcnpz.local"
}

# Configurações Azure
variable "azure_resource_group_name" {
  description = "Nome do Resource Group Azure"
  type        = string
}

variable "azure_hub_vnet_id" {
  description = "ID da VNET Hub Azure"
  type        = string
}

variable "azure_spoke_vnet_id" {
  description = "ID da VNET Spoke Azure"
  type        = string
}

variable "azure_vm_ip" {
  description = "IP da VM Azure para registro DNS"
  type        = string
  default     = 1
}

# Configurações AWS
variable "create_aws_dns" {
  description = "Criar zona DNS na AWS (para economizar, pode desabilitar)"
  type        = bool
  default     = true
}

variable "aws_vpc_id" {
  description = "ID da VPC AWS"
  type        = string
  default     = ""
}

variable "aws_ec2_ip" {
  description = "IP da instância EC2 para registro DNS"
  type        = string
  default     = "1"
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}