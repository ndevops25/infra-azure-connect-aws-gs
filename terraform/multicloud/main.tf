# main.tf - Orquestrador Completo Corrigido
# Inclui todos os módulos necessários

# Gerar par de chaves SSH automaticamente
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Criar diretório para chaves SSH
resource "local_file" "ssh_dir" {
  content  = ""
  filename = "${path.module}/ssh-keys/.gitkeep"
}

# Salvar chaves localmente
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/ssh-keys/id_rsa"
  file_permission = "0600"
  
  depends_on = [local_file.ssh_dir]
}

resource "local_file" "public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "${path.module}/ssh-keys/id_rsa.pub"
  file_permission = "0644"
  
  depends_on = [local_file.ssh_dir]
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-${var.environment}-keypair"
  public_key = tls_private_key.ssh_key.public_key_openssh
  
  tags = local.common_tags
}

# Resource Group principal
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.azure_location
  tags     = local.common_tags
}

# Módulo Azure Networking (CORRIGIDO)
module "azure_networking" {
  source = "./modules/azure-networking"
  
  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  # CONFIGURAÇÃO CORRIGIDA - TODOS OS SUBNETS NOS RANGES CORRETOS
  # ✅ CORREÇÃO: Todos os subnets devem estar dentro dos address_space corretos
  hub_vnet_config = {
    address_space = ["10.0.0.0/16"]          # Hub VNET: 10.0.x.x
    subnets = {
      hub_subnet = "10.0.1.0/24"             # ✅ Dentro do Hub (10.0.x.x)
    }
  }
  
  spoke_vnet_config = {
    address_space = ["10.1.0.0/16"]          # Spoke VNET: 10.1.x.x  
    subnets = {
      spoke_subnet = "10.1.1.0/24"           # ✅ Dentro do Spoke (10.1.x.x)
    }
  }
  
  # ✅ CORREÇÃO CRÍTICA: Gateway e Firewall dentro do Hub
  gateway_subnet_cidr  = "10.0.2.0/27"
  firewall_subnet_cidr = "10.0.3.0/26"
  
  # Resto das configurações...
  enable_gateway_transit    = true
  use_remote_gateways      = false
  create_spoke_route_table = false
  create_hub_nsg           = true
  create_spoke_nsg         = true
  aws_cidr_block          = "10.2.0.0/16"
  
  tags = local.common_tags
}

# Módulo Azure Security (ADICIONADO)
module "azure_security" {
  source = "./modules/azure-security"
  
  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Firewall subnet
  firewall_subnet_id = module.azure_networking.firewall_subnet_id
  
  # Configurações de segurança (econômicas)
  enable_firewall              = var.enable_firewall
  enable_bastion              = var.enable_bastion
  enable_ddos_protection      = false  # Muito caro para estudantes
  enable_network_watcher      = false   # Grátis
  enable_flow_logs            = false  # Para economizar
  create_application_security_groups = false
  
  # CIDRs permitidos
  azure_source_cidrs      = ["10.0.0.0/16", "10.1.0.0/16"]  # Hub + Spoke
  azure_destination_cidrs = ["10.0.0.0/16", "10.1.0.0/16"]  # Hub + Spoke
  aws_source_cidrs        = ["10.2.0.0/16"]                 # AWS
  aws_destination_cidrs   = ["10.2.0.0/16"]                 # AWS
  
  # Configurações do Firewall (se habilitado)
  firewall_sku                = "Standard"
  threat_intelligence_mode    = "Alert"
  intrusion_detection_mode    = "Alert"
  
  # Bastion (se habilitado)
  vnet_name           = module.azure_networking.hub_vnet_name
  bastion_subnet_cidr = "10.0.4.0/26"  # ✅ CORRIGIDO: Dentro do Hub (10.0.x.x)
  
  tags = local.common_tags
  
  depends_on = [module.azure_networking]
}

# Módulo Azure Compute (CORRIGIDO)
module "azure_compute" {
  source = "./modules/azure-compute"
  
