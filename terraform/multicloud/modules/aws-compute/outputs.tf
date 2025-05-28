# modules/aws-compute/outputs.tf

output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.main.id
}

output "instance_private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.main.private_ip
}

output "instance_public_ip" {
  description = "IP público da instância"
  value       = aws_instance.main.public_ip
}

output "elastic_ip" {
  description = "Elastic IP (se criado)"
  value       = var.create_elastic_ip ? aws_eip.main[0].public_ip : null
}

output "security_group_id" {
  description = "ID do Security Group"
  value       = aws_security_group.main.id
}

output "ssh_command" {
  description = "Comando SSH para conectar"
  value       = var.create_elastic_ip ? "ssh ubuntu@${aws_eip.main[0].public_ip}" : "ssh ubuntu@${aws_instance.main.public_ip}"
}