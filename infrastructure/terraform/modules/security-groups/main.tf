# Security Groups Module for eShelf

# Note: We don't use data source for security groups because of permission restrictions
# We use the IDs directly from terraform.tfvars

# Bastion Security Group - Create new or use existing
# checkov:skip=CKV2_AWS_5:Security group is attached to EC2 instances via module references
resource "aws_security_group" "bastion" {
  count = var.use_existing_security_groups ? 0 : 1
  name        = "${var.project}-bastion-sg-${var.environment}"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # checkov:skip=CKV_AWS_24:SSH access is restricted via allowed_ssh_cidrs variable
  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # checkov:skip=CKV_AWS_382:Egress all traffic is required for functionality
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-bastion-sg-${var.environment}"
  })
}

# Application Security Group - Create new or use existing
# checkov:skip=CKV2_AWS_5:Security group is attached to EC2 instances via module references
resource "aws_security_group" "app" {
  count = var.use_existing_security_groups ? 0 : 1
  name        = "${var.project}-app-sg-${var.environment}"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  # SSH from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = var.use_existing_security_groups ? [var.existing_bastion_sg_id] : [aws_security_group.bastion[0].id]
  }

  # HTTP from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = var.use_existing_security_groups ? [var.existing_alb_sg_id] : [aws_security_group.alb[0].id]
  }

  # Internal communication
  ingress {
    description = "Internal communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # checkov:skip=CKV_AWS_382:Egress all traffic is required for functionality
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-app-sg-${var.environment}"
  })
}

# ALB Security Group - Create new or use existing
# checkov:skip=CKV2_AWS_5:Security group is attached to ALB via module references
resource "aws_security_group" "alb" {
  count = var.use_existing_security_groups ? 0 : 1
  name        = "${var.project}-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # checkov:skip=CKV_AWS_260:ALB requires public HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # checkov:skip=CKV_AWS_382:Egress all traffic is required for functionality
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-alb-sg-${var.environment}"
  })
}

# K3s Master Security Group - Create new or use existing
resource "aws_security_group" "k3s_master" {
  count = var.use_existing_security_groups ? 0 : 1
  name        = "${var.project}-k3s-master-sg-${var.environment}"
  description = "Security group for K3s master node"
  vpc_id      = var.vpc_id

  # checkov:skip=CKV_AWS_24:SSH access is restricted via allowed_ssh_cidrs variable
  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # K3s API Server (from VPC)
  ingress {
    description = "K3s API Server from VPC"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # K3s API Server (from Internet - for kubectl access)
  # checkov:skip=CKV_AWS_24:K3s API server requires public access for kubectl
  ingress {
    description = "K3s API Server from Internet"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K3s Flannel VXLAN
  ingress {
    description = "K3s Flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # K3s Kubelet metrics
  ingress {
    description = "K3s Kubelet metrics"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # K3s etcd
  ingress {
    description = "K3s etcd client"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # checkov:skip=CKV_AWS_382:Egress all traffic is required for functionality
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-k3s-master-sg-${var.environment}"
  })
}

# K3s Worker Security Group - Create new or use existing
resource "aws_security_group" "k3s_worker" {
  count = var.use_existing_security_groups ? 0 : 1
  name        = "${var.project}-k3s-worker-sg-${var.environment}"
  description = "Security group for K3s worker nodes"
  vpc_id      = var.vpc_id

  # SSH from Master or Bastion
  ingress {
    description     = "SSH from Master"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = var.use_existing_security_groups ? [var.existing_k3s_master_sg_id] : [aws_security_group.k3s_master[0].id]
  }

  # K3s Flannel VXLAN
  ingress {
    description = "K3s Flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # K3s Kubelet metrics
  ingress {
    description = "K3s Kubelet metrics"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NodePort range
  # checkov:skip=CKV_AWS_260:NodePort services require public access
  ingress {
    description = "NodePort services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal communication
  ingress {
    description = "Internal communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # checkov:skip=CKV_AWS_382:Egress all traffic is required for functionality
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-k3s-worker-sg-${var.environment}"
  })
}

# RDS Security Group - Create new or use existing
resource "aws_security_group" "rds" {
  count = var.use_existing_security_groups ? 0 : 1
  name        = "${var.project}-rds-sg-${var.environment}"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  # PostgreSQL from App or K3s Workers
  ingress {
    description     = "PostgreSQL from App"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.use_existing_security_groups ? (
      concat(
        var.existing_app_sg_id != "" ? [var.existing_app_sg_id] : [],
        var.create_k3s_cluster && var.existing_k3s_worker_sg_id != "" ? [var.existing_k3s_worker_sg_id] : []
      )
    ) : concat(
      [aws_security_group.app[0].id],
      var.create_k3s_cluster ? [aws_security_group.k3s_worker[0].id] : []
    )
  }

  tags = merge(var.tags, {
    Name = "${var.project}-rds-sg-${var.environment}"
  })
}

