# Hướng Dẫn Các Bước Thủ Công

Tài liệu này bổ sung hướng dẫn thủ công cho các script tự động trong project.

## Setup Infrastructure với Terraform

### Script Tự Động
```powershell
.\scripts\setup-infrastructure.ps1 -Environment dev
```

### Hướng Dẫn Thủ Công

#### Bước 1: Kiểm tra Prerequisites
```powershell
# Kiểm tra Terraform
terraform version

# Kiểm tra AWS CLI
aws --version

# Kiểm tra AWS credentials
aws sts get-caller-identity
```

#### Bước 2: Cấu hình Terraform
```powershell
cd infrastructure/terraform/environments/dev

# Tạo file terraform.tfvars từ example
Copy-Item terraform.tfvars.example terraform.tfvars

# Chỉnh sửa terraform.tfvars nếu cần
notepad terraform.tfvars
```

#### Bước 3: Terraform Init
```powershell
terraform init
```

#### Bước 4: Terraform Plan
```powershell
terraform plan -out=tfplan
```

Kiểm tra output để đảm bảo:
- VPC sẽ được tạo
- Subnets (public/private) sẽ được tạo
- Security Groups sẽ được tạo
- EC2 instances cho K3s cluster sẽ được tạo
- Internet Gateway, NAT Gateway sẽ được tạo

#### Bước 5: Terraform Apply
```powershell
terraform apply tfplan
```

Nhập `yes` khi được hỏi xác nhận. Quá trình này có thể mất 5-10 phút.

#### Bước 6: Lấy Terraform Outputs
```powershell
terraform output
```

Lưu lại các giá trị quan trọng:
- `k3s_master_instance_id`
- `k3s_worker_instance_ids`
- `bastion_instance_id`
- `vpc_id`

## Deploy K3s Cluster

### Script Tự Động
```powershell
.\scripts\deploy-k3s-simple.ps1 -Environment dev
```

### Hướng Dẫn Thủ Công

#### Bước 1: Cập nhật Ansible Inventory
```powershell
cd infrastructure/ansible

# Mở file inventory
notepad inventory/dev.ini
```

Cập nhật với thông tin từ Terraform output:
```ini
[master]
k3s-master ansible_host=<MASTER_IP> ansible_user=ec2-user

[workers]
k3s-worker-1 ansible_host=<WORKER1_IP> ansible_user=ec2-user
k3s-worker-2 ansible_host=<WORKER2_IP> ansible_user=ec2-user
```

#### Bước 2: Deploy K3s với Ansible
```powershell
ansible-playbook -i inventory/dev.ini playbooks/k3s-cluster.yml
```

Playbook sẽ:
- Install K3s trên master node
- Join worker nodes vào cluster
- Setup kubeconfig
- Verify cluster health

#### Bước 3: Lấy kubeconfig
```powershell
# Từ master node
scp ec2-user@<MASTER_IP>:~/.kube/config ~/.kube/config

# Hoặc dùng AWS SSM
aws ssm start-session --target <MASTER_INSTANCE_ID> --region <REGION>
# Trong session:
cat ~/.kube/config
```

#### Bước 4: Verify Cluster
```powershell
kubectl get nodes
```

Kết quả mong đợi:
```
NAME              STATUS   ROLES                  AGE   VERSION
ip-xxx-xxx-xxx    Ready    control-plane,master   5m    v1.28.x+k3s1
ip-xxx-xxx-xxx    Ready    <none>                 4m    v1.28.x+k3s1
ip-xxx-xxx-xxx    Ready    <none>                 4m    v1.28.x+k3s1
```

## Push Images lên Harbor

### Script Tự Động
```powershell
.\scripts\push-images-to-harbor.ps1
```

### Hướng Dẫn Thủ Công

#### Bước 1: Port-forward Harbor
```powershell
kubectl port-forward svc/harbor-core -n harbor 8080:80
```

Giữ terminal này chạy, mở terminal mới cho các bước tiếp theo.

#### Bước 2: Login vào Harbor
```powershell
docker login localhost:8080 -u admin -p Harbor12345
```

#### Bước 3: Build và Push từng Service

**API Gateway:**
```powershell
docker build -t localhost:8080/eshelf/api-gateway:dev backend/services/api-gateway/
docker push localhost:8080/eshelf/api-gateway:dev
```

