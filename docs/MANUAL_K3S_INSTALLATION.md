# Hướng Dẫn Cài Đặt K3s Thủ Công

## Tổng Quan

Hướng dẫn này giúp bạn cài đặt K3s cluster thủ công trên EC2 instance, tránh các lỗi đã gặp khi tự động hóa.

## Thông Tin Cần Thiết

- **Master Instance ID**: `i-0fba6eeba0cd77a15`
- **Master Public IP**: `54.252.223.41` (hoặc lấy từ terraform output)
- **Region**: `ap-southeast-2`
- **OS**: Amazon Linux 2

## Các Lỗi Đã Gặp và Cách Tránh

### 1. AWS CLI v1 JSON Parsing Issues
**Lỗi**: "File association not found for extension .py", "Invalid JSON primitive"
**Giải pháp**: Dùng `--output text` thay vì `--output json`, hoặc check trực tiếp qua SSM session

### 2. Line Endings (CRLF vs LF)
**Lỗi**: "set: -\r: invalid option" trong bash script
**Giải pháp**: Dùng script bash trực tiếp trên server, không qua PowerShell string manipulation

### 3. K3s Download Failed
**Lỗi**: "[ERROR] Download failed" từ GitHub
**Giải pháp**: 
- Dùng version cụ thể thay vì "latest"
- Hoặc download binary trực tiếp
- Hoặc retry nhiều lần

### 4. Process Chạy Nhưng Port Không Listen
**Lỗi**: Process có nhưng port 6443 không listen, config không được tạo
**Giải pháp**: Check logs chi tiết, có thể K3s đang crash hoặc chưa khởi tạo xong

### 5. Service Không Start
**Lỗi**: systemd service inactive
**Giải pháp**: Check journalctl logs, có thể thiếu dependencies hoặc config sai

---

## Bước 1: Kết Nối Vào Server

### Cách 1: Qua AWS SSM Session Manager (Khuyến nghị)

```powershell
# Cài Session Manager Plugin nếu chưa có
# Download từ: https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPlugin.zip
# Cài file .msi trong zip

# Kết nối
aws ssm start-session --target i-0fba6eeba0cd77a15 --region ap-southeast-2
```

### Cách 2: Qua SSH (nếu có SSH key)

```bash
ssh -i your-key.pem ec2-user@54.252.223.41
```

---

## Bước 2: Chuẩn Bị Hệ Thống

Chạy các lệnh sau trên server:

```bash
# Update system
sudo yum update -y

# Install required packages
sudo yum install -y curl wget vim net-tools

# Disable swap (bắt buộc cho Kubernetes)
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
```

---

## Bước 3: Dọn Dẹp K3s Cũ (Nếu Có)

**QUAN TRỌNG**: Bước này rất quan trọng! Nếu có process cũ bị treo (zombie process), việc cài mới sẽ không thể bind vào port 6443.

```bash
# Stop và remove K3s cũ
# QUAN TRỌNG: pkill -9 để kill zombie processes
sudo pkill -9 k3s || true
sudo systemctl stop k3s 2>&1 || true
sudo systemctl disable k3s 2>&1 || true

# Đợi 3 giây để process thực sự dừng
sleep 3

# Clean data (CẨN THẬN: Xóa toàn bộ data cũ)
sudo rm -rf /var/lib/rancher/k3s
sudo rm -rf /etc/rancher/k3s
sudo rm -f /usr/local/bin/k3s
sudo rm -f /usr/local/bin/kubectl
sudo rm -f /usr/local/bin/crictl
sudo rm -f /usr/local/bin/ctr

# Tạo lại directories
sudo mkdir -p /etc/rancher/k3s
sudo mkdir -p /var/lib/rancher/k3s/server/db/etcd
```

---

## Bước 4: Cài Đặt K3s

### ⭐ Phương Pháp 2: Download Binary Trực Tiếp (KHUYẾN NGHỊ)

**Tại sao chọn phương pháp này?**
- Script cài đặt tự động (`curl ... | sh`) hay bị lỗi khi mạng chập chờn
- Download binary trực tiếp là cách "nồi đồng cối đá" nhất, ít lỗi nhất
- Không phụ thuộc vào script installer của Rancher có thể thay đổi

```bash
# Set variables
export MASTER_IP="54.252.223.41"
export K3S_VERSION="v1.28.5+k3s1"

# Download binary (thử wget trước, fallback sang curl)
cd /tmp
wget --timeout=30 --tries=3 https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s -O /tmp/k3s || \
curl -L --max-time 30 --retry 3 https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s -o /tmp/k3s

# Cấp quyền và di chuyển
chmod +x /tmp/k3s
sudo mv /tmp/k3s /usr/local/bin/k3s
```

