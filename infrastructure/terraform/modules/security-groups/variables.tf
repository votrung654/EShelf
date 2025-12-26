# Security Groups Module Variables

variable "project" {
  description = "Project name"
  type        = string
  default     = "eshelf"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_k3s_cluster" {
  description = "Create K3s cluster security groups"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# Use existing security groups (for AWS Academy with restricted permissions)
variable "use_existing_security_groups" {
  description = "Use existing security groups instead of creating new ones"
  type        = bool
  default     = false
}

variable "existing_bastion_sg_id" {
  description = "Existing bastion security group ID"
  type        = string
  default     = ""
}

variable "existing_app_sg_id" {
  description = "Existing app security group ID"
  type        = string
  default     = ""
}

variable "existing_alb_sg_id" {
  description = "Existing ALB security group ID"
  type        = string
  default     = ""
}

variable "existing_k3s_master_sg_id" {
  description = "Existing K3s master security group ID"
  type        = string
  default     = ""
}

variable "existing_k3s_worker_sg_id" {
  description = "Existing K3s worker security group ID"
  type        = string
  default     = ""
}

variable "existing_rds_sg_id" {
  description = "Existing RDS security group ID"
  type        = string
  default     = ""
}


