# modules/azure-compute/outputs.tf

output "vm_id" {
  description = "ID da VM"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Nome da VM"
  value       = azurerm_linux_virtual_machine.main.name
}

output "vm_private_ip" {
  description = "IP privado da VM"
  value       = azurerm_linux_virtual_machine.main.private_ip_address
}

output "vm_public_ip" {
  description = "IP público da VM (se criado)"
  value       = var.create_public_ip ? azurerm_public_ip.main[0].ip_address : null
}

output "network_interface_id" {
  description = "ID da interface de rede"
  value       = azurerm_network_interface.main.id
}

output "network_security_group_id" {
  description = "ID do Network Security Group"
  value       = azurerm_network_security_group.main.id
}

output "ssh_command" {
  description = "Comando SSH para conectar (se IP público disponível)"
  value       = var.create_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.main[0].ip_address}" : "VM sem IP público"
}