# Các Bước Tiếp Theo Sau Khi Đăng Nhập AWS Console

Bạn đã đăng nhập AWS Console thành công! Bây giờ làm theo các bước sau:

## Bước 1: Cài Đặt Công Cụ Cần Thiết

### 1.1. AWS CLI (Bắt buộc)

**Cách 1: Dùng winget (Khuyến nghị)**
```powershell
winget install Amazon.AWSCLI
```

**Cách 2: Download từ website**
- Truy cập: https://aws.amazon.com/cli/
- Download và cài đặt AWS CLI v2

**Cách 3: Dùng CloudShell (Không cần cài)**
- Trong AWS Console, click icon **CloudShell** (terminal icon ở top bar)
- CloudShell đã có AWS CLI sẵn, không cần cài đặt

**Kiểm tra sau khi cài:**
```powershell
aws --version
```

### 1.2. Terraform (Bắt buộc)

**Cách 1: Dùng Chocolatey**
```powershell
choco install terraform
```

**Cách 2: Download từ website**
- Truy cập: https://www.terraform.io/downloads
- Download và giải nén vào PATH

**Kiểm tra sau khi cài:**
```powershell
terraform version
```

### 1.3. kubectl (Đã có)

Bạn đã có kubectl v1.32.2, không cần cài thêm!

## Bước 2: Configure AWS CLI

Sau khi cài AWS CLI, bạn cần configure credentials. Có 2 cách:

### Cách 1: Dùng CloudShell (Dễ nhất - Không cần configure)

1. Trong AWS Console, click icon **CloudShell** (terminal icon)
2. CloudShell đã có credentials sẵn
3. Có thể chạy AWS CLI commands ngay

### Cách 2: Configure AWS CLI trên máy local

**Lấy Access Key từ AWS Console:**

1. Trong AWS Console, vào **IAM** service
2. Click **Users** → chọn user của bạn (hoặc tạo user mới nếu cần)
3. Tab **Security credentials**
4. Scroll xuống **Access keys** → **Create access key**
5. Chọn use case: **Command Line Interface (CLI)**
6. Copy **Access Key ID** và **Secret Access Key** (chỉ hiển thị 1 lần!)

**Configure AWS CLI:**
```powershell
aws configure
```

Nhập:
- **AWS Access Key ID:** [Paste từ bước trên]
- **AWS Secret Access Key:** [Paste từ bước trên]
- **Default region name:** `us-east-1` (hoặc region bạn muốn)
- **Default output format:** `json`

**Test kết nối:**
```powershell
aws sts get-caller-identity
```

Nếu thành công, sẽ hiển thị Account ID và User ARN.

### Lưu ý: Nếu Bạn Đổi Tài Khoản AWS Mới

Nếu bạn đổi từ tài khoản lab sang tài khoản Free Tier mới:

1. **Chạy script setup:**
   ```powershell
   .\scripts\setup-new-aws-account.ps1
   ```
   Script này sẽ:
   - Hướng dẫn configure AWS CLI
   - Kiểm tra kết nối
   - Kiểm tra infrastructure cũ (nếu có)
   - Hướng dẫn cleanup và bắt đầu lại

2. **Nếu có infrastructure cũ từ account trước:**
   - Có thể bị terminate tự động khi account cũ hết hạn
   - Nếu vẫn còn, nên destroy và tạo lại:
     ```powershell
     cd infrastructure\terraform\environments\dev
     terraform destroy  # Nếu state file vẫn còn
     ```

3. **Bắt đầu lại từ Bước 3:**
   - Chạy `terraform init` và `terraform apply` để tạo infrastructure mới
   - Sau đó tiếp tục với Bước 4 và 5

## Bước 3: Setup Terraform Infrastructure

### 3.1. Kiểm Tra Terraform Configuration

```powershell
cd infrastructure/terraform/environments/dev

# Validate Terraform files
terraform init -backend=false
terraform validate
terraform fmt -check
```

### 3.2. Tạo Terraform Variables File

```powershell
# Copy file example
Copy-Item terraform.tfvars.example terraform.tfvars

# Mở và chỉnh sửa nếu cần
notepad terraform.tfvars
```

**Lưu ý:** File `terraform.tfvars` đã có trong `.gitignore`, không được commit lên Git.

### 3.3. Terraform Init và Plan

```powershell
# Initialize Terraform
terraform init

# Xem trước những gì sẽ được tạo (KHÔNG tạo thật)
terraform plan
```

Kiểm tra output:
- VPC sẽ được tạo
- Subnets (public/private)
- Security Groups
- EC2 instances cho K3s cluster
- Internet Gateway, NAT Gateway

### 3.4. Terraform Apply (Tạo Infrastructure)

**Lưu ý:** Bước này sẽ tạo resources trên AWS và có thể tốn phí!

```powershell
terraform apply
```

Terraform sẽ hiển thị plan và hỏi xác nhận. Nhập `yes` để tiếp tục.

**Thời gian:** Quá trình này có thể mất 5-10 phút để tạo tất cả resources.

### 3.5. Kiểm Tra Terraform Output

Sau khi apply thành công:

