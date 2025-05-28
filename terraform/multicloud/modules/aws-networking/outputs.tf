# modules/aws-networking/outputs.tf

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR da VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  value       = aws_subnet.public.cidr_block
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "ID da route table pública"
  value       = aws_route_table.public.id
}

output "vpn_gateway_id" {
  description = "ID do VPN Gateway (se criado)"
  value       = var.create_vpn_gateway ? aws_vpn_gateway.main[0].id : null
}

output "availability_zones" {
  description = "AZs disponíveis na região"
  value       = data.aws_availability_zones.available.names
}