# variables.tf - Variáveis Atualizadas com Novos Controles

# Configurações básicas
variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "xpto-corp"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

# Regiões
variable "azure_location" {
  description = "Região do Azure"
  type        = string
  default     = "Brazil South"
}

variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "sa-east-1"
}

# Configurações Azure VM (econômicas)
variable "azure_vm_size" {
  description = "Tamanho da VM Azure"
  type        = string
  default     = "Standard_B1s"  # 1 vCPU, 1GB RAM - ~$8/mês
}

variable "azure_vm_admin_username" {
  description = "Username admin Azure"
  type        = string
  default     = "azureuser"
}

variable "create_azure_public_ip" {
  description = "Criar IP público para VM Azure"
  type        = bool
  default     = false  # Para economizar
}

# Configurações AWS EC2 (econômicas)
variable "aws_instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"  # Elegível para free tier
}

variable "aws_key_pair_name" {
  description = "Nome do Key Pair AWS (deve existir)"
  type        = string
  default     = "xpto-keypair"
}

# Features opcionais (para controlar custos)
variable "enable_vpn_connection" {
  description = "Habilitar VPN Site-to-Site (custa ~$178/mês total)"
  type        = bool
  default     = false  # Desabilitado por padrão para economizar
}

variable "aws_vpn_gateway_id_manual" {
  description = "ID do VPN Gateway AWS (obter manualmente após primeiro deploy)"
  type        = string
  default     = ""
  
  # Instruções para usar:
  # 1. Primeiro deploy: deixe vazio ""
  # 2. Após AWS VPN Gateway criado, use: terraform output aws_vpn_gateway_id
  # 3. Segundo deploy: preencha com o ID obtido
}

variable "enable_aws_dns" {
  description = "Habilitar DNS privado na AWS"
  type        = bool
  default     = true  # Custo baixo
}

variable "vpn_gateway_sku" {
  description = "SKU do VPN Gateway Azure"
  type        = string
  default     = "VpnGw1"  # Mais barato
}

variable "private_dns_zone_name" {
  description = "Nome da zona DNS privada"
  type        = string
  default     = "xpto.local"
}

# Configurações de Segurança (NOVAS)
variable "enable_firewall" {
  description = "Habilitar Azure Firewall (caro ~$544/mês)"
  type        = bool
  default     = false  # Desabilitado para economizar
}

variable "enable_bastion" {
  description = "Habilitar Azure Bastion (~$140/mês)"
  type        = bool
  default     = false  # Desabilitado para economizar
}

variable "enable_ddos_protection" {
  description = "Habilitar DDoS Protection (caro ~$2944/mês)"
  type        = bool
  default     = false  # Muito caro para estudantes
}

variable "enable_network_watcher" {
  description = "Habilitar Network Watcher (grátis)"
  type        = bool
  default     = true  # Grátis, sempre habilitado
}

variable "enable_flow_logs" {
  description = "Habilitar Flow Logs (~$5/mês)"
  type        = bool
  default     = false  # Para economizar
}

# Configurações avançadas de rede (opcionais)
variable "custom_azure_cidrs" {
  description = "CIDRs customizados para Azure"
  type = object({
    hub_vnet         = optional(string, "10.0.0.0/16")
    spoke_vnet       = optional(string, "10.1.0.0/16")
    gateway_subnet   = optional(string, "10.0.2.0/27")
    firewall_subnet  = optional(string, "10.0.3.0/26")
    bastion_subnet   = optional(string, "10.0.4.0/26")
  })
  default = {}
}

variable "custom_aws_cidrs" {
  description = "CIDRs customizados para AWS"
  type = object({
    vpc_cidr    = optional(string, "10.2.0.0/16")
    subnet_cidr = optional(string, "10.2.1.0/24")
  })
  default = {}
}