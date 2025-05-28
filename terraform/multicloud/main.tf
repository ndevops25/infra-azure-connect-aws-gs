# main.tf - Versão Simplificada para Estudantes
# Orquestração básica dos módulos

# Gerar par de chaves SSH automaticamente
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Salvar chaves localmente
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/ssh-keys/id_rsa"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "${path.module}/ssh-keys/id_rsa.pub"
  file_permission = "0644"
}

# Resource Group principal
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.azure_location
  tags     = local.common_tags
}

# Módulo Azure Networking (com recursos básicos)
module "azure_networking" {
  source = "./modules/azure-networking"
  
  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Configurações básicas de rede
  hub_vnet_config = {
    address_space = ["10.1.0.0/16"]
    subnets = {
      hub_subnet = "10.1.1.0/24"
    }
  }
  
  spoke_vnet_config = {
    address_space = ["10.1.10.0/24"]
    subnets = {
      spoke_subnet = "10.1.10.0/25"
    }
  }
  
  gateway_subnet_cidr  = "10.1.3.0/27"
  firewall_subnet_cidr = "10.1.4.0/26"
  
  # Configurações para estudantes
  enable_gateway_transit    = true
  use_remote_gateways      = false
  create_spoke_route_table = false  # Simplificar roteamento
  
  tags = local.common_tags
}

# Módulo Azure Compute (VM básica)
module "azure_compute" {
  source = "./modules/azure-compute"
  
  vm_name             = "vm-spoke-${var.environment}"
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  subnet_id = module.azure_networking.spoke_subnet_ids["spoke_subnet"]
  
  # Configurações econômicas
  vm_size              = var.azure_vm_size
  admin_username       = var.azure_vm_admin_username
  ssh_public_key_path  = tls_private_key.ssh_key.public_key_openssh
  create_public_ip     = false  # Economizar, acesso via VPN ou jumpbox
  allow_http          = false
  allowed_source_cidr = "10.2.0.0/16"  # Apenas AWS
  
  tags = local.common_tags
  
  depends_on = [module.azure_networking]
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

# Módulo AWS Compute (EC2 básica)
module "aws_compute" {
  source = "./modules/aws-compute"
  
  instance_name = "ec2-${var.project_name}-${var.environment}"
  environment   = var.environment
  
  vpc_id    = module.aws_networking.vpc_id
  subnet_id = module.aws_networking.public_subnet_id
  
  # Configurações econômicas
  instance_type      = var.aws_instance_type
  key_name          = var.aws_key_pair_name
  create_elastic_ip = true  # Para acesso SSH
  allow_http        = false
  allowed_icmp_cidrs = ["10.1.0.0/16", "10.1.10.0/24"]  # Azure
  
  azure_vm_ip = module.azure_compute.vm_private_ip
  
  tags = local.common_tags
  
  depends_on = [module.aws_networking]
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
  azure_hub_cidr           = "10.1.0.0/16"
  azure_spoke_cidr         = "10.1.10.0/24"
  
  # AWS side
  aws_vpn_gateway_id = module.aws_networking.vpn_gateway_id
  aws_vpc_cidr      = "10.2.0.0/16"
  
  # Configurações básicas
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
  }
}