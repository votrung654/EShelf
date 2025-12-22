# Development Environment Outputs

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = module.ec2.bastion_public_ip
}

output "app_private_ips" {
  description = "Application server private IPs"
  value       = module.ec2.app_private_ips
}

output "ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i <key.pem> ec2-user@${module.ec2.bastion_public_ip}"
}


