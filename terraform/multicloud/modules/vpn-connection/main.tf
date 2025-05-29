# modules/vpn-connection/main.tf
# Módulo VPN Connection - VERSÃO SIMPLIFICADA SEM DEPENDÊNCIAS CIRCULARES

# ============================================================================
# FASE 1: SEMPRE CRIA O VPN GATEWAY AZURE
# ============================================================================

# Public IP para VPN Gateway Azure
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "pip-vpngw-${var.project_name}-${var.environment}"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# VPN Gateway Azure (sempre criado - demora ~25 minutos)
resource "azurerm_virtual_network_gateway" "main" {
  name                = "vpngw-${var.project_name}-${var.environment}"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = var.vpn_gateway_sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.azure_gateway_subnet_id
  }

  tags = var.tags
}

# ============================================================================
# FASE 2: RECURSOS AWS (só se VPN habilitada E AWS Gateway ID fornecido)
# ============================================================================

# Customer Gateway AWS
resource "aws_customer_gateway" "azure" {
  count = var.enable_vpn_connection ? 1 : 0
  
  bgp_asn    = var.bgp_asn
  ip_address = azurerm_public_ip.vpn_gateway.ip_address
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = "cgw-azure-${var.project_name}-${var.environment}"
  })

  depends_on = [azurerm_virtual_network_gateway.main]
}

# ============================================================================
# FASE 3: CONEXÕES VPN (só se AWS VPN Gateway ID for fornecido manualmente)
# ============================================================================

# Data source para buscar VPN Gateway AWS existente
data "aws_vpn_gateway" "existing" {
  count = var.enable_vpn_connection && var.aws_vpn_gateway_id != "" ? 1 : 0
  
  id = var.aws_vpn_gateway_id
}

# VPN Connection AWS para Azure
resource "aws_vpn_connection" "azure" {
  count = var.enable_vpn_connection && var.aws_vpn_gateway_id != "" ? 1 : 0
  
  customer_gateway_id = aws_customer_gateway.azure[0].id
  type                = "ipsec.1"
  vpn_gateway_id      = var.aws_vpn_gateway_id
  static_routes_only  = true

  tags = merge(var.tags, {
    Name = "vpn-azure-${var.project_name}-${var.environment}"
  })
}

# Rotas estáticas para Azure via VPN
resource "aws_vpn_connection_route" "azure_hub" {
  count = var.enable_vpn_connection && var.aws_vpn_gateway_id != "" ? 1 : 0
  
  vpn_connection_id      = aws_vpn_connection.azure[0].id
  destination_cidr_block = var.azure_hub_cidr
}

resource "aws_vpn_connection_route" "azure_spoke" {
  count = var.enable_vpn_connection && var.aws_vpn_gateway_id != "" ? 1 : 0
  
  vpn_connection_id      = aws_vpn_connection.azure[0].id
  destination_cidr_block = var.azure_spoke_cidr
}

# Local Network Gateway Azure (representa a AWS)
resource "azurerm_local_network_gateway" "aws" {
  count = var.enable_vpn_connection && var.aws_vpn_gateway_id != "" ? 1 : 0
  
  name                = "lng-aws-${var.project_name}-${var.environment}"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  gateway_address     = aws_vpn_connection.azure[0].tunnel1_address

  address_space = [var.aws_vpc_cidr]

  tags = var.tags
}

# VPN Connection Azure para AWS
resource "azurerm_virtual_network_gateway_connection" "aws" {
  count = var.enable_vpn_connection && var.aws_vpn_gateway_id != "" ? 1 : 0
  
  name                = "cn-aws-${var.environment}"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws[0].id

  shared_key = aws_vpn_connection.azure[0].tunnel1_preshared_key

  tags = var.tags
}