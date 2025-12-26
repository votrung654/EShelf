# EC2 Module for eShelf

# Get latest Amazon Linux 2023 AMI (only if ami_id is not provided)
data "aws_ami" "amazon_linux" {
  count = var.ami_id == "" ? 1 : 0
  
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

# Local value for AMI ID
locals {
  ami_id = var.ami_id != "" ? var.ami_id : (length(data.aws_ami.amazon_linux) > 0 ? data.aws_ami.amazon_linux[0].id : "")
  key_name = var.create_key_pair ? aws_key_pair.main[0].key_name : (var.key_name != "" ? var.key_name : null)
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
  ami                         = local.ami_id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true
  # key_name is optional - only set if not null
  key_name                    = local.key_name
  iam_instance_profile        = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  # Skip AMI validation (required when no DescribeImages permission)
  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
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

  ami                         = local.ami_id
  instance_type               = var.k3s_master_instance_type
  key_name                    = local.key_name
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.k3s_master_sg_id]
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  # Skip AMI validation (required when no DescribeImages permission)
  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update system (skip curl package conflicts)
              yum update -y --skip-broken || true
              
              # Install required packages (use curl-minimal if curl conflicts)
              yum install -y wget vim net-tools || true
              
              # Install curl if not present
              if ! command -v curl &> /dev/null; then
                yum install -y curl --allowerasing || yum install -y curl-minimal || true
              fi
              
              # Disable swap
              swapoff -a || true
              sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true
              
              # Load kernel modules
              modprobe br_netfilter || true
              modprobe overlay || true
              
              # Configure sysctl
              cat > /etc/sysctl.d/k3s.conf <<EOF2
              net.bridge.bridge-nf-call-iptables = 1
              net.bridge.bridge-nf-call-ip6tables = 1
              net.ipv4.ip_forward = 1
              EOF2
              sysctl --system || true
              
              # Get master IP (use private IP from metadata)
              MASTER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4)
              PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || wget -q -O - http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")
              
              # Install K3s server with retry logic (use specific version)
              # IMPORTANT: Use private IP for node-ip, public IP only for tls-san
              echo "Installing K3s server..."
              echo "Master Private IP: $${MASTER_IP}"
              echo "Master Public IP: $${PUBLIC_IP}"
              K3S_VERSION="v1.28.5+k3s1"
              MAX_RETRIES=5
              RETRY=0
              while [ $RETRY -lt $MAX_RETRIES ]; do
                # Build install command
                if [ -n "$${PUBLIC_IP}" ]; then
                  INSTALL_CMD="curl -sfL https://get.k3s.io 2>/dev/null | INSTALL_K3S_VERSION=$${K3S_VERSION} sh -s - server --cluster-init --tls-san $${MASTER_IP} --tls-san $${PUBLIC_IP} --node-ip $${MASTER_IP}"
                else
                  INSTALL_CMD="curl -sfL https://get.k3s.io 2>/dev/null | INSTALL_K3S_VERSION=$${K3S_VERSION} sh -s - server --cluster-init --tls-san $${MASTER_IP} --node-ip $${MASTER_IP}"
                fi
                
                if eval $${INSTALL_CMD} 2>&1; then
                  echo "K3s installed successfully!"
                  break
                fi
                
                # Try with wget
                if [ -n "$${PUBLIC_IP}" ]; then
                  INSTALL_CMD="wget -q -O - https://get.k3s.io 2>/dev/null | INSTALL_K3S_VERSION=$${K3S_VERSION} sh -s - server --cluster-init --tls-san $${MASTER_IP} --tls-san $${PUBLIC_IP} --node-ip $${MASTER_IP}"
                else
                  INSTALL_CMD="wget -q -O - https://get.k3s.io 2>/dev/null | INSTALL_K3S_VERSION=$${K3S_VERSION} sh -s - server --cluster-init --tls-san $${MASTER_IP} --node-ip $${MASTER_IP}"
                fi
                
                if eval $${INSTALL_CMD} 2>&1; then
                  echo "K3s installed successfully with wget!"
                  break
                fi
                
                RETRY=$((RETRY + 1))
                echo "Retry $RETRY/$MAX_RETRIES failed, waiting 10 seconds..."
                sleep 10
              done
              
              if [ $RETRY -eq $MAX_RETRIES ]; then
                echo "ERROR: Failed to install K3s after $MAX_RETRIES retries"
                exit 1
              fi
              
              # Wait for K3s to be ready
              echo "Waiting for K3s to be ready..."
              timeout=300
              elapsed=0
              while [ ! -f /etc/rancher/k3s/k3s.yaml ] && [ $elapsed -lt $timeout ]; do
                sleep 5
                elapsed=$((elapsed + 5))
              done
              
              # Setup kubeconfig
              mkdir -p /home/ec2-user/.kube
              if [ -f /etc/rancher/k3s/k3s.yaml ]; then
                cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
                chown -R ec2-user:ec2-user /home/ec2-user/.kube
                sed -i "s/127.0.0.1/$${MASTER_IP}/g" /home/ec2-user/.kube/config || true
                if [ -n "$${PUBLIC_IP}" ]; then
                  sed -i "s/127.0.0.1/$${PUBLIC_IP}/g" /home/ec2-user/.kube/config || true
                fi
              fi
              
              # Install kubectl
              if [ ! -f /usr/local/bin/kubectl ]; then
                KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt 2>/dev/null || wget -q -O - https://dl.k8s.io/release/stable.txt)
                if curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl" 2>/dev/null || \
                   wget -q "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl" 2>/dev/null; then
                  if [ -f kubectl ]; then
                    chmod +x kubectl
                    mv kubectl /usr/local/bin/ || true
                  fi
                fi
              fi
              
              # Save token for workers
              if [ -f /var/lib/rancher/k3s/server/node-token ]; then
                cat /var/lib/rancher/k3s/server/node-token > /tmp/k3s-token.txt
                chmod 644 /tmp/k3s-token.txt
              fi
              
              echo "K3s Master deployment completed!"
              EOF

  tags = merge(var.tags, {
    Name = "${var.project}-k3s-master-${var.environment}"
    Role = "K3s-Master"
  })
}

