#!/bin/bash
# Script cài đặt K3s - Version 2 (Cải thiện theo feedback)
# Đảm bảo: LF line endings, đủ delays, ưu tiên binary download
# Usage: bash install-k3s-on-server-v2.sh <MASTER_IP>

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== K3s Installation Script v2 ===${NC}"
echo ""

MASTER_IP="${1:-54.252.223.41}"
K3S_VERSION="v1.28.5+k3s1"

if [ -z "$MASTER_IP" ]; then
    echo -e "${RED}Error: Master IP required${NC}"
    exit 1
fi

echo -e "${YELLOW}Master IP: $MASTER_IP${NC}"
echo -e "${YELLOW}K3s Version: $K3S_VERSION${NC}"
echo ""

# Step 1: Prepare system
echo -e "${GREEN}[1/8] Preparing system...${NC}"
sudo yum update -y >/dev/null 2>&1 || true
sudo yum install -y curl wget vim net-tools >/dev/null 2>&1

# Disable swap
sudo swapoff -a 2>/dev/null || true
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
sudo modprobe br_netfilter 2>/dev/null || true
sudo modprobe overlay 2>/dev/null || true

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k3s.conf >/dev/null
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system >/dev/null 2>&1

echo -e "${GREEN}✓ System prepared${NC}"
echo ""

# Step 2: Clean old K3s (QUAN TRỌNG: pkill -9 để kill zombie processes)
echo -e "${GREEN}[2/8] Cleaning old K3s (CRITICAL: killing zombie processes)...${NC}"
sudo pkill -9 k3s 2>/dev/null || true
sudo systemctl stop k3s 2>/dev/null || true
sudo systemctl disable k3s 2>/dev/null || true
sleep 3  # Đợi process thực sự dừng

# Clean files
sudo rm -rf /var/lib/rancher/k3s 2>/dev/null || true
sudo rm -rf /etc/rancher/k3s 2>/dev/null || true
sudo rm -f /usr/local/bin/k3s 2>/dev/null || true
sudo rm -f /usr/local/bin/kubectl 2>/dev/null || true
sudo rm -f /usr/local/bin/crictl 2>/dev/null || true
sudo rm -f /usr/local/bin/ctr 2>/dev/null || true

# Recreate directories
sudo mkdir -p /etc/rancher/k3s
sudo mkdir -p /var/lib/rancher/k3s/server/db/etcd

echo -e "${GREEN}✓ Cleaned (including zombie processes)${NC}"
echo ""

# Step 3: Download Binary (PHƯƠNG PHÁP 2 - Ưu tiên như Gemini khuyên)
echo -e "${GREEN}[3/8] Downloading K3s binary (Method 2 - Recommended)...${NC}"
cd /tmp

# Try wget first, fallback to curl
if wget -q --timeout=30 --tries=3 https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s -O /tmp/k3s 2>/dev/null; then
    echo -e "${GREEN}✓ Downloaded via wget${NC}"
elif curl -L --max-time 30 --retry 3 https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s -o /tmp/k3s 2>/dev/null; then
    echo -e "${GREEN}✓ Downloaded via curl${NC}"
else
    echo -e "${RED}✗ Failed to download K3s binary${NC}"
    echo "Checking network connectivity..."
    curl -I https://github.com --max-time 10 2>&1 | head -3 || echo "GitHub unreachable"
    exit 1
fi

chmod +x /tmp/k3s
sudo mv /tmp/k3s /usr/local/bin/k3s

echo -e "${GREEN}✓ Binary installed${NC}"
echo ""

# Step 4: Create systemd service
echo -e "${GREEN}[4/8] Creating systemd service...${NC}"
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

echo -e "${GREEN}✓ Service created and enabled${NC}"
echo ""

# Step 5: Start K3s service
echo -e "${GREEN}[5/8] Starting K3s service...${NC}"
sudo systemctl start k3s

