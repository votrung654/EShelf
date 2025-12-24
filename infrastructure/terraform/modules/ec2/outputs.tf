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

output "k3s_master_public_ip" {
  description = "K3s master node public IP"
  value       = var.create_k3s_cluster ? aws_instance.k3s_master[0].public_ip : null
}

output "k3s_master_private_ip" {
  description = "K3s master node private IP"
  value       = var.create_k3s_cluster ? aws_instance.k3s_master[0].private_ip : null
}

output "k3s_worker_private_ips" {
  description = "K3s worker nodes private IPs"
  value       = var.create_k3s_cluster ? aws_instance.k3s_worker[*].private_ip : []
}

output "k3s_master_instance_id" {
  description = "K3s master instance ID"
  value       = var.create_k3s_cluster ? aws_instance.k3s_master[0].id : null
}

output "k3s_worker_instance_ids" {
  description = "K3s worker instance IDs"
  value       = var.create_k3s_cluster ? aws_instance.k3s_worker[*].id : []
}


