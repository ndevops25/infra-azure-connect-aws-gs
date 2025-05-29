# outputs.tf - Outputs principais do projeto CORRIGIDOS

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

# ✅ NOVO: Informações de SSH e Chaves
output "ssh_information" {
  description = "Informações para conexão SSH"
  value = {
    aws_key_pair_name     = aws_key_pair.main.key_name
    aws_private_key_path  = "${path.module}/ssh-keys/id_rsa"
    aws_public_key_path   = "${path.module}/ssh-keys/id_rsa.pub"
    azure_key_path        = "${path.module}/ssh-keys/id_rsa.pub"
    key_permissions_cmd   = "chmod 400 ${path.module}/ssh-keys/id_rsa"
  }
}

# ✅ NOVO: Comandos SSH Prontos para Uso
output "ssh_commands" {
  description = "Comandos SSH prontos para copiar e colar"
  value = {
    # AWS SSH
    aws_ssh_command = "ssh -i ${path.module}/ssh-keys/id_rsa -o StrictHostKeyChecking=no ubuntu@${module.aws_compute.elastic_ip}"

    # Azure SSH (se tiver IP público)
    azure_ssh_command = (
      module.azure_compute.vm_public_ip != null ?
      "ssh -i ${path.module}/ssh-keys/id_rsa -o StrictHostKeyChecking=no ${var.azure_vm_admin_username}@${module.azure_compute.vm_public_ip}" :
      "Azure VM sem IP público - Acesso via Bastion ou VPN"
    )

    # Comandos de preparação
    setup_ssh_permissions = "chmod 400 ${path.module}/ssh-keys/id_rsa && chmod 644 ${path.module}/ssh-keys/id_rsa.pub"
    
    # Teste de conectividade
    test_aws_connection = "ssh -i ${path.module}/ssh-keys/id_rsa -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@${module.aws_compute.elastic_ip} 'echo \"SSH OK - $(hostname)\"'"
  }
}

# ✅ MELHORADO: Comandos de conectividade e testes
output "connection_commands" {
  description = "Comandos úteis para conectar e testar"
  value = {
    # SSH Commands (já com chaves corretas)
    ssh_aws = "ssh -i ./ssh-keys/id_rsa ubuntu@${module.aws_compute.elastic_ip}"
    ssh_azure = (
      module.azure_compute.vm_public_ip != null ?
      "ssh -i ./ssh-keys/id_rsa ${var.azure_vm_admin_username}@${module.azure_compute.vm_public_ip}" :
      "VM Azure sem IP público"
    )

    # Ping Tests
    ping_test_aws_to_azure = "ping ${module.azure_compute.vm_private_ip}"
    ping_test_azure_to_aws = "ping ${module.aws_compute.instance_private_ip}"
    ping_test_aws_public = "ping ${module.aws_compute.elastic_ip}"
    
    # DNS Tests
    dns_test_azure = "nslookup vm-azure.${var.private_dns_zone_name}"
    dns_test_aws = var.enable_aws_dns ? "nslookup ec2-aws.aws.${var.private_dns_zone_name}" : "AWS DNS não habilitado"
    
    # Preparation Commands
    fix_ssh_permissions = "chmod 400 ./ssh-keys/id_rsa"
    test_ssh_key = "ssh-keygen -l -f ./ssh-keys/id_rsa.pub"
  }
}

# ✅ NOVO: Informações Detalhadas para Debug
output "debug_information" {
  description = "Informações para debug e troubleshooting"
  value = {
    # Instâncias
    aws_instance_id = module.aws_compute.instance_id
    aws_key_pair_used = aws_key_pair.main.key_name
    aws_security_group_id = module.aws_compute.security_group_id
    
    # IPs para referência
    aws_public_ip = module.aws_compute.elastic_ip
    aws_private_ip = module.aws_compute.instance_private_ip
    azure_private_ip = module.azure_compute.vm_private_ip
    
    # Comandos de debug AWS
    aws_debug_commands = {
      check_instance_status = "aws ec2 describe-instance-status --instance-ids ${module.aws_compute.instance_id}"
      check_security_groups = "aws ec2 describe-security-groups --group-ids ${module.aws_compute.security_group_id}"
      check_key_pair = "aws ec2 describe-key-pairs --key-names ${aws_key_pair.main.key_name}"
      get_console_output = "aws ec2 get-console-output --instance-id ${module.aws_compute.instance_id}"
    }
    
    # Paths importantes
    ssh_key_location = "${path.module}/ssh-keys/id_rsa"
    ssh_key_exists = fileexists("${path.module}/ssh-keys/id_rsa")
  }
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

# ✅ MELHORADO: Informações de custo
output "cost_information" {
  description = "Informações de custo estimado"
  value = {
    vpn_enabled = var.enable_vpn_connection
    estimated_monthly_cost_usd = var.enable_vpn_connection ? "~$200 (com VPN)" : "~$25 (sem VPN)"
    cost_warning = var.enable_vpn_connection ? "ATENÇÃO: VPN Gateway custa ~$178/mês" : "Configuração econômica ativa"
    savings_tip = "Para economizar: desabilite VPN quando não precisar"
    
    # Breakdown detalhado
    cost_breakdown = {
      azure_vm = "~$8/mês (Standard_B1s)"
      aws_ec2 = "~$9/mês (t3.micro, pode ser Free Tier)"
      azure_public_ip = "~$3/mês"
      aws_elastic_ip = "~$4/mês"
      dns_zones = "~$1/mês"
      vpn_gateways = var.enable_vpn_connection ? "~$178/mês (Azure + AWS)" : "$0/mês (desabilitado)"
    }
  }
}

# ✅ MELHORADO: Status da infraestrutura
output "infrastructure_status" {
  description = "Status geral da infraestrutura"
  value = {
    azure_resources_created = true
    aws_resources_created = true
    vpn_connection_enabled = var.enable_vpn_connection
    dns_zones_created = true
    aws_dns_enabled = var.enable_aws_dns
    ready_for_testing = true
    
    # Status detalhado
    ssh_keys_generated = fileexists("${path.module}/ssh-keys/id_rsa")
    aws_key_pair_name = aws_key_pair.main.key_name
    total_estimated_cost = var.enable_vpn_connection ? "$200/mês" : "$25/mês"
  }
}

# ✅ NOVO: Quick Start Commands
output "quick_start" {
  description = "Comandos rápidos para começar a usar"
  value = {
    step_1_fix_permissions = "chmod 400 ./ssh-keys/id_rsa"
    step_2_test_aws_ssh = "ssh -i ./ssh-keys/id_rsa -o ConnectTimeout=5 ubuntu@${module.aws_compute.elastic_ip} 'echo Connected to AWS!'"
    step_3_run_tests = "./test-connectivity.sh"
    step_4_check_costs = "terraform output cost_information"
    
    # Para troubleshooting
    if_ssh_fails = [
      "1. Verificar se chave existe: ls -la ./ssh-keys/",
      "2. Corrigir permissões: chmod 400 ./ssh-keys/id_rsa", 
      "3. Testar conectividade: ping ${module.aws_compute.elastic_ip}",
      "4. Verificar Security Group: terraform output debug_information",
      "5. Verificar logs da instância via AWS Console"
    ]
  }
}