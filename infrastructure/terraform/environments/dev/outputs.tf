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

output "k3s_master_public_ip" {
  description = "K3s master node public IP"
  value       = var.create_k3s_cluster ? module.ec2.k3s_master_public_ip : null
}

output "k3s_master_private_ip" {
  description = "K3s master node private IP"
  value       = var.create_k3s_cluster ? module.ec2.k3s_master_private_ip : null
}

output "k3s_worker_private_ips" {
  description = "K3s worker nodes private IPs"
  value       = var.create_k3s_cluster ? module.ec2.k3s_worker_private_ips : []
}

output "k3s_kubeconfig_command" {
  description = "Command to get kubeconfig from master"
  value       = var.create_k3s_cluster ? "scp -i <key.pem> ec2-user@${module.ec2.k3s_master_public_ip}:~/.kube/config ~/.kube/config" : null
}

output "ansible_inventory_info" {
  description = "Info for Ansible inventory"
  value = var.create_k3s_cluster ? {
    master_ip = module.ec2.k3s_master_public_ip
    worker1_ip = module.ec2.k3s_worker_private_ips[0]
    worker2_ip = module.ec2.k3s_worker_private_ips[1]
  } : null
}