**Auth Service:**
```powershell
docker build -t localhost:8080/eshelf/auth-service:dev backend/services/auth-service/
docker push localhost:8080/eshelf/auth-service:dev
```

**Book Service:**
```powershell
docker build -t localhost:8080/eshelf/book-service:dev backend/services/book-service/
docker push localhost:8080/eshelf/book-service:dev
```

**User Service:**
```powershell
docker build -f backend/services/user-service/Dockerfile -t localhost:8080/eshelf/user-service:dev backend/
docker push localhost:8080/eshelf/user-service:dev
```

**ML Service:**
```powershell
docker build -t localhost:8080/eshelf/ml-service:dev backend/services/ml-service/
docker push localhost:8080/eshelf/ml-service:dev
```

#### Bước 4: Verify Images trong Harbor
1. Truy cập http://localhost:8080
2. Đăng nhập với admin/Harbor12345
3. Vào project "eshelf"
4. Kiểm tra repositories có images

#### Bước 5: Scale Up Deployments
```powershell
kubectl scale deployment -n eshelf-dev --all --replicas=1
```

## Deploy Applications

### Script Tự Động
```powershell
.\scripts\deploy-applications.ps1
```

### Hướng Dẫn Thủ Công

#### Bước 1: Deploy ArgoCD
```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f infrastructure/kubernetes/argocd/
```

#### Bước 2: Đợi ArgoCD Ready
```powershell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

#### Bước 3: Lấy ArgoCD Admin Password
```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

#### Bước 4: Port-forward ArgoCD
```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### Bước 5: Truy cập ArgoCD UI
- URL: https://localhost:8080
- Username: admin
- Password: (từ bước 3)

#### Bước 6: Deploy Monitoring Stack
```powershell
kubectl apply -f infrastructure/kubernetes/monitoring/
```

#### Bước 7: Deploy Harbor Registry
```powershell
kubectl apply -f infrastructure/kubernetes/harbor/
```

## Setup AWS Credentials

### Script Tự Động
```powershell
.\scripts\setup-aws-credentials.ps1
```

### Hướng Dẫn Thủ Công

#### Cách 1: AWS SSO (Khuyến nghị cho AWS Academy)
```powershell
aws configure sso --profile aws-academy
```

Khi được hỏi:
- SSO start URL: `https://<ACCOUNT_ID>.signin.aws.amazon.com/console`
- SSO region: `us-east-1`
- SSO registration scopes: `sso:account:access`
- CLI default client Region: `us-east-1`
- CLI default output format: `json`

Login:
```powershell
aws sso login --profile aws-academy
```

Sử dụng:
```powershell
$env:AWS_PROFILE = "aws-academy"
aws s3 ls
```

#### Cách 2: Access Keys (Truyền thống)
```powershell
aws configure
```

Nhập:
- AWS Access Key ID: (từ IAM Console)
- AWS Secret Access Key: (từ IAM Console)
- Default region name: `us-east-1`
- Default output format: `json`

#### Cách 3: CloudShell (Không cần configure)
1. Trong AWS Console, click icon CloudShell
2. CloudShell đã có credentials sẵn
3. Chạy AWS CLI commands trực tiếp

## Test AWS Connection

### Script Tự Động
```powershell
.\scripts\test-aws-connection.ps1
```

### Hướng Dẫn Thủ Công

```powershell
# Test AWS CLI installation
aws --version

# Test credentials
aws sts get-caller-identity

# Test EC2 access
aws ec2 describe-instances --region us-east-1 --max-items 1

# Test VPC access
aws ec2 describe-vpcs --region us-east-1 --max-items 1
```

## Troubleshooting

### Lỗi: Script không chạy được
- Kiểm tra PowerShell execution policy: `Get-ExecutionPolicy`
- Nếu Restricted, chạy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Lỗi: AWS CLI không tìm thấy
- Kiểm tra PATH: `$env:Path`
- Thêm AWS CLI vào PATH nếu cần

### Lỗi: Terraform không tìm thấy
- Kiểm tra Terraform đã cài: `terraform version`
- Thêm Terraform vào PATH nếu cần

### Lỗi: kubectl không kết nối được cluster
- Kiểm tra kubeconfig: `kubectl config view`
- Kiểm tra cluster connectivity: `kubectl cluster-info`

