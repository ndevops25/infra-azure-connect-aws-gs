# modules/dns-private/outputs.tf

output "azure_dns_zone_id" {
  description = "ID da zona DNS privada Azure"
  value       = azurerm_private_dns_zone.main.id
}

output "azure_dns_zone_name" {
  description = "Nome da zona DNS privada Azure"
  value       = azurerm_private_dns_zone.main.name
}

output "aws_dns_zone_id" {
  description = "ID da zona DNS privada AWS (se criada)"
  value       = var.create_aws_dns # ? aws_route53_zone.private[0].zone_id : null
}

output "aws_dns_zone_name" {
  description = "Nome da zona DNS privada AWS (se criada)"
  value       = var.create_aws_dns # ? aws_route53_zone.private[0].name : null
}

output "dns_records" {
  description = "Registros DNS criados"
  value = {
    azure_vm_fqdn = var.azure_vm_ip != "" ? "vm-azure.${var.dns_zone_name}" : null
    aws_ec2_fqdn  = var.create_aws_dns && var.aws_ec2_ip != "" ? "ec2-aws.aws.${var.dns_zone_name}" : null
  }
}