```powershell
terraform output
```

Bạn sẽ thấy:
- `k3s_master_instance_id`: ID của master node
- `k3s_worker_instance_ids`: IDs của worker nodes
- `bastion_instance_id`: ID của bastion host
- `vpc_id`: ID của VPC
- `public_subnet_ids`: IDs của public subnets
- `private_subnet_ids`: IDs của private subnets

## Bước 4: Deploy Kubernetes Cluster (K3s)

### 4.1. Setup Ansible Inventory

Terraform output sẽ được dùng để tạo Ansible inventory. Script tự động sẽ làm điều này, hoặc bạn có thể làm thủ công:

```powershell
cd infrastructure/ansible

# Tạo inventory từ Terraform output
# (Script tự động sẽ làm điều này)
```

### 4.2. Deploy K3s với Ansible

```powershell
# Từ thư mục ansible
ansible-playbook -i inventory/hosts.ini playbooks/k3s-cluster.yml
```

Playbook này sẽ:
- Install K3s trên master node
- Join worker nodes vào cluster
- Setup kubeconfig
- Verify cluster health

### 4.3. Verify Cluster

```powershell
# Export kubeconfig (script sẽ tự động làm)
# Hoặc copy kubeconfig từ master node

kubectl get nodes
```

Kết quả mong đợi:
```
NAME              STATUS   ROLES                  AGE   VERSION
ip-xxx-xxx-xxx    Ready    control-plane,master   5m    v1.28.x+k3s1
ip-xxx-xxx-xxx    Ready    <none>                 4m    v1.28.x+k3s1
ip-xxx-xxx-xxx    Ready    <none>                 4m    v1.28.x+k3s1
```

## Bước 5: Deploy Applications

### 5.1. Deploy ArgoCD

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f infrastructure/kubernetes/argocd/
```

Chờ ArgoCD pods ready:
```powershell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 5.2. Truy Cập ArgoCD UI

**Lấy ArgoCD admin password:**
```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

**Port-forward ArgoCD:**
```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Truy cập browser:**
- URL: `https://localhost:8080`
- Username: `admin`
- Password: [Password từ command trên]

### 5.3. Deploy Monitoring Stack

```powershell
kubectl apply -f infrastructure/kubernetes/monitoring/
```

### 5.4. Deploy Harbor Registry

```powershell
kubectl apply -f infrastructure/kubernetes/harbor/
```

## Bước 6: Test và Verify

### Test Infrastructure

```powershell
# Test AWS connection
.\scripts\test-aws-connection.ps1

# Test Terraform
cd infrastructure/terraform/environments/dev
terraform validate
terraform plan
```

### Test Applications

```powershell
# Check pods
kubectl get pods -A

# Check services
kubectl get svc -A

# Check ArgoCD applications
kubectl get applications -n argocd
```

## Checklist Tổng Hợp

### Prerequisites
- [x] AWS CLI đã cài đặt
- [x] Terraform đã cài đặt
- [x] kubectl đã có
- [x] AWS credentials đã configure
- [x] Helm đã cài đặt

### Infrastructure
- [x] Terraform init thành công
- [x] Terraform plan không có lỗi
- [x] Terraform apply thành công
- [x] EC2 instances đang chạy
- [x] VPC và subnets đã được tạo

### Kubernetes
- [x] K3s cluster đã deploy
- [x] Tất cả nodes status: Ready
- [x] kubeconfig đã được setup

### Applications
- [x] ArgoCD đã deploy
- [x] ArgoCD UI accessible
- [x] Monitoring stack đã deploy (Prometheus, Grafana, Alertmanager running; Loki pending do thiếu memory)
- [x] Harbor đã deploy

## Troubleshooting

### Lỗi: "AWS CLI not found"
- Cài đặt AWS CLI: `winget install Amazon.AWSCLI`
- Hoặc dùng CloudShell trong AWS Console

### Lỗi: "Terraform not found"
- Cài đặt Terraform: `choco install terraform`
- Hoặc download từ: https://www.terraform.io/downloads

### Lỗi: "Credentials not configured"
- Lấy Access Key từ IAM Console
- Configure: `aws configure`
- Test: `aws sts get-caller-identity`

### Lỗi: "Terraform plan fails"
- Kiểm tra AWS credentials
- Kiểm tra IAM permissions
- Kiểm tra region có đúng không

### Lỗi: "Cannot connect to cluster"
- Kiểm tra kubeconfig đã được setup chưa
- Kiểm tra network connectivity
- Kiểm tra security groups

## Tài Liệu Tham Khảo

- **DEMO_GUIDE.md** - Hướng dẫn demo chi tiết
- **docs/BROWSER_TESTING_GUIDE.md** - Test qua browser
- **QUICK_START_AWS.md** - Quick start guide

## Lưu Ý Quan Trọng

**Lưu ý về chi phí:** Tạo EC2 instances và các resources sẽ tốn phí. Nhớ shutdown khi không dùng:
```powershell
.\scripts\aws-shutdown.sh dev
```

**Cleanup:** Khi xong, destroy resources:
```powershell
cd infrastructure/terraform/environments/dev
terraform destroy
```