  vm_name             = "vm-spoke-${var.environment}"
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  subnet_id = module.azure_networking.spoke_subnet_ids["spoke_subnet"]
  
  # Configurações econômicas
  vm_size                 = var.azure_vm_size
  admin_username          = var.azure_vm_admin_username
  ssh_public_key_path     = tls_private_key.ssh_key.public_key_openssh
  create_public_ip        = var.create_azure_public_ip
  allow_http             = false
  allowed_source_cidr    = "10.2.0.0/16"  # Apenas AWS
  
  tags = local.common_tags
  
  depends_on = [module.azure_networking, local_file.public_key]
}

# Módulo AWS Networking (básico)
module "aws_networking" {
  source = "./modules/aws-networking"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_cidr           = "10.2.0.0/16"
  public_subnet_cidr = "10.2.1.0/24"
  
  # VPN Gateway pode ser caro, tornar opcional
  create_vpn_gateway = var.enable_vpn_connection
  
  tags = local.common_tags
}

# Módulo AWS Compute (CORRIGIDO)
module "aws_compute" {
  source = "./modules/aws-compute"
  
  instance_name = "ec2-${var.project_name}-${var.environment}"
  environment   = var.environment
  
  vpc_id    = module.aws_networking.vpc_id
  subnet_id = module.aws_networking.public_subnet_id
  
  # CORREÇÃO: Usar o key pair criado automaticamente
  instance_type      = var.aws_instance_type
  key_name          = aws_key_pair.main.key_name  # ✅ CORRIGIDO
  create_elastic_ip = true
  allow_http        = false
  allowed_icmp_cidrs = ["10.0.0.0/16", "10.1.0.0/16"]
  
  azure_vm_ip = module.azure_compute.vm_private_ip
  
  tags = local.common_tags
  
  depends_on = [module.aws_networking, aws_key_pair.main]  # ✅ Adicionar dependência
}

# Módulo VPN Connection (opcional, para economizar)
module "vpn_connection" {
  count = var.enable_vpn_connection ? 1 : 0
  
  source = "./modules/vpn-connection"
  
  project_name = var.project_name
  environment  = var.environment
  
  # Azure side
  azure_location            = azurerm_resource_group.main.location
  azure_resource_group_name = azurerm_resource_group.main.name
  azure_gateway_subnet_id   = module.azure_networking.gateway_subnet_id
  azure_hub_cidr   = "10.0.0.0/16"    # ✅ CORRIGIDO
  azure_spoke_cidr = "10.1.0.0/16"    # ✅ CORRIGIDO
  
  # AWS side
  aws_vpn_gateway_id = var.aws_vpn_gateway_id_manual
  aws_vpc_cidr     = "10.2.0.0/16"    # ✅ OK

  # Configurações básicas
  enable_vpn_connection = var.enable_vpn_connection
  vpn_gateway_sku = var.vpn_gateway_sku
  bgp_asn        = 65000
  
  tags = local.common_tags
  
  depends_on = [
    module.azure_networking,
    module.aws_networking
  ]
}

# Módulo DNS Privado (básico)
module "dns_private" {
  source = "./modules/dns-private"
  
  project_name = var.project_name
  environment  = var.environment
  
  dns_zone_name = var.private_dns_zone_name
  
  # Azure DNS
  azure_resource_group_name = azurerm_resource_group.main.name
  azure_hub_vnet_id        = module.azure_networking.hub_vnet_id
  azure_spoke_vnet_id      = module.azure_networking.spoke_vnet_id
  azure_vm_ip             = module.azure_compute.vm_private_ip
  
  # AWS DNS (opcional para economizar)
  create_aws_dns = var.enable_aws_dns
  aws_vpc_id     = module.aws_networking.vpc_id
  aws_ec2_ip     = module.aws_compute.instance_private_ip
  
  tags = local.common_tags
  
  depends_on = [
    module.azure_compute,
    module.aws_compute
  ]
}

# Locals para configurações compartilhadas
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = "Student"
    CreatedBy   = "Terraform"
    Purpose     = "Learning"
    Budget      = "Limited"
    CreatedOn   = timestamp()
  }
}