echo -e "${GREEN}✓ Service started${NC}"
echo ""

# Step 6: Wait for K3s (QUAN TRỌNG: Đợi đủ thời gian - ít nhất 2-3 phút)
echo -e "${GREEN}[6/8] Waiting for K3s to initialize (this takes 2-5 minutes)...${NC}"
echo -e "${YELLOW}Please be patient - K3s needs time to start up...${NC}"

timeout=300  # 5 minutes
elapsed=0
check_interval=10  # Check every 10 seconds

while [ ! -f /etc/rancher/k3s/k3s.yaml ] && [ $elapsed -lt $timeout ]; do
    sleep $check_interval
    elapsed=$((elapsed + check_interval))
    
    # Show progress every 30 seconds
    if [ $((elapsed % 30)) -eq 0 ]; then
        echo "  Waiting... ($elapsed seconds)"
        
        # Check service status
        if sudo systemctl is-active k3s >/dev/null 2>&1; then
            echo "  ✓ Service is active"
        else
            echo "  ⚠ Service not active yet"
        fi
        
        # Check if process is running
        if pgrep -f k3s >/dev/null; then
            echo "  ✓ K3s process is running"
        fi
    fi
done

if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
    echo -e "${RED}✗ Config file not created after $timeout seconds${NC}"
    echo ""
    echo "Checking service status..."
    sudo systemctl status k3s --no-pager | head -40
    echo ""
    echo "Checking logs..."
    sudo journalctl -u k3s -n 100 --no-pager | tail -50
    echo ""
    echo "Checking process..."
    ps aux | grep k3s | head -5
    exit 1
fi

echo -e "${GREEN}✓ Config file created after $elapsed seconds${NC}"
echo ""

# Step 7: Verify installation
echo -e "${GREEN}[7/8] Verifying installation...${NC}"

# Wait additional 30 seconds for everything to stabilize
echo "  Waiting 30 seconds for K3s to fully stabilize..."
sleep 30

# Check service
if sudo systemctl is-active k3s >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Service is active${NC}"
else
    echo -e "${RED}  ✗ Service is not active${NC}"
    sudo systemctl status k3s --no-pager | head -20
fi

# Check port
if sudo netstat -tlnp 2>/dev/null | grep 6443 >/dev/null || sudo ss -tlnp 2>/dev/null | grep 6443 >/dev/null; then
    echo -e "${GREEN}  ✓ Port 6443 is listening${NC}"
    sudo netstat -tlnp 2>/dev/null | grep 6443 || sudo ss -tlnp 2>/dev/null | grep 6443
else
    echo -e "${RED}  ✗ Port 6443 is not listening${NC}"
fi

# Check config
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    echo -e "${GREEN}  ✓ Config file exists${NC}"
else
    echo -e "${RED}  ✗ Config file does not exist${NC}"
    exit 1
fi

echo ""

# Step 8: Setup kubeconfig
echo -e "${GREEN}[8/8] Setting up kubeconfig...${NC}"
mkdir -p /home/ec2-user/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube

# Update server URL
sed -i "s/127.0.0.1/$MASTER_IP/g" /home/ec2-user/.kube/config

echo -e "${GREEN}✓ Kubeconfig setup complete${NC}"
echo ""

# Final test
echo -e "${GREEN}=== Testing kubectl ===${NC}"
sleep 10  # Final wait

if /usr/local/bin/k3s kubectl get nodes 2>&1; then
    echo ""
    echo -e "${GREEN}=== SUCCESS! K3s is ready! ===${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Get kubeconfig: cat /home/ec2-user/.kube/config"
    echo "2. Update kubeconfig on local machine with IP: $MASTER_IP"
    echo "3. Test from local: kubectl get nodes"
else
    echo -e "${YELLOW}⚠ kubectl test had issues, but installation may still be in progress${NC}"
    echo "Check logs: sudo journalctl -u k3s -n 50"
fi

