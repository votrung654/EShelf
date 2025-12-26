# Security Groups Module Outputs

output "bastion_sg_id" {
  description = "Bastion security group ID"
  value       = var.use_existing_security_groups ? var.existing_bastion_sg_id : aws_security_group.bastion[0].id
}

output "app_sg_id" {
  description = "Application security group ID"
  value       = var.use_existing_security_groups ? var.existing_app_sg_id : aws_security_group.app[0].id
}

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = var.use_existing_security_groups ? var.existing_alb_sg_id : aws_security_group.alb[0].id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = var.use_existing_security_groups ? var.existing_rds_sg_id : aws_security_group.rds[0].id
}

output "k3s_master_sg_id" {
  description = "K3s master security group ID"
  value       = var.use_existing_security_groups ? var.existing_k3s_master_sg_id : aws_security_group.k3s_master[0].id
}

output "k3s_worker_sg_id" {
  description = "K3s worker security group ID"
  value       = var.use_existing_security_groups ? var.existing_k3s_worker_sg_id : aws_security_group.k3s_worker[0].id
}


