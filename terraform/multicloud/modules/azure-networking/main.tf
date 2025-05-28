# modules/azure-networking/main.tf
# Módulo Azure Networking - Versão Completa

# VNET Hub
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.hub_vnet_config.address_space
  
  tags = var.tags
}

# VNET Spoke
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.spoke_vnet_config.address_space
  
  tags = var.tags
}

# Subnets Hub
resource "azurerm_subnet" "hub_subnets" {
  for_each = var.hub_vnet_config.subnets
  
  name                 = "${each.key}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value]
}

# Gateway Subnet (nome fixo exigido pelo Azure)
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

# Azure Firewall Subnet (nome fixo exigido pelo Azure)
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_cidr]
}

# Subnets Spoke
resource "azurerm_subnet" "spoke_subnets" {
  for_each = var.spoke_vnet_config.subnets
  
  name                 = "${each.key}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [each.value]
}

# VNET Peering Hub -> Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke-${var.environment}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.enable_gateway_transit
  use_remote_gateways          = false
}

# VNET Peering Spoke -> Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub-${var.environment}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_remote_gateways
}

# Route Table para Hub
resource "azurerm_route_table" "hub" {
  count = var.create_hub_route_table ? 1 : 0
  
  name                = "rt-hub-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Route Table para Spoke (direcionar tráfego via Hub)
resource "azurerm_route_table" "spoke" {
  count = var.create_spoke_route_table ? 1 : 0
  
  name                = "rt-spoke-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Rotas customizadas para Hub
resource "azurerm_route" "hub_routes" {
  for_each = var.create_hub_route_table ? var.hub_custom_routes : {}
  
  name                   = each.key
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.hub[0].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_ip
}

# Rotas customizadas para Spoke
resource "azurerm_route" "spoke_routes" {
  for_each = var.create_spoke_route_table ? var.spoke_custom_routes : {}
  
  name                   = each.key
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.spoke[0].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_ip
}

# Associação Route Table com Hub Subnets (exceto Gateway e Firewall)
resource "azurerm_subnet_route_table_association" "hub" {
  for_each = var.create_hub_route_table ? var.hub_vnet_config.subnets : {}
  
  subnet_id      = azurerm_subnet.hub_subnets[each.key].id
  route_table_id = azurerm_route_table.hub[0].id
}

# Associação Route Table com Spoke Subnets
resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = var.create_spoke_route_table ? var.spoke_vnet_config.subnets : {}
  
  subnet_id      = azurerm_subnet.spoke_subnets[each.key].id
  route_table_id = azurerm_route_table.spoke[0].id
}

# Network Security Group para Hub (básico)
resource "azurerm_network_security_group" "hub" {
  count = var.create_hub_nsg ? 1 : 0
  
  name                = "nsg-hub-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Regra para permitir tráfego interno
  security_rule {
    name                       = "AllowVnetInBound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Regra para permitir tráfego da AWS
  security_rule {
    name                       = "AllowAWSInBound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.aws_cidr_block
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Network Security Group para Spoke (básico)
resource "azurerm_network_security_group" "spoke" {
  count = var.create_spoke_nsg ? 1 : 0
  
  name                = "nsg-spoke-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ICMP
  security_rule {
    name                       = "ICMP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.aws_cidr_block
    destination_address_prefix = "*"
  }

  # HTTP/HTTPS
  security_rule {
    name                       = "HTTP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associação NSG com Hub Subnets
resource "azurerm_subnet_network_security_group_association" "hub" {
  for_each = var.create_hub_nsg ? var.hub_vnet_config.subnets : {}
  
  subnet_id                 = azurerm_subnet.hub_subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.hub[0].id
}

# Associação NSG com Spoke Subnets
resource "azurerm_subnet_network_security_group_association" "spoke" {
  for_each = var.create_spoke_nsg ? var.spoke_vnet_config.subnets : {}
  
  subnet_id                 = azurerm_subnet.spoke_subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke[0].id
}