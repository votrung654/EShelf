# VPC Module Outputs

output "vpc_id" {
  description = "VPC ID"
  value       = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = var.use_existing_vpc ? var.vpc_cidr : aws_vpc.main[0].cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = local.private_subnet_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = var.use_existing_vpc ? (var.existing_igw_id != "" ? var.existing_igw_id : null) : (length(aws_internet_gateway.main) > 0 ? aws_internet_gateway.main[0].id : null)
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = var.use_existing_subnets ? null : aws_route_table.public[0].id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = var.use_existing_subnets ? null : aws_route_table.private[0].id
}


