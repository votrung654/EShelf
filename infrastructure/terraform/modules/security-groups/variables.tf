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
  default     = ["0.0.0.0/0"] # Change to specific IP in production
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}


