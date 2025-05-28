# modules/aws-compute/variables.tf

variable "instance_name" {
  description = "Nome da instância EC2"
  type        = string
  default     = "ec2-basic"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"  # Elegível para free tier
}

variable "key_name" {
  description = "Nome da key pair (deve existir na AWS)"
  type        = string
}

variable "create_elastic_ip" {
  description = "Criar Elastic IP"
  type        = bool
  default     = true
}

variable "allow_http" {
  description = "Permitir tráfego HTTP"
  type        = bool
  default     = false
}

variable "allowed_icmp_cidrs" {
  description = "CIDRs permitidos para ICMP"
  type        = list(string)
  default     = ["10.1.0.0/16", "10.1.10.0/24"]
}

variable "azure_vm_ip" {
  description = "IP da VM Azure para testes de conectividade"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}