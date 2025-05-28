# modules/aws-compute/main.tf
# Módulo AWS Compute - Versão Básica para Estudantes

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Security Group básico
resource "aws_security_group" "main" {
  name        = "sg-${var.instance_name}-${var.environment}"
  description = "Security group for ${var.instance_name}"
  vpc_id      = var.vpc_id

  # SSH básico
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Para facilitar acesso em estudos
  }

  # ICMP para testes de conectividade
  ingress {
    description = "ICMP from Azure"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.allowed_icmp_cidrs
  }

  # HTTP básico (se necessário)
  dynamic "ingress" {
    for_each = var.allow_http ? [1] : []
    content {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Outbound completo
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "sg-${var.instance_name}-${var.environment}"
  })
}

# Elastic IP (opcional)
resource "aws_eip" "main" {
  count = var.create_elastic_ip ? 1 : 0
  
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "eip-${var.instance_name}-${var.environment}"
  })

  depends_on = [aws_instance.main]
}

# EC2 Instance básica
resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.main.id]

  # Script básico de inicialização
  user_data = base64encode(templatefile("${path.module}/scripts/init.sh", {
    azure_vm_ip = var.azure_vm_ip
  }))

  # Usar gp3 que é mais barato que gp2
  root_block_device {
    volume_type = "gp3"
    volume_size = 8  # Mínimo para não ter custo extra
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = var.instance_name
  })
}

# Data source para AMI Ubuntu mais recente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-lts-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}