# eShelf Production Environment
# Terraform configuration for production infrastructure

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "eshelf-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "eshelf-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "eShelf"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  project     = "eshelf"
  environment = "production"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project             = local.project
  environment         = local.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway  = var.enable_nat_gateway
  tags                = local.common_tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  project            = local.project
  environment        = local.environment
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  allowed_ssh_cidrs  = var.allowed_ssh_cidrs
  create_k3s_cluster = var.create_k3s_cluster
  tags               = local.common_tags
}

module "ec2" {
  source = "../../modules/ec2"

  project                 = local.project
  environment             = local.environment
  create_key_pair         = var.create_key_pair
  public_key              = var.public_key
  bastion_instance_type   = var.bastion_instance_type
  app_instance_type       = var.app_instance_type
  app_instance_count      = var.app_instance_count
  create_k3s_cluster      = var.create_k3s_cluster
  k3s_master_instance_type = var.k3s_master_instance_type
  k3s_worker_instance_type = var.k3s_worker_instance_type
  k3s_worker_count        = var.k3s_worker_count
  public_subnet_id        = module.vpc.public_subnet_ids[0]
  private_subnet_ids      = module.vpc.private_subnet_ids
  bastion_sg_id           = module.security_groups.bastion_sg_id
  app_sg_id                = module.security_groups.app_sg_id
  k3s_master_sg_id        = var.create_k3s_cluster ? module.security_groups.k3s_master_sg_id : ""
  k3s_worker_sg_id        = var.create_k3s_cluster ? module.security_groups.k3s_worker_sg_id : ""
  tags                     = local.common_tags
}

