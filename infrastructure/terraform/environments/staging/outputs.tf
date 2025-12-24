# Staging Environment Outputs

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

output "bastion_instance_id" {
  description = "Bastion host instance ID"
  value       = module.ec2.bastion_instance_id
}

output "k3s_master_instance_id" {
  description = "K3s master instance ID"
  value       = var.create_k3s_cluster ? module.ec2.k3s_master_instance_id : null
}

output "k3s_worker_instance_ids" {
  description = "K3s worker instance IDs"
  value       = var.create_k3s_cluster ? module.ec2.k3s_worker_instance_ids : []
}

