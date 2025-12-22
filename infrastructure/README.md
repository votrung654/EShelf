# eShelf Infrastructure

Infrastructure as Code for eShelf platform.

## Directory Structure

```
infrastructure/
├── terraform/
│   ├── modules/              # Reusable Terraform modules
│   │   ├── vpc/             # VPC, Subnets, IGW, NAT
│   │   ├── ec2/             # EC2 instances
│   │   └── security-groups/ # Security Groups
│   └── environments/
│       └── dev/             # Development environment
│
├── cloudformation/           # CloudFormation templates (Lab 1)
│   └── templates/
│       ├── vpc-stack.yaml
│       └── ec2-stack.yaml
│
├── kubernetes/               # Kubernetes manifests (Lab 2+)
│   ├── base/
│   ├── overlays/
│   └── helm/
│
└── ansible/                  # Configuration management
    ├── inventory/
    ├── playbooks/
    └── roles/
```

## Lab 1: Infrastructure as Code

### Terraform

Deploy AWS infrastructure with Terraform modules.

**Requirements:**
- VPC with public/private subnets (3 points)
- Route tables and NAT Gateway (2 points)
- EC2 instances (public/private) (2 points)
- Security Groups (2 points)
- Test cases (1 point)

**See:** [terraform/environments/dev/README.md](terraform/environments/dev/README.md)

### CloudFormation

Alternative IaC approach using AWS CloudFormation.

**See:** [cloudformation/README.md](cloudformation/README.md) (to be created)

## Lab 2: CI/CD Automation

### GitHub Actions

Automated Terraform deployment with security scanning.

**See:** [../.github/workflows/terraform.yml](../.github/workflows/terraform.yml)

### Jenkins

CI/CD pipeline for application deployment.

**See:** [jenkins/README.md](jenkins/README.md) (to be created)

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Cloud (VPC)                       │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Public Subnets (2 AZs)                 │ │
│  │  ┌──────────────┐         ┌──────────────┐         │ │
│  │  │   Bastion    │         │     NAT      │         │ │
│  │  │     Host     │         │   Gateway    │         │ │
│  │  │  (t3.micro)  │         │              │         │ │
│  │  └──────────────┘         └──────────────┘         │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │             Private Subnets (2 AZs)                 │ │
│  │  ┌──────────────┐         ┌──────────────┐         │ │
│  │  │ App Server 1 │         │ App Server 2 │         │ │
│  │  │  (t3.small)  │         │  (t3.small)  │         │ │
│  │  │   Docker     │         │   Docker     │         │ │
│  │  └──────────────┘         └──────────────┘         │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │                   RDS PostgreSQL                    │ │
│  │                   ElastiCache Redis                 │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Security

### Security Groups

| SG | Inbound | Outbound |
|----|---------|----------|
| Bastion | SSH (22) from your IP | All |
| App | SSH from Bastion, Port 3000 from ALB | All |
| ALB | HTTP (80), HTTPS (443) from anywhere | All |
| RDS | PostgreSQL (5432) from App SG | None |

### Best Practices

- ✅ Use specific IP for SSH access
- ✅ Enable encryption at rest
- ✅ Use IAM roles instead of access keys
- ✅ Enable VPC Flow Logs
- ✅ Use AWS Secrets Manager for credentials

## Cost Estimation

### Development Environment

| Resource | Type | Monthly Cost (USD) |
|----------|------|-------------------|
| EC2 Bastion | t3.micro | ~$7.50 |
| EC2 App (x2) | t3.small | ~$30 |
| NAT Gateway | - | ~$32 |
| RDS PostgreSQL | db.t3.micro | ~$15 |
| ElastiCache | cache.t3.micro | ~$12 |
| **Total** | | **~$96.50** |

**Note:** Use AWS Free Tier when possible. Stop resources when not in use.

## Cleanup

```bash
# Terraform
cd terraform/environments/dev
terraform destroy

# CloudFormation
aws cloudformation delete-stack --stack-name eshelf-vpc
aws cloudformation delete-stack --stack-name eshelf-ec2
```

## Next Steps

After infrastructure is ready:
1. Deploy application services
2. Setup Kubernetes cluster
3. Configure monitoring
4. Setup CI/CD pipelines

See [PLAN.md](../PLAN.md) for detailed roadmap.

