# Production Environment Variables

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.2.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_key_pair" {
  description = "Create new key pair"
  type        = bool
  default     = true
}

variable "public_key" {
  description = "Public key for EC2"
  type        = string
  default     = ""
}

variable "bastion_instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t3.small"
}

variable "app_instance_type" {
  description = "App server instance type"
  type        = string
  default     = "t3.medium"
}

variable "app_instance_count" {
  description = "Number of app servers"
  type        = number
  default     = 3
}

variable "create_k3s_cluster" {
  description = "Create K3s cluster (1 master + 2 workers)"
  type        = bool
  default     = true
}

variable "k3s_master_instance_type" {
  description = "K3s master instance type"
  type        = string
  default     = "t3.large"
}

variable "k3s_worker_instance_type" {
  description = "K3s worker instance type"
  type        = string
  default     = "t3.medium"
}

variable "k3s_worker_count" {
  description = "Number of K3s worker nodes"
  type        = number
  default     = 2
}