### Phương Pháp 1: Dùng Official Installer (Backup nếu Method 2 fail)

```bash
# Set variables
export MASTER_IP="54.252.223.41"
export K3S_VERSION="v1.28.5+k3s1"

# Download binary
cd /tmp
wget https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s
chmod +x k3s
sudo mv k3s /usr/local/bin/

# Download install script
wget https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s-install.sh
chmod +x k3s-install.sh

# Create systemd service (sau khi download binary ở trên)
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

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable k3s
sudo systemctl start k3s
```

### Phương Pháp 1: Dùng Official Installer (Backup nếu Method 2 fail)

```bash
# Set variables
export MASTER_IP="54.252.223.41"

# Cài K3s với version cụ thể (tránh lỗi download)
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -s - server \
  --cluster-init \
  --tls-san $MASTER_IP \
  --node-ip $MASTER_IP \
  --bind-address 0.0.0.0 \
  --disable traefik \
  --write-kubeconfig-mode 644 \
  --data-dir /var/lib/rancher/k3s

# Nếu lỗi download, dùng phương pháp 2 (binary download)
```

### Phương Pháp 3: Manual Installation (Nếu 2 phương pháp trên fail)

```bash
# Set variables
export MASTER_IP="54.252.223.41"
export K3S_VERSION="v1.28.5+k3s1"

# Download và install binary
cd /tmp
wget https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s
chmod +x k3s
sudo mv k3s /usr/local/bin/k3s

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

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable k3s
sudo systemctl start k3s
```

---

## Bước 5: Kiểm Tra và Đợi K3s Khởi Động

```bash
# QUAN TRỌNG: Đợi đủ thời gian (2-5 phút)
# Race condition: Script automation thường check quá sớm
# K3s cần ít nhất 2-3 phút để khởi động hoàn toàn
echo "Waiting for K3s to start (this takes 2-5 minutes)..."
echo "Please be patient - K3s needs time to initialize..."

timeout=300  # 5 phút
elapsed=0
check_interval=10  # Check mỗi 10 giây

while [ ! -f /etc/rancher/k3s/k3s.yaml ] && [ $elapsed -lt $timeout ]; do
  sleep $check_interval
  elapsed=$((elapsed + check_interval))
  
  # Hiển thị progress mỗi 30 giây
  if [ $((elapsed % 30)) -eq 0 ]; then
    echo "Waiting... ($elapsed seconds)"
    
    # Check service status
    if sudo systemctl is-active k3s >/dev/null 2>&1; then
      echo "  ✓ Service is active"
    else
      echo "  ⚠ Service not active yet"
    fi
  fi
done

# Đợi thêm 30 giây để K3s ổn định hoàn toàn
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
  echo "Config created! Waiting 30 more seconds for K3s to stabilize..."
  sleep 30
fi

# Kiểm tra service
sudo systemctl status k3s

# Kiểm tra port
sudo netstat -tlnp | grep 6443 || sudo ss -tlnp | grep 6443

# Kiểm tra config file
ls -la /etc/rancher/k3s/k3s.yaml

# Kiểm tra logs nếu có lỗi
sudo journalctl -u k3s -n 50 --no-pager
```

---

## Bước 6: Setup Kubeconfig

```bash
# Set master IP
export MASTER_IP="54.252.223.41"

# Tạo .kube directory
mkdir -p /home/ec2-user/.kube

# Copy config
sudo cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube

# Update server URL trong config
sed -i "s/127.0.0.1/$MASTER_IP/g" /home/ec2-user/.kube/config

# Test kubectl
/usr/local/bin/k3s kubectl get nodes
```

---

## Bước 7: Lấy Kubeconfig Về Máy Local

### Cách 1: Qua SSM Command

```powershell
# Trên Windows PowerShell
aws ssm send-command `
  --instance-ids i-0fba6eeba0cd77a15 `
  --document-name "AWS-RunShellScript" `
  --parameters "commands=[cat /home/ec2-user/.kube/config]" `
  --region ap-southeast-2 `
  --output text

# Đợi vài giây, sau đó lấy output
aws ssm get-command-invocation `
  --command-id <COMMAND_ID> `
  --instance-id i-0fba6eeba0cd77a15 `
  --region ap-southeast-2 `
  --query "StandardOutputContent" `
  --output text > kubeconfig.yaml
```

### Cách 2: Copy từ SSM Session

```bash
# Trong SSM session, chạy:
cat /home/ec2-user/.kube/config

# Copy output và paste vào file C:\Users\<USER>\.kube\config trên Windows
# Nhớ thay 127.0.0.1 bằng public IP: 54.252.223.41
```

