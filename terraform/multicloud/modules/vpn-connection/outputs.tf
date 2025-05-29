# modules/vpn-connection/outputs.tf

output "azure_vpn_gateway_id" {
  description = "ID do VPN Gateway Azure"
  value       = azurerm_virtual_network_gateway.main.id
}

output "azure_vpn_gateway_name" {
  description = "Nome do VPN Gateway Azure"
  value       = azurerm_virtual_network_gateway.main.name
}

output "azure_vpn_public_ip" {
  description = "IP público do VPN Gateway Azure"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}

output "aws_customer_gateway_id" {
  description = "ID do Customer Gateway AWS (se criado)"
  value       = var.enable_vpn_connection ? aws_customer_gateway.azure[0].id : null
}

output "aws_vpn_connection_id" {
  description = "ID da conexão VPN AWS (se criada)"
  value       = var.enable_vpn_connection && var.aws_vpn_gateway_id != "" ? aws_vpn_connection.azure[0].id : null
}

output "vpn_tunnel1_address" {
  description = "Endereço do tunnel 1 da VPN (se criado)"
  value       = var.enable_vpn_connection && var.aws_vpn_gateway_id != "" ? aws_vpn_connection.azure[0].tunnel1_address : null
  sensitive   = true
}

output "vpn_tunnel2_address" {
  description = "Endereço do tunnel 2 da VPN (se criado)"
  value       = var.enable_vpn_connection && var.aws_vpn_gateway_id != "" ? aws_vpn_connection.azure[0].tunnel2_address : null
  sensitive   = true
}

output "vpn_connection_status" {
  description = "Status da conexão VPN"
  value = {
    azure_gateway_created     = true
    aws_customer_gateway_created = var.enable_vpn_connection
    aws_vpn_connection_created   = var.enable_vpn_connection && var.aws_vpn_gateway_id != ""
    tunnel1_configured          = var.enable_vpn_connection && var.aws_vpn_gateway_id != ""
    tunnel2_available          = var.enable_vpn_connection && var.aws_vpn_gateway_id != ""
  }
}

output "vpn_configuration" {
  description = "Configuração da VPN"
  value = {
    azure_public_ip = azurerm_public_ip.vpn_gateway.ip_address
    gateway_sku     = var.vpn_gateway_sku
    bgp_asn        = var.bgp_asn
    vpn_enabled    = var.enable_vpn_connection
    aws_gateway_id = var.aws_vpn_gateway_id
  }
}