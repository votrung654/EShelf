# eShelf Development Environment

Terraform configuration for Lab 1 - Infrastructure as Code.

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- AWS account with appropriate permissions

## Setup

### 1. Configure Variables

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
# - Add your SSH public key
# - Change allowed_ssh_cidrs to your IP
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Validate Configuration

```bash
terraform validate
terraform fmt -check
```

### 4. Plan Infrastructure

```bash
terraform plan -out=tfplan
```

### 5. Apply Infrastructure

```bash
terraform apply tfplan
```

## Outputs

After successful apply, you'll get:

```
vpc_id = "vpc-xxxxx"
bastion_public_ip = "x.x.x.x"
app_private_ips = ["10.0.10.x", "10.0.11.x"]
ssh_command = "ssh -i key.pem ec2-user@x.x.x.x"
```

## Testing

### Test SSH to Bastion

```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>
```

### Test SSH to Private EC2 via Bastion

```bash
# Add key to ssh-agent
ssh-add ~/.ssh/your-key.pem

# SSH with jump host
ssh -J ec2-user@<bastion-ip> ec2-user@<private-ip>
```

### Test NAT Gateway

```bash
# From private EC2
curl ifconfig.me
# Should return NAT Gateway's public IP
```

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Or destroy specific resources
terraform destroy -target=module.ec2
```

## Modules Used

- `../../modules/vpc` - VPC, Subnets, IGW, NAT
- `../../modules/security-groups` - Security Groups
- `../../modules/ec2` - Bastion and App servers

## Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets
│   ├── 10.0.1.0/24 (AZ-a)
│   │   └── Bastion Host
│   └── 10.0.2.0/24 (AZ-b)
│       └── NAT Gateway
└── Private Subnets
    ├── 10.0.10.0/24 (AZ-a)
    │   └── App Server 1
    └── 10.0.11.0/24 (AZ-b)
        └── App Server 2
```

## Troubleshooting

### Error: VPC already exists

```bash
# Import existing VPC
terraform import module.vpc.aws_vpc.main vpc-xxxxx
```

### Error: Key pair already exists

```bash
# Set create_key_pair = false in terraform.tfvars
# Specify existing key_name
```

### Error: Insufficient permissions

Check your AWS IAM permissions include:
- EC2 full access
- VPC full access
- IAM (for instance profiles)

