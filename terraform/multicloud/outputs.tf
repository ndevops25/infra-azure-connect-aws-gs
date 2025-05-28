# outputs.tf - Outputs principais do projeto

# Informações dos Resource Groups
output "resource_group_name" {
  description = "Nome do Resource Group Azure"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID do Resource Group Azure"
  value       = azurerm_resource_group.main.id
}

# Informações de Rede Azure
output "azure_hub_vnet_id" {
  description = "ID da VNET Hub Azure"
  value       = module.azure_networking.hub_vnet_id
}

output "azure_spoke_vnet_id" {
  description = "ID da VNET Spoke Azure"
  value       = module.azure_networking.spoke_vnet_id
}

# Informações de Rede AWS
output "aws_vpc_id" {
  description = "ID da VPC AWS"
  value       = module.aws_networking.vpc_id
}

output "aws_subnet_id" {
  description = "ID da subnet pública AWS"
  value       = module.aws_networking.public_subnet_id
}

# Informações das VMs
output "azure_vm_id" {
  description = "ID da VM Azure"
  value       = module.azure_compute.vm_id
}

output "azure_vm_private_ip" {
  description = "IP privado da VM Azure"
  value       = module.azure_compute.vm_private_ip
}

output "azure_vm_public_ip" {
  description = "IP público da VM Azure (se disponível)"
  value       = module.azure_compute.vm_public_ip
}

output "aws_ec2_instance_id" {
  description = "ID da instância EC2"
  value       = module.aws_compute.instance_id
}

output "aws_ec2_private_ip" {
  description = "IP privado da instância EC2"
  value       = module.aws_compute.instance_private_ip
}

output "aws_ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = module.aws_compute.elastic_ip
}

# Informações de VPN (se habilitada)
output "vpn_enabled" {
  description = "Status da VPN"
  value       = var.enable_vpn_connection
}

output "azure_vpn_gateway_ip" {
  description = "IP público do VPN Gateway Azure (se VPN habilitada)"
  value       = var.enable_vpn_connection ? module.vpn_connection[0].azure_vpn_public_ip : null
}

output "vpn_connection_id" {
  description = "ID da conexão VPN AWS (se VPN habilitada)"
  value       = var.enable_vpn_connection ? module.vpn_connection[0].aws_vpn_connection_id : null
}

# Informações de DNS
output "azure_dns_zone_name" {
  description = "Nome da zona DNS privada Azure"
  value       = module.dns_private.azure_dns_zone_name
}

output "aws_dns_zone_name" {
  description = "Nome da zona DNS privada AWS (se habilitada)"
  value       = module.dns_private.aws_dns_zone_name
}

# Comandos úteis para conectividade
output "connection_commands" {
  description = "Comandos úteis para conectar e testar"
  value = {
    ssh_aws = module.aws_compute.ssh_command
    ssh_azure = module.azure_compute.ssh_command
    ping_test_aws_to_azure = "ping ${module.azure_compute.vm_private_ip}"
    ping_test_azure_to_aws = "ping ${module.aws_compute.instance_private_ip}"
    dns_test_azure = "nslookup vm-azure.${var.private_dns_zone_name}"
    dns_test_aws = var.enable_aws_dns ? "nslookup ec2-aws.aws.${var.private_dns_zone_name}" : "AWS DNS não habilitado"
  }
}

# Informações de custo
output "cost_information" {
  description = "Informações de custo estimado"
  value = {
    vpn_enabled = var.enable_vpn_connection
    estimated_monthly_cost_usd = var.enable_vpn_connection ? "~$200 (com VPN)" : "~$25 (sem VPN)"
    cost_warning = var.enable_vpn_connection ? "ATENÇÃO: VPN Gateway custa ~$178/mês" : "Configuração econômica ativa"
    savings_tip = "Para economizar: desabilite VPN quando não precisar"
  }
}

# Status geral da infraestrutura
output "infrastructure_status" {
  description = "Status geral da infraestrutura"
  value = {
    azure_resources_created = true
    aws_resources_created = true
    vpn_connection_enabled = var.enable_vpn_connection
    dns_zones_created = true
    aws_dns_enabled = var.enable_aws_dns
    ready_for_testing = true
  }
}