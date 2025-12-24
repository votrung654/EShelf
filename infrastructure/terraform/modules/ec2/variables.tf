# EC2 Module Variables

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

variable "create_key_pair" {
  description = "Create a new key pair"
  type        = bool
  default     = true
}

variable "public_key" {
  description = "Public key for EC2 key pair"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Existing key pair name"
  type        = string
  default     = ""
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "Instance type for application servers"
  type        = string
  default     = "t3.small"
}

variable "app_instance_count" {
  description = "Number of application servers"
  type        = number
  default     = 2
}

variable "k3s_master_instance_type" {
  description = "Instance type for K3s master node"
  type        = string
  default     = "t3.medium"
}

variable "k3s_worker_instance_type" {
  description = "Instance type for K3s worker nodes"
  type        = string
  default     = "t3.small"
}

variable "k3s_worker_count" {
  description = "Number of K3s worker nodes"
  type        = number
  default     = 2
}

variable "create_k3s_cluster" {
  description = "Create K3s cluster (1 master + N workers)"
  type        = bool
  default     = false
}

variable "public_subnet_id" {
  description = "Public subnet ID for bastion"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for app servers"
  type        = list(string)
}

variable "bastion_sg_id" {
  description = "Bastion security group ID"
  type        = string
}

variable "app_sg_id" {
  description = "Application security group ID"
  type        = string
}

variable "k3s_master_sg_id" {
  description = "K3s master security group ID"
  type        = string
  default     = ""
}

variable "k3s_worker_sg_id" {
  description = "K3s worker security group ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}