# K3s Worker Nodes
resource "aws_instance" "k3s_worker" {
  count = var.create_k3s_cluster ? var.k3s_worker_count : 0

  ami                    = local.ami_id
  instance_type          = var.k3s_worker_instance_type
  key_name               = local.key_name
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.k3s_worker_sg_id]
  iam_instance_profile   = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  # Skip AMI validation (required when no DescribeImages permission)
  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update system (skip curl package conflicts)
              yum update -y --skip-broken || true
              
              # Install required packages (use curl-minimal if curl conflicts)
              yum install -y wget vim net-tools || true
              
              # Install curl if not present
              if ! command -v curl &> /dev/null; then
                yum install -y curl --allowerasing || yum install -y curl-minimal || true
              fi
              
              # Disable swap
              swapoff -a || true
              sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true
              
              # Load kernel modules
              modprobe br_netfilter || true
              modprobe overlay || true
              
              # Configure sysctl
              cat > /etc/sysctl.d/k3s.conf <<EOF2
              net.bridge.bridge-nf-call-iptables = 1
              net.bridge.bridge-nf-call-ip6tables = 1
              net.ipv4.ip_forward = 1
              EOF2
              sysctl --system || true
              
              # Get worker IP
              WORKER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4)
              
              # Get master IP from instance tag (set by Terraform)
              # Master IP is stored in tag "K3sMasterIP"
              INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
              REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null | sed 's/.$//' || wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
              MASTER_IP=$(aws ec2 describe-tags --region $${REGION} --filters "Name=resource-id,Values=$${INSTANCE_ID}" "Name=key,Values=K3sMasterIP" --query "Tags[0].Value" --output text 2>/dev/null || echo "")
              
              # If tag not found, try to discover master from same VPC
              if [ -z "$${MASTER_IP}" ]; then
                # Use default master IP pattern or discover
                VPC_CIDR=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ 2>/dev/null | head -n1)/subnet-ipv4-cidr-block 2>/dev/null | cut -d'/' -f1 | sed 's/\.[0-9]*$$/.10/' || echo "172.31.35.10")
                MASTER_IP=$${VPC_CIDR}
              fi
              
              # Use pre-shared token
              K3S_TOKEN="${var.k3s_token != "" ? var.k3s_token : "changeme-token-12345"}"
              
              # Wait for master to be ready (retry logic)
              echo "Waiting for master to be ready..."
              MAX_RETRIES=60
              RETRY=0
              while [ $RETRY -lt $MAX_RETRIES ]; do
                if curl -k -sf https://$${MASTER_IP}:6443/healthz 2>/dev/null &> /dev/null || \
                   wget -q --no-check-certificate -O /dev/null https://$${MASTER_IP}:6443/healthz 2>/dev/null; then
                  echo "Master is ready!"
                  break
                fi
                echo "Waiting for master... ($RETRY/$MAX_RETRIES)"
                sleep 10
                RETRY=$((RETRY + 1))
              done
              
              # Install K3s agent with retry logic (use specific version)
              echo "Installing K3s agent..."
              K3S_VERSION="v1.28.5+k3s1"
              MAX_RETRIES=5
              RETRY=0
              while [ $RETRY -lt $MAX_RETRIES ]; do
                if curl -sfL https://get.k3s.io 2>/dev/null | INSTALL_K3S_VERSION=$${K3S_VERSION} K3S_URL=https://$${MASTER_IP}:6443 K3S_TOKEN=$${K3S_TOKEN} sh -s - agent --node-ip $${WORKER_IP} 2>&1; then
                  echo "K3s agent installed successfully!"
                  break
                elif wget -q -O - https://get.k3s.io 2>/dev/null | INSTALL_K3S_VERSION=$${K3S_VERSION} K3S_URL=https://$${MASTER_IP}:6443 K3S_TOKEN=$${K3S_TOKEN} sh -s - agent --node-ip $${WORKER_IP} 2>&1; then
                  echo "K3s agent installed successfully with wget!"
                  break
                else
                  RETRY=$((RETRY + 1))
                  echo "Retry $RETRY/$MAX_RETRIES failed, waiting 10 seconds..."
                  sleep 10
                fi
              done
              
              if [ $RETRY -eq $MAX_RETRIES ]; then
                echo "ERROR: Failed to install K3s agent after $MAX_RETRIES retries"
                exit 1
              fi
              
              echo "K3s Worker deployment completed!"
              EOF

  tags = merge(var.tags, {
    Name = "${var.project}-k3s-worker-${count.index + 1}-${var.environment}"
    Role = "K3s-Worker"
    K3sMasterIP = var.create_k3s_cluster ? aws_instance.k3s_master[0].private_ip : ""
  })
  
  depends_on = [aws_instance.k3s_master]
}

# Application Server (for non-K3s deployments)
resource "aws_instance" "app" {
  count = var.create_k3s_cluster ? 0 : var.app_instance_count

  ami                    = local.ami_id
  instance_type          = var.app_instance_type
  key_name               = local.key_name
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.app_sg_id]

  # Skip AMI validation (required when no DescribeImages permission)
  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
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