### Cách 3: Dùng Script Có Sẵn

```powershell
# Trên Windows
cd D:\github-renewable\eShelf
.\scripts\get-kubeconfig-simple.ps1 -Environment dev

# Sau đó update IP trong config
cd infrastructure\terraform\environments\dev
$masterIp = (terraform output -json k3s_master_public_ip | ConvertFrom-Json).Trim('"')
(Get-Content "$env:USERPROFILE\.kube\config") -replace 'https://[^:]+:6443', "https://${masterIp}:6443" | Set-Content "$env:USERPROFILE\.kube\config"
```

---

## Bước 8: Test Kết Nối

```powershell
# Trên Windows
kubectl get nodes
kubectl cluster-info
kubectl get pods --all-namespaces
```

Nếu thành công, bạn sẽ thấy:
```
NAME                    STATUS   ROLES                  AGE   VERSION
ip-172-31-34-105...     Ready    control-plane,master   5m    v1.28.5+k3s1
```

---

## Troubleshooting

### Lỗi: Service không start

```bash
# Check logs
sudo journalctl -u k3s -n 100 --no-pager

# Check process
ps aux | grep k3s

# Restart service
sudo systemctl restart k3s
sudo systemctl status k3s
```

### Lỗi: Port 6443 không listen

```bash
# Check port
sudo netstat -tlnp | grep 6443
sudo ss -tlnp | grep 6443

# Check firewall
sudo iptables -L -n | grep 6443
sudo firewall-cmd --list-all 2>&1

# Check security group trên AWS Console
# Đảm bảo port 6443 mở từ 0.0.0.0/0 hoặc IP của bạn
```

### Lỗi: Config file không được tạo

```bash
# Check K3s đang chạy chưa
sudo systemctl is-active k3s

# Check logs
sudo journalctl -u k3s -n 50 --no-pager

# Check data directory
ls -la /var/lib/rancher/k3s/server/

# Nếu có lỗi etcd, có thể cần clean và restart
sudo rm -rf /var/lib/rancher/k3s/server/db/etcd/*
sudo systemctl restart k3s
```

### Lỗi: Download failed từ GitHub

```bash
# Thử version khác
export K3S_VERSION="v1.27.8+k3s2"

# Hoặc download manual
cd /tmp
wget https://github.com/k3s-io/k3s/releases/download/v1.28.5+k3s1/k3s
chmod +x k3s
sudo mv k3s /usr/local/bin/
```

### Lỗi: "Unable to connect to the server"

```bash
# Check security group trên AWS
# Port 6443 phải mở từ Internet (0.0.0.0/0)

# Check K3s đang listen đúng IP chưa
sudo netstat -tlnp | grep 6443
# Phải thấy: 0.0.0.0:6443 hoặc 54.252.223.41:6443

# Check kubeconfig server URL
cat /home/ec2-user/.kube/config | grep server
# Phải là: https://54.252.223.41:6443 (không phải 127.0.0.1)
```

---

## Checklist Cuối Cùng

- [ ] K3s service đang chạy: `sudo systemctl is-active k3s`
- [ ] Port 6443 đang listen: `sudo netstat -tlnp | grep 6443`
- [ ] Config file tồn tại: `ls -la /etc/rancher/k3s/k3s.yaml`
- [ ] Kubeconfig đã được setup: `ls -la /home/ec2-user/.kube/config`
- [ ] Kubeconfig server URL đúng: `cat /home/ec2-user/.kube/config | grep server`
- [ ] Security group mở port 6443 từ Internet
- [ ] kubectl get nodes hoạt động từ local machine

---

## Lưu Ý Quan Trọng

1. **Luôn dùng version cụ thể** thay vì "latest" để tránh lỗi download
2. **Đợi đủ thời gian** (2-5 phút) để K3s khởi động hoàn toàn - Đây là nguyên nhân chính gây lỗi!
3. **pkill -9 k3s** trước khi cài mới để kill zombie processes
4. **Ưu tiên phương pháp 2** (Download Binary) thay vì installer script
5. **Check logs** nếu có lỗi: `sudo journalctl -u k3s -n 100`
6. **Đảm bảo security group** mở port 6443 từ Internet (Inbound) và port 443 (Outbound cho GitHub)
7. **Update kubeconfig** với đúng public IP, không dùng 127.0.0.1
8. **Line endings**: Nếu copy script từ Windows, đảm bảo dùng LF (không phải CRLF)

---

## Sau Khi Cài Đặt Thành Công

1. Deploy ArgoCD
2. Deploy Monitoring stack (Prometheus, Grafana)
3. Deploy Harbor registry

Xem file `NEXT_STEPS.md` để tiếp tục các bước tiếp theo.

