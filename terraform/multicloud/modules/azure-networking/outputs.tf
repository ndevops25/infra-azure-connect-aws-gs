# modules/azure-networking/outputs.tf

output "hub_vnet_id" {
  description = "ID da VNET Hub"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Nome da VNET Hub"
  value       = azurerm_virtual_network.hub.name
}

output "spoke_vnet_id" {
  description = "ID da VNET Spoke"
  value       = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  description = "Nome da VNET Spoke"
  value       = azurerm_virtual_network.spoke.name
}

output "hub_subnet_ids" {
  description = "IDs dos subnets do Hub"
  value = {
    for k, v in azurerm_subnet.hub_subnets : k => v.id
  }
}

output "spoke_subnet_ids" {
  description = "IDs dos subnets do Spoke"
  value = {
    for k, v in azurerm_subnet.spoke_subnets : k => v.id
  }
}

output "gateway_subnet_id" {
  description = "ID do Gateway Subnet"
  value       = azurerm_subnet.gateway.id
}

output "firewall_subnet_id" {
  description = "ID do Azure Firewall Subnet"
  value       = azurerm_subnet.firewall.id
}

output "hub_vnet_address_space" {
  description = "Address space da VNET Hub"
  value       = azurerm_virtual_network.hub.address_space
}

output "spoke_vnet_address_space" {
  description = "Address space da VNET Spoke"
  value       = azurerm_virtual_network.spoke.address_space
}

output "peering_hub_to_spoke_id" {
  description = "ID do peering Hub para Spoke"
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
}

output "peering_spoke_to_hub_id" {
  description = "ID do peering Spoke para Hub"
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
}

output "hub_route_table_id" {
  description = "ID da route table do Hub (se criada)"
  value       = var.create_hub_route_table ? azurerm_route_table.hub[0].id : null
}

output "spoke_route_table_id" {
  description = "ID da route table do Spoke (se criada)"
  value       = var.create_spoke_route_table ? azurerm_route_table.spoke[0].id : null
}

output "hub_nsg_id" {
  description = "ID do NSG do Hub (se criado)"
  value       = var.create_hub_nsg ? azurerm_network_security_group.hub[0].id : null
}

output "spoke_nsg_id" {
  description = "ID do NSG do Spoke (se criado)"
  value       = var.create_spoke_nsg ? azurerm_network_security_group.spoke[0].id : null
}

# Outputs úteis para outros módulos
output "network_info" {
  description = "Informações consolidadas da rede"
  value = {
    hub = {
      vnet_id           = azurerm_virtual_network.hub.id
      vnet_name         = azurerm_virtual_network.hub.name
      address_space     = azurerm_virtual_network.hub.address_space
      gateway_subnet_id = azurerm_subnet.gateway.id
      firewall_subnet_id = azurerm_subnet.firewall.id
      route_table_id    = var.create_hub_route_table ? azurerm_route_table.hub[0].id : null
      nsg_id           = var.create_hub_nsg ? azurerm_network_security_group.hub[0].id : null
      subnets = {
        for k, v in azurerm_subnet.hub_subnets : k => {
          id            = v.id
          name          = v.name
          address_prefix = v.address_prefixes[0]
        }
      }
    }
    spoke = {
      vnet_id       = azurerm_virtual_network.spoke.id
      vnet_name     = azurerm_virtual_network.spoke.name
      address_space = azurerm_virtual_network.spoke.address_space
      route_table_id = var.create_spoke_route_table ? azurerm_route_table.spoke[0].id : null
      nsg_id        = var.create_spoke_nsg ? azurerm_network_security_group.spoke[0].id : null
      subnets = {
        for k, v in azurerm_subnet.spoke_subnets : k => {
          id            = v.id
          name          = v.name
          address_prefix = v.address_prefixes[0]
        }
      }
    }
    peering = {
      hub_to_spoke_id = azurerm_virtual_network_peering.hub_to_spoke.id
      spoke_to_hub_id = azurerm_virtual_network_peering.spoke_to_hub.id
    }
  }
}