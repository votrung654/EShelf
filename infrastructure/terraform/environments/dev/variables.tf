# Development Environment Variables

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
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
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "App server instance type"
  type        = string
  default     = "t3.small"
}

variable "app_instance_count" {
  description = "Number of app servers"
  type        = number
  default     = 2
}

variable "create_k3s_cluster" {
  description = "Create K3s cluster (1 master + 2 workers)"
  type        = bool
  default     = true
}

variable "k3s_master_instance_type" {
  description = "K3s master instance type"
  type        = string
  default     = "t3.medium"
}

variable "k3s_worker_instance_type" {
  description = "K3s worker instance type"
  type        = string
  default     = "t3.small"
}

variable "k3s_worker_count" {
  description = "Number of K3s worker nodes"
  type        = number
  default     = 2
}

variable "k3s_token" {
  description = "Pre-shared K3s token for joining workers (if empty, will use default)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ami_id" {
  description = "AMI ID for EC2 instances. If empty, will try to query (requires ec2:DescribeImages permission)"
  type        = string
  default     = ""
}

# Use existing VPC (for AWS Academy with restricted permissions)
variable "use_existing_vpc" {
  description = "Use existing VPC instead of creating new one"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "Existing VPC ID (required if use_existing_vpc = true)"
  type        = string
  default     = ""
}

variable "existing_igw_id" {
  description = "Existing Internet Gateway ID (optional, will create if not provided)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Existing EC2 key pair name (required if create_key_pair = false)"
  type        = string
  default     = ""
}

# Use existing subnets (for AWS Academy with restricted permissions)
variable "use_existing_subnets" {
  description = "Use existing subnets instead of creating new ones"
  type        = bool
  default     = false
}

variable "existing_public_subnet_ids" {
  description = "Existing public subnet IDs (required if use_existing_subnets = true)"
  type        = list(string)
  default     = []
}

variable "existing_private_subnet_ids" {
  description = "Existing private subnet IDs (required if use_existing_subnets = true)"
  type        = list(string)
  default     = []
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


