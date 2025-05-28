# modules/azure-compute/variables.tf

variable "vm_name" {
  description = "Nome da VM"
  type        = string
  default     = "vm-basic"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
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

variable "subnet_id" {
  description = "ID do subnet onde criar a VM"
  type        = string
}

variable "vm_size" {
  description = "Tamanho da VM"
  type        = string
  default     = "Standard_B1s"  # Mais barato para estudantes
}

variable "admin_username" {
  description = "Username do administrador"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Caminho para chave SSH pública"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "create_public_ip" {
  description = "Criar IP público para acesso direto"
  type        = bool
  default     = false  # Para economizar, só criar se necessário
}

variable "allow_http" {
  description = "Permitir tráfego HTTP"
  type        = bool
  default     = false
}

variable "allowed_source_cidr" {
  description = "CIDR permitido para ICMP"
  type        = string
  default     = "10.0.0.0/8"
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}