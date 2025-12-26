# VPC Module for eShelf
# Lab 1 - Infrastructure as Code

# Data source for existing VPC
data "aws_vpc" "existing" {
  count = var.use_existing_vpc && var.existing_vpc_id != "" ? 1 : 0
  id    = var.existing_vpc_id
}

# VPC - Create new or use existing
resource "aws_vpc" "main" {
  count = var.use_existing_vpc ? 0 : 1

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project}-vpc-${var.environment}"
  })
}

# Internet Gateway - Only create if not using existing VPC
# Default VPC already has IGW, so we skip creation
resource "aws_internet_gateway" "main" {
  count = var.use_existing_vpc ? 0 : 1

  vpc_id = local.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project}-igw-${var.environment}"
  })
}

# Note: We don't use data sources for subnets/route tables because of permission restrictions
# We use the IDs directly from terraform.tfvars

# Local values
locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.main[0].id
  vpc_cidr_block = var.use_existing_vpc ? data.aws_vpc.existing[0].cidr_block : aws_vpc.main[0].cidr_block
  # If existing_igw_id is provided, use it directly; otherwise create new (if not using existing VPC)
  # For existing VPC without IGW ID, we skip IGW creation (default VPC already has IGW)
  igw_id = var.use_existing_vpc && var.existing_igw_id != "" ? var.existing_igw_id : (var.use_existing_vpc ? "" : aws_internet_gateway.main[0].id)
  
  # Use existing subnets if provided, otherwise use created subnets
  public_subnet_ids = var.use_existing_subnets ? var.existing_public_subnet_ids : aws_subnet.public[*].id
  private_subnet_ids = var.use_existing_subnets ? var.existing_private_subnet_ids : aws_subnet.private[*].id
}

# Public Subnets - Create new or use existing
# checkov:skip=CKV_AWS_130:Public subnets require public IP assignment for internet access
resource "aws_subnet" "public" {
  count = var.use_existing_subnets ? 0 : length(var.public_subnet_cidrs)

  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project}-public-subnet-${count.index + 1}-${var.environment}"
    Tier = "Public"
  })
}

# Private Subnets - Create new or use existing
resource "aws_subnet" "private" {
  count = var.use_existing_subnets ? 0 : length(var.private_subnet_cidrs)

  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.project}-private-subnet-${count.index + 1}-${var.environment}"
    Tier = "Private"
  })
}

# Elastic IP for NAT Gateway - Only create if not using existing subnets
# checkov:skip=CKV2_AWS_19:EIP is attached to NAT Gateway, not EC2 instance
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway && !var.use_existing_subnets ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project}-nat-eip-${var.environment}"
  })

  depends_on = [local.igw_id]
}

# NAT Gateway - Only create if not using existing subnets
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway && !var.use_existing_subnets ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.project}-nat-${var.environment}"
  })

  depends_on = [local.igw_id]
}

# Public Route Table - Only create if not using existing subnets
# When using existing subnets, we use the default route table that already exists
resource "aws_route_table" "public" {
  count = var.use_existing_subnets ? 0 : 1
  
  vpc_id = local.vpc_id

  dynamic "route" {
    for_each = local.igw_id != "" ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = local.igw_id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-public-rt-${var.environment}"
  })
}

# Private Route Table - Only create if not using existing subnets
resource "aws_route_table" "private" {
  count = var.use_existing_subnets ? 0 : 1
  
  vpc_id = local.vpc_id

  dynamic "route" {
    for_each = var.enable_nat_gateway && length(aws_nat_gateway.main) > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-private-rt-${var.environment}"
  })
}

# Public Route Table Associations - Only if creating subnets
resource "aws_route_table_association" "public" {
  count = var.use_existing_subnets ? 0 : length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Table Associations - Only if creating subnets
resource "aws_route_table_association" "private" {
  count = var.use_existing_subnets ? 0 : length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}


