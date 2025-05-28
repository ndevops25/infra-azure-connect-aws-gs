# modules/aws-networking/variables.tf

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.2.1.0/24"
}

variable "create_vpn_gateway" {
  description = "Criar VPN Gateway (custa ~$36/mês)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}