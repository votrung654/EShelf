# Hướng Dẫn Cài Đặt eShelf

## Mục lục

1. [Yêu cầu trước khi cài đặt](#yêu-cầu-trước-khi-cài-đặt)
2. [Thiết lập môi trường phát triển cục bộ](#thiết-lập-môi-trường-phát-triển-cục-bộ)
3. [Thiết lập hạ tầng](#thiết-lập-hạ-tầng)
4. [Triển khai Kubernetes](#triển-khai-kubernetes)
5. [Thiết lập CI/CD](#thiết-lập-cicd)
6. [Thiết lập Monitoring](#thiết-lập-monitoring)

## Yêu cầu trước khi cài đặt

### Công cụ cần thiết

- Docker & Docker Compose
- Node.js 20+
- Python 3.11+
- kubectl
- Helm 3.x
- Terraform 1.5+ (cho hạ tầng)
- Ansible (cho thiết lập K3s)
- AWS CLI (cho CloudFormation)

### Tài khoản cần thiết

- GitHub (cho CI/CD)
- Tài khoản AWS (cho hạ tầng cloud)
- Docker Hub hoặc Harbor (cho container registry)

## Thiết lập môi trường phát triển cục bộ

### 1. Clone repository

```bash
git clone https://github.com/votrung654/EShelf.git
cd eShelf
```

### 2. Cài đặt dependencies

```bash
# Frontend
npm install

# Các service backend
cd backend/services/api-gateway && npm install
cd ../auth-service && npm install
cd ../book-service && npm install
cd ../user-service && npm install

# ML Service
cd ../ml-service && pip install -r requirements.txt
```

### 3. Thiết lập database

```bash
cd backend/database
npm install
npx prisma migrate dev
npx prisma generate
npx prisma db seed
```

### 4. Khởi động các service

```bash
# Khởi động tất cả service bằng Docker Compose
cd backend
docker-compose up -d

# Hoặc khởi động từng service riêng lẻ
npm run backend:start
```

### 5. Khởi động Frontend

```bash
npm run dev
```

Truy cập: http://localhost:5173

## Thiết lập hạ tầng

### Cách 1: Terraform (Khuyến nghị)

#### 1. Cấu hình AWS Credentials

```bash
aws configure
```

#### 2. Khởi tạo Terraform

```bash
cd infrastructure/terraform/environments/dev
terraform init
```

#### 3. Tạo file terraform.tfvars

```hcl
aws_region = "ap-southeast-1"
create_k3s_cluster = true
k3s_master_instance_type = "t3.medium"
k3s_worker_instance_type = "t3.small"
k3s_worker_count = 2
public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
```

#### 4. Plan và Apply

```bash
terraform plan
terraform apply
```

#### 5. Lấy outputs

```bash
terraform output
```

### Cách 2: CloudFormation

```bash
cd infrastructure/cloudformation/templates
aws cloudformation create-stack \
  --stack-name eshelf-vpc \
  --template-body file://vpc-stack.yaml \
  --region ap-southeast-1
```

## Triển khai Kubernetes

### 1. Thiết lập K3s Cluster với Ansible

#### Cập nhật Inventory

Cập nhật `infrastructure/ansible/inventory/dev.ini`:
```ini
[master]
k3s-master ansible_host=<MASTER_IP> ansible_user=ec2-user

[workers]
k3s-worker-1 ansible_host=<WORKER1_IP> ansible_user=ec2-user
k3s-worker-2 ansible_host=<WORKER2_IP> ansible_user=ec2-user
```

#### Chạy Playbook

```bash
cd infrastructure/ansible
ansible-playbook -i inventory/dev.ini playbooks/setup-cluster.yml
ansible-playbook -i inventory/dev.ini playbooks/setup-tools.yml
```

#### Lấy kubeconfig

```bash
scp ec2-user@<MASTER_IP>:~/.kube/config ~/.kube/config
kubectl get nodes
```

### 2. Triển khai ứng dụng

#### Dùng Kustomize

```bash
# Staging
kubectl apply -k infrastructure/kubernetes/overlays/staging

# Production
kubectl apply -k infrastructure/kubernetes/overlays/prod
```

#### Dùng ArgoCD

```bash
# Cài đặt ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply các ứng dụng
kubectl apply -f infrastructure/kubernetes/argocd/applications/
```

## Thiết lập CI/CD

### GitHub Actions

Đã cấu hình sẵn trong `.github/workflows/`:
- `ci.yml`: CI cho Frontend/Backend
- `smart-build.yml`: Smart build (chỉ build service thay đổi)
- `terraform.yml`: Hạ tầng IaC
- `mlops-model-training.yml`: Huấn luyện mô hình ML
- `mlops-model-deployment.yml`: Triển khai mô hình ML
- `deploy-rollback.yml`: Triển khai với rollback

### AWS CodePipeline

```bash
cd infrastructure/cloudformation/pipeline
aws cloudformation create-stack \
  --stack-name eshelf-codepipeline \
  --template-body file://codepipeline-stack.yaml \
  --parameters \
    ParameterKey=GitHubOwner,ParameterValue=votrung654 \
    ParameterKey=GitHubRepo,ParameterValue=EShelf \
    ParameterKey=GitHubToken,ParameterValue=ghp_xxx \
  --capabilities CAPABILITY_NAMED_IAM
```

## Thiết lập Monitoring

### 1. Triển khai Monitoring Stack

```bash
kubectl apply -k infrastructure/kubernetes/monitoring
```

### 2. Truy cập Dashboard

```bash
# Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090
# Truy cập: http://localhost:9090

# Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000
# Truy cập: http://localhost:3000
# Mặc định: admin/admin123

# Loki (qua Grafana)
# Đã cấu hình sẵn trong Grafana datasources
```

### 3. Cấu hình cảnh báo

Cập nhật `infrastructure/kubernetes/monitoring/prometheus/alerts.yaml` và apply:
```bash
kubectl apply -f infrastructure/kubernetes/monitoring/prometheus/alerts.yaml
```

## Thiết lập Harbor

### 1. Cài đặt Harbor

```bash
helm repo add harbor https://helm.goharbor.io
helm install harbor harbor/harbor -f infrastructure/kubernetes/harbor/harbor-values.yaml -n harbor
```

### 2. Truy cập Harbor

```bash
kubectl port-forward svc/harbor-core -n harbor 8080:80
# Truy cập: http://localhost:8080
# Mặc định: admin/Harbor12345
```

### 3. Tạo Project

1. Đăng nhập Harbor UI
2. Tạo project: `eshelf`
3. Cập nhật CI/CD để sử dụng Harbor registry

## Xử lý sự cố

### Service không khởi động

```bash
# Xem log
docker-compose logs
kubectl logs -n eshelf-prod deployment/api-gateway

# Kiểm tra trạng thái
kubectl get pods -n eshelf-prod
kubectl describe pod <pod-name> -n eshelf-prod
```

### Lỗi kết nối database

```bash
# Kiểm tra database
docker-compose ps
docker-compose logs postgres

# Test kết nối
kubectl exec -it <postgres-pod> -n eshelf-prod -- psql -U postgres -d eshelf
```

### Lỗi mạng

```bash
# Kiểm tra service
kubectl get svc -n eshelf-prod

# Test kết nối
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Trong pod: wget -O- http://api-gateway:3000/health
```

