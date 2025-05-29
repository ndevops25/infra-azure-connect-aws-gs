# modules/aws-compute/main.tf
# Módulo AWS Compute - Versão Básica para Estudantes

# Security Group básico
# Security Group mais permissivo para testes
resource "aws_security_group" "main" {
  name        = "${var.instance_name}-${var.environment}-sg"
  description = "Security group for ${var.instance_name}"
  vpc_id      = var.vpc_id

  # SSH de qualquer lugar (para testes)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ✅ Mais permissivo para debug
  }

  # ICMP de qualquer lugar (para testes)
  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]  # ✅ Permitir ping
  }

  # Todo tráfego de saída
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
# modules/aws-compute/main.tf - CORREÇÃO
resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.main.id]
  
  # ✅ CORREÇÃO: Garantir que SSH está habilitado
  user_data = base64encode(templatefile("${path.module}/scripts/init.sh", {
    azure_vm_ip = var.azure_vm_ip
  }))
  
  # ✅ ADICIONAR: Garantir que user data execute
  user_data_replace_on_change = true
  
  # ✅ CORREÇÃO: Usar storage mais barato
  root_block_device {
    volume_type = "gp2"  # Mais barato que gp3 às vezes
    volume_size = 8      # Mínimo
    encrypted   = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = var.instance_name
  })
}

# Data source para AMI Ubuntu mais recente
# Data source para AMI Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}