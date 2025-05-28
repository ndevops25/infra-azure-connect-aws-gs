# modules/aws-networking/main.tf
# Módulo AWS Networking - Versão Básica para Estudantes

# VPC básica
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "vpc-${var.project_name}-${var.environment}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "igw-${var.project_name}-${var.environment}"
  })
}

# Subnet pública básica
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "subnet-public-${var.project_name}-${var.environment}"
    Type = "Public"
  })
}

# Route Table para subnet pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "rt-public-${var.project_name}-${var.environment}"
  })
}

# Associação da Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# VPN Gateway (básico, sem redundância para economizar)
resource "aws_vpn_gateway" "main" {
  count = var.create_vpn_gateway ? 1 : 0
  
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "vpngw-${var.project_name}-${var.environment}"
  })
}

# Propagação de rotas VPN (se VPN Gateway existir)
resource "aws_vpn_gateway_route_propagation" "main" {
  count = var.create_vpn_gateway ? 1 : 0
  
  vpn_gateway_id = aws_vpn_gateway.main[0].id
  route_table_id = aws_route_table.public.id
}

# Data source para AZs disponíveis
data "aws_availability_zones" "available" {
  state = "available"
}