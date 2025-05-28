# modules/dns-private/main.tf
# Módulo DNS Privado - Versão Básica para Estudantes

# Private DNS Zone no Azure
resource "azurerm_private_dns_zone" "main" {
  name                = var.dns_zone_name
  resource_group_name = var.azure_resource_group_name
  
  tags = var.tags
}

# Link da DNS Zone com VNET Hub
resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = "link-hub-${var.environment}"
  resource_group_name   = var.azure_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = var.azure_hub_vnet_id
  registration_enabled  = true
  
  tags = var.tags
}

# Link da DNS Zone com VNET Spoke
resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  name                  = "link-spoke-${var.environment}"
  resource_group_name   = var.azure_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = var.azure_spoke_vnet_id
  registration_enabled  = true
  
  tags = var.tags
}

# Registro DNS para VM Azure
resource "azurerm_private_dns_a_record" "azure_vm" {  
  name                = "vm-azure"
  zone_name           = azurerm_private_dns_zone.main.name
  resource_group_name = var.azure_resource_group_name
  ttl                 = 300
  records             = [var.azure_vm_ip]
  
  tags = var.tags
}

# Route 53 Private Zone na AWS (básica)
# resource "aws_route53_zone" "private" {
#   count = var.create_aws_dns ? 1 : 0
  
#   name = "aws.${var.dns_zone_name}"

#   vpc {
#     vpc_id = var.aws_vpc_id
#   }

#   tags = merge(var.tags, {
#     Name = "private-zone-${var.project_name}-${var.environment}"
#   })
# }

# # Registro DNS para EC2 na AWS
# resource "aws_route53_record" "ec2" {
#   count = var.create_aws_dns && var.aws_ec2_ip != "1" ? 1 : 0
  
#   zone_id = aws_route53_zone.private[0].zone_id
#   name    = "ec2-aws"
#   type    = "A"
#   ttl     = 300
#   records = [var.aws_ec2_ip]
# }

# # Registro DNS para resolver Azure a partir da AWS
# resource "aws_route53_record" "azure_vm_from_aws" {
#   count = var.create_aws_dns && var.azure_vm_ip != "1" ? 1 : 0
  
#   zone_id = aws_route53_zone.private[0].zone_id
#   name    = "vm-azure"
#   type    = "A"
#   ttl     = 300
#   records = [var.azure_vm_ip]
# }