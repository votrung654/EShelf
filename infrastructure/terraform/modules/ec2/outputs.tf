# EC2 Module Outputs

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Bastion instance ID"
  value       = aws_instance.bastion.id
}

output "app_instance_ids" {
  description = "Application instance IDs"
  value       = aws_instance.app[*].id
}

output "app_private_ips" {
  description = "Application instance private IPs"
  value       = aws_instance.app[*].private_ip
}


