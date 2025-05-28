# modules/vpn-connection/outputs.tf

output "azure_vpn_gateway_id" {
  description = "ID do VPN Gateway Azure"
  value       = azurerm_virtual_network_gateway.main.id
}

output "azure_vpn_public_ip" {
  description = "IP público do VPN Gateway Azure"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}

output "aws_customer_gateway_id" {
  description = "ID do Customer Gateway AWS"
  value       = aws_customer_gateway.azure.id
}

output "aws_vpn_connection_id" {
  description = "ID da conexão VPN AWS (se criada)"
  value       = var.aws_vpn_gateway_id != null ? aws_vpn_connection.azure[0].id : null
}

output "vpn_tunnel1_address" {
  description = "Endereço do tunnel 1 da VPN"
  value       = var.aws_vpn_gateway_id != null ? aws_vpn_connection.azure[0].tunnel1_address : null
  sensitive   = true
}

output "vpn_connection_status" {
  description = "Status da conexão VPN"
  value = {
    azure_gateway_provisioned = azurerm_virtual_network_gateway.main.id != null
    aws_connection_created    = var.aws_vpn_gateway_id != null
    tunnel1_configured        = var.aws_vpn_gateway_id != null ? true : false
  }
}