# modules/vpn-connection/main.tf
# Módulo VPN Connection - Versão Básica para Estudantes

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Public IP para VPN Gateway Azure
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "pip-vpngw-${var.project_name}-${var.environment}"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  allocation_method   = "Static"
  sku                 = "Basic"  # Mais barato que Standard

  tags = var.tags
}

# VPN Gateway Azure (configuração básica)
resource "azurerm_virtual_network_gateway" "main" {
  name                = "vpngw-${var.project_name}-${var.environment}"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = var.vpn_gateway_sku  # VpnGw1 para estudantes

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.azure_gateway_subnet_id
  }

  tags = var.tags
}

# Customer Gateway AWS (representa o Azure VPN Gateway)
resource "aws_customer_gateway" "azure" {
  bgp_asn    = var.bgp_asn
  ip_address = azurerm_public_ip.vpn_gateway.ip_address
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = "cgw-azure-${var.project_name}-${var.environment}"
  })

  depends_on = [azurerm_virtual_network_gateway.main]
}

# VPN Connection AWS para Azure
resource "aws_vpn_connection" "azure" {
  count = var.aws_vpn_gateway_id != null ? 1 : 0
  
  customer_gateway_id = aws_customer_gateway.azure.id
  type                = "ipsec.1"
  vpn_gateway_id      = var.aws_vpn_gateway_id
  static_routes_only  = true

  tags = merge(var.tags, {
    Name = "vpn-azure-${var.project_name}-${var.environment}"
  })
}

# Rotas estáticas para Azure via VPN
resource "aws_vpn_connection_route" "azure_hub" {
  count = var.aws_vpn_gateway_id != null ? 1 : 0
  
  vpn_connection_id      = aws_vpn_connection.azure[0].id
  destination_cidr_block = var.azure_hub_cidr
}

resource "aws_vpn_connection_route" "azure_spoke" {
  count = var.aws_vpn_gateway_id != null ? 1 : 0
  
  vpn_connection_id      = aws_vpn_connection.azure[0].id
  destination_cidr_block = var.azure_spoke_cidr
}

# Local Network Gateway Azure (representa a AWS)
resource "azurerm_local_network_gateway" "aws" {
  count = var.aws_vpn_gateway_id != null ? 1 : 0
  
  name                = "lng-aws-${var.project_name}-${var.environment}"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  gateway_address     = var.aws_vpn_gateway_id != null ? aws_vpn_connection.azure[0].tunnel1_address : ""

  address_space = [var.aws_vpc_cidr]

  tags = var.tags
}

# VPN Connection Azure para AWS (apenas tunnel 1 para economizar)
resource "azurerm_virtual_network_gateway_connection" "aws" {
  count = var.aws_vpn_gateway_id != null ? 1 : 0
  
  name                = "cn-aws-${var.environment}"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws[0].id

  shared_key = var.aws_vpn_gateway_id != null ? aws_vpn_connection.azure[0].tunnel1_preshared_key : ""

  tags = var.tags
}