# EC2 Module for eShelf

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair
resource "aws_key_pair" "main" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.project}-keypair-${var.environment}"
  public_key = var.public_key

  tags = merge(var.tags, {
    Name = "${var.project}-keypair-${var.environment}"
  })
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.bastion_instance_type
  key_name                    = var.create_key_pair ? aws_key_pair.main[0].key_name : var.key_name
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF

  tags = merge(var.tags, {
    Name = "${var.project}-bastion-${var.environment}"
    Role = "Bastion"
  })
}

# K3s Master Node
resource "aws_instance" "k3s_master" {
  count = var.create_k3s_cluster ? 1 : 0

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.k3s_master_instance_type
  key_name                    = var.create_key_pair ? aws_key_pair.main[0].key_name : var.key_name
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.k3s_master_sg_id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y curl wget vim net-tools
              
              # Disable swap
              swapoff -a
              sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
              
              # Load kernel modules
              modprobe br_netfilter
              modprobe overlay
              
              # Configure sysctl
              cat > /etc/sysctl.d/k8s.conf <<EOF2
              net.bridge.bridge-nf-call-iptables = 1
              net.bridge.bridge-nf-call-ip6tables = 1
              net.ipv4.ip_forward = 1
              EOF2
              sysctl --system
              EOF

  tags = merge(var.tags, {
    Name = "${var.project}-k3s-master-${var.environment}"
    Role = "K3s-Master"
  })
}

# K3s Worker Nodes
resource "aws_instance" "k3s_worker" {
  count = var.create_k3s_cluster ? var.k3s_worker_count : 0

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.k3s_worker_instance_type
  key_name               = var.create_key_pair ? aws_key_pair.main[0].key_name : var.key_name
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.k3s_worker_sg_id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y curl wget vim net-tools
              
              # Disable swap
              swapoff -a
              sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
              
              # Load kernel modules
              modprobe br_netfilter
              modprobe overlay
              
              # Configure sysctl
              cat > /etc/sysctl.d/k8s.conf <<EOF2
              net.bridge.bridge-nf-call-iptables = 1
              net.bridge.bridge-nf-call-ip6tables = 1
              net.ipv4.ip_forward = 1
              EOF2
              sysctl --system
              EOF

  tags = merge(var.tags, {
    Name = "${var.project}-k3s-worker-${count.index + 1}-${var.environment}"
    Role = "K3s-Worker"
  })
}

# Application Server (for non-K3s deployments)
resource "aws_instance" "app" {
  count = var.create_k3s_cluster ? 0 : var.app_instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.app_instance_type
  key_name               = var.create_key_pair ? aws_key_pair.main[0].key_name : var.key_name
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.app_sg_id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              
              # Install Docker
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              
              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # Install Node.js
              curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
              yum install -y nodejs
              EOF

  tags = merge(var.tags, {
    Name = "${var.project}-app-${count.index + 1}-${var.environment}"
    Role = "Application"
  })
}


