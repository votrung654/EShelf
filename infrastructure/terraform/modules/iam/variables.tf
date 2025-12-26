# IAM Module Variables

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

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}



