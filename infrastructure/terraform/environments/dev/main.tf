# eShelf Development Environment
# Terraform configuration for Lab 1

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment for remote state
  # backend "s3" {
  #   bucket         = "eshelf-terraform-state"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "eshelf-terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  # Skip AMI validation (required when no DescribeImages permission)
  skip_credentials_validation = false
  skip_metadata_api_check     = true
  skip_region_validation      = false

  default_tags {
    tags = {
      Project     = "eShelf"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

# Local variables
locals {
  project     = "eshelf"
  environment = "dev"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project                     = local.project
  environment                 = local.environment
  vpc_cidr                    = var.vpc_cidr
  availability_zones          = var.availability_zones
  public_subnet_cidrs         = var.public_subnet_cidrs
  private_subnet_cidrs        = var.private_subnet_cidrs
  enable_nat_gateway          = var.enable_nat_gateway
  use_existing_vpc            = var.use_existing_vpc
  existing_vpc_id             = var.existing_vpc_id
  existing_igw_id             = var.existing_igw_id
  use_existing_subnets        = var.use_existing_subnets
  existing_public_subnet_ids  = var.existing_public_subnet_ids
  existing_private_subnet_ids = var.existing_private_subnet_ids
  tags                        = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project     = local.project
  environment = local.environment
  tags        = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  project                      = local.project
  environment                  = local.environment
  vpc_id                       = module.vpc.vpc_id
  vpc_cidr                     = var.vpc_cidr
  allowed_ssh_cidrs            = var.allowed_ssh_cidrs
  create_k3s_cluster           = var.create_k3s_cluster
  use_existing_security_groups = var.use_existing_security_groups
  existing_bastion_sg_id       = var.existing_bastion_sg_id
  existing_app_sg_id           = var.existing_app_sg_id
  existing_alb_sg_id           = var.existing_alb_sg_id
  existing_k3s_master_sg_id    = var.existing_k3s_master_sg_id
  existing_k3s_worker_sg_id    = var.existing_k3s_worker_sg_id
  existing_rds_sg_id           = var.existing_rds_sg_id
  tags                         = local.common_tags
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  project                  = local.project
  environment              = local.environment
  create_key_pair          = var.create_key_pair
  public_key               = var.public_key
  key_name                 = var.key_name
  bastion_instance_type    = var.bastion_instance_type
  app_instance_type        = var.app_instance_type
  app_instance_count       = var.app_instance_count
  create_k3s_cluster       = var.create_k3s_cluster
  k3s_master_instance_type = var.k3s_master_instance_type
  k3s_worker_instance_type = var.k3s_worker_instance_type
  k3s_worker_count         = var.k3s_worker_count
  public_subnet_id         = module.vpc.public_subnet_ids[0]
  private_subnet_ids       = module.vpc.private_subnet_ids
  bastion_sg_id            = module.security_groups.bastion_sg_id
  app_sg_id                = module.security_groups.app_sg_id
  k3s_master_sg_id         = var.create_k3s_cluster ? module.security_groups.k3s_master_sg_id : ""
  k3s_worker_sg_id         = var.create_k3s_cluster ? module.security_groups.k3s_worker_sg_id : ""
  iam_instance_profile     = module.iam.ec2_ssm_instance_profile_name
  k3s_token                = var.k3s_token
  ami_id                   = var.ami_id
  tags                     = local.common_tags
}

