output "instance_id" {
  description = "Bastion instance ID"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "Bastion public IP"
  value       = aws_instance.bastion.public_ip
}

output "public_dns" {
  description = "Bastion public DNS"
  value       = aws_instance.bastion.public_dns
}

output "security_group_id" {
  description = "Bastion security group ID"
  value       = aws_security_group.bastion.id
}