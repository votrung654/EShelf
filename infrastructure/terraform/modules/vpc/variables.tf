# VPC Module Variables

variable "project" {
  description = "Project name"
  type        = string
  default     = "eshelf"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# Use existing VPC
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


