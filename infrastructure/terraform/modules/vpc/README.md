# VPC Module

Terraform module for creating VPC infrastructure.

## Resources Created

- VPC with DNS support
- Internet Gateway
- Public Subnets (2 AZs)
- Private Subnets (2 AZs)
- NAT Gateway with Elastic IP
- Route Tables (Public & Private)
- Route Table Associations

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project             = "eshelf"
  environment         = "dev"
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway  = true
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project | Project name | string | "eshelf" |
| environment | Environment name | string | "dev" |
| vpc_cidr | VPC CIDR block | string | "10.0.0.0/16" |
| availability_zones | List of AZs | list(string) | ["ap-southeast-1a", "ap-southeast-1b"] |
| public_subnet_cidrs | Public subnet CIDRs | list(string) | ["10.0.1.0/24", "10.0.2.0/24"] |
| private_subnet_cidrs | Private subnet CIDRs | list(string) | ["10.0.10.0/24", "10.0.11.0/24"] |
| enable_nat_gateway | Enable NAT Gateway | bool | true |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| internet_gateway_id | Internet Gateway ID |
| nat_gateway_id | NAT Gateway ID |
| public_route_table_id | Public route table ID |
| private_route_table_id | Private route table ID |

