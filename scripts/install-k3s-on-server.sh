#!/bin/bash
# Script cài đặt K3s hoàn chỉnh - Copy toàn bộ script này vào server và chạy
# Usage: bash install-k3s-on-server.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== K3s Installation Script ===${NC}"
echo ""

# Get master IP from terraform output hoặc set manually
MASTER_IP="${1:-54.252.223.41}"

if [ -z "$MASTER_IP" ]; then
    echo -e "${RED}Error: Master IP not provided${NC}"
    echo "Usage: bash install-k3s-on-server.sh <MASTER_IP>"
    exit 1
fi

echo -e "${YELLOW}Using Master IP: $MASTER_IP${NC}"
echo ""

# Step 1: Prepare system
echo -e "${GREEN}[1/7] Preparing system...${NC}"
sudo yum update -y
sudo yum install -y curl wget vim net-tools

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
sudo modprobe br_netfilter
sudo modprobe overlay

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k3s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

echo -e "${GREEN}✓ System prepared${NC}"
echo ""

# Step 2: Clean old K3s
echo -e "${GREEN}[2/7] Cleaning old K3s installation (if any)...${NC}"
sudo pkill -9 k3s 2>/dev/null || true
sudo systemctl stop k3s 2>/dev/null || true
sudo systemctl disable k3s 2>/dev/null || true

sudo rm -rf /var/lib/rancher/k3s
sudo rm -rf /etc/rancher/k3s
sudo rm -f /usr/local/bin/k3s
sudo rm -f /usr/local/bin/kubectl
sudo rm -f /usr/local/bin/crictl
sudo rm -f /usr/local/bin/ctr

sudo mkdir -p /etc/rancher/k3s
sudo mkdir -p /var/lib/rancher/k3s/server/db/etcd

echo -e "${GREEN}✓ Cleaned${NC}"
echo ""

# Step 3: Install K3s
echo -e "${GREEN}[3/7] Installing K3s...${NC}"

# Try method 1: Official installer with specific version
echo "Trying official installer..."
if curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -s - server \
  --cluster-init \
  --tls-san $MASTER_IP \
  --node-ip $MASTER_IP \
  --bind-address 0.0.0.0 \
  --disable traefik \
  --write-kubeconfig-mode 644 \
  --data-dir /var/lib/rancher/k3s 2>&1; then
    echo -e "${GREEN}✓ K3s installed via official installer${NC}"
else
    echo -e "${YELLOW}Official installer failed, trying direct binary download...${NC}"
    
    # Method 2: Direct binary download
    cd /tmp
    K3S_VERSION="v1.28.5+k3s1"
    
    if wget -q https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s -O /tmp/k3s || \
       curl -L https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s -o /tmp/k3s; then
        chmod +x /tmp/k3s
        sudo mv /tmp/k3s /usr/local/bin/k3s
        
        # Create systemd service
        sudo tee /etc/systemd/system/k3s.service > /dev/null <<EOF
[Unit]
Description=Lightweight Kubernetes
Documentation=https://k3s.io
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/k3s server \\
    --cluster-init \\
    --tls-san $MASTER_IP \\
    --node-ip $MASTER_IP \\
    --bind-address 0.0.0.0 \\
    --disable traefik \\
    --write-kubeconfig-mode 644 \\
    --data-dir /var/lib/rancher/k3s
KillMode=process
Delegate=yes
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
        
        sudo systemctl daemon-reload
        sudo systemctl enable k3s
        sudo systemctl start k3s
        
        echo -e "${GREEN}✓ K3s installed via direct binary${NC}"
    else
        echo -e "${RED}✗ Failed to download K3s binary${NC}"
        exit 1
    fi
fi

echo ""

# Step 4: Wait for K3s to start
echo -e "${GREEN}[4/7] Waiting for K3s to start (this may take 2-5 minutes)...${NC}"
timeout=300
elapsed=0
while [ ! -f /etc/rancher/k3s/k3s.yaml ] && [ $elapsed -lt $timeout ]; do
    sleep 5
    elapsed=$((elapsed + 5))
    echo "  Waiting... ($elapsed seconds)"
    
    # Check if service is running
    if sudo systemctl is-active k3s >/dev/null 2>&1; then
        echo "  Service is active"
    fi
done

if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
    echo -e "${RED}✗ K3s config file not created after $timeout seconds${NC}"
    echo "Checking service status..."
    sudo systemctl status k3s --no-pager | head -30
    echo ""
    echo "Checking logs..."
    sudo journalctl -u k3s -n 50 --no-pager | tail -50
    exit 1
fi

echo -e "${GREEN}✓ K3s started${NC}"
echo ""

# Step 5: Verify installation
echo -e "${GREEN}[5/7] Verifying installation...${NC}"

# Check service
if sudo systemctl is-active k3s >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Service is active${NC}"
else
    echo -e "${YELLOW}⚠ Service is not active${NC}"
fi

# Check port
if sudo netstat -tlnp 2>/dev/null | grep 6443 >/dev/null || sudo ss -tlnp 2>/dev/null | grep 6443 >/dev/null; then
    echo -e "${GREEN}✓ Port 6443 is listening${NC}"
else
    echo -e "${YELLOW}⚠ Port 6443 is not listening${NC}"
fi

# Check config
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    echo -e "${GREEN}✓ Config file exists${NC}"
else
    echo -e "${RED}✗ Config file does not exist${NC}"
    exit 1
fi

echo ""

# Step 6: Setup kubeconfig
echo -e "${GREEN}[6/7] Setting up kubeconfig...${NC}"
mkdir -p /home/ec2-user/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
sed -i "s/127.0.0.1/$MASTER_IP/g" /home/ec2-user/.kube/config

echo -e "${GREEN}✓ Kubeconfig setup complete${NC}"
echo ""

# Step 7: Test kubectl
echo -e "${GREEN}[7/7] Testing kubectl...${NC}"
sleep 10
if /usr/local/bin/k3s kubectl get nodes 2>&1; then
    echo ""
    echo -e "${GREEN}✓ kubectl test successful${NC}"
else
    echo -e "${YELLOW}⚠ kubectl test failed, but installation may still be in progress${NC}"
fi

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "Next steps:"
echo "1. Get kubeconfig to your local machine:"
echo "   cat /home/ec2-user/.kube/config"
echo ""
echo "2. Update kubeconfig on local machine with correct IP"
echo ""
echo "3. Test from local:"
echo "   kubectl get nodes"

