# Hướng Dẫn Setup Không Cần AWS Account

## 📋 Tổng Quan

Tài liệu này liệt kê các bước có thể test **KHÔNG CẦN AWS account** và cách setup môi trường local để test.

---

## CÁC BƯỚC CÓ THỂ CHẠY KHÔNG CẦN AWS

### 1. 4.9 Demo PR-only Pipeline
**Không cần AWS** - Chỉ cần GitHub repo

**Các bước:**
```powershell
# 1. Tạo feature branch
git checkout -b feature/test-pr-pipeline

# 2. Thay đổi code (ví dụ thêm comment)
# Edit any file

# 3. Push và tạo PR
git add .
git commit -m "test: Test PR pipeline"
git push origin feature/test-pr-pipeline

# 4. Tạo PR trên GitHub
# Vào GitHub → Create Pull Request
```

**Kết quả:** GitHub Actions sẽ chạy PR pipeline (test, lint, scan) mà không deploy

---

### 2. 4.10 Demo Terraform 3 Environments (Plan Only)
**Không cần AWS** - Chỉ validate và plan, không apply

**Các bước:**
```powershell
# 1. Check environments
Get-ChildItem -Path "infrastructure/terraform/environments" -Directory

# 2. Plan dev environment (không cần AWS credentials)
cd infrastructure/terraform/environments/dev
terraform init -backend=false
terraform validate
terraform plan -var="public_key=dummy" -var="create_k3s_cluster=false" -input=false

# 3. Plan staging environment
cd ../staging
terraform init -backend=false
terraform validate
terraform plan -var-file=terraform.tfvars.example -input=false

# 4. Plan prod environment
cd ../prod
terraform init -backend=false
terraform validate
terraform plan -var-file=terraform.tfvars.example -input=false
```

**Lưu ý:** 
- Sử dụng `-backend=false` để không cần S3 backend
- Sử dụng dummy variables để validate code
- **KHÔNG chạy `terraform apply`** vì sẽ tạo resources trên AWS

**Kết quả:** Validate Terraform code và xem plan output

---

### 3. 4.3-4.8: Deploy lên Local Kubernetes Cluster
**Không cần AWS** - Sử dụng local K8s cluster

**Các options:**
- **k3d** (Khuyên dùng - nhẹ, nhanh)
- **minikube** (Phổ biến)
- **kind** (Kubernetes in Docker)
- **Docker Desktop** (Built-in K8s)

---

## 🚀 SETUP LOCAL KUBERNETES CLUSTER

### Option 1: k3d (Khuyên dùng - Nhẹ nhất)

**Cài đặt:**
```powershell
# Download k3d từ https://k3d.io/
# Hoặc dùng Chocolatey
choco install k3d

# Hoặc dùng winget
winget install k3d
```

**Tạo cluster:**
```powershell
# Tạo cluster với 1 master và 2 workers (giống AWS setup)
k3d cluster create eshelf-cluster --servers 1 --agents 2 --port "8080:80@loadbalancer" --port "8443:443@loadbalancer"

# Verify
kubectl get nodes
```

**Kết quả:** Local K8s cluster sẵn sàng

---

### Option 2: minikube

**Cài đặt:**
```powershell
# Download từ https://minikube.sigs.k8s.io/docs/start/
# Hoặc dùng Chocolatey
choco install minikube
```

**Tạo cluster:**
```powershell
# Start minikube
minikube start --nodes 3

# Verify
kubectl get nodes
```

---

### Option 3: Docker Desktop (Nếu đã có)

**Enable Kubernetes:**
1. Mở Docker Desktop
2. Settings → Kubernetes
3. Enable Kubernetes
4. Apply & Restart

**Verify:**
```powershell
kubectl get nodes
```

---

## 📝 CÁC BƯỚC CÓ THỂ TEST VỚI LOCAL CLUSTER

### ✅ 4.3 Deploy Applications lên K8s (Local)

**Các bước:**
```powershell
# 1. Deploy Staging
kubectl apply -k infrastructure/kubernetes/overlays/staging
kubectl get pods -n eshelf-staging

# 2. Deploy Production
kubectl apply -k infrastructure/kubernetes/overlays/prod
kubectl get pods -n eshelf-prod
```

**Lưu ý:** 
- Cần build images local hoặc dùng public images
- Có thể cần sửa image pull policies

---

### ✅ 4.4 Setup Monitoring (Local)

**Các bước:**
```powershell
# 1. Deploy Monitoring Stack
kubectl apply -k infrastructure/kubernetes/monitoring
kubectl get pods -n monitoring

# 2. Port Forward
kubectl port-forward svc/prometheus -n monitoring 9090:9090
kubectl port-forward svc/grafana -n monitoring 3000:3000

# 3. Truy cập
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin123)
```

---

### ✅ 4.5 Setup ArgoCD (Local)

**Các bước:**
```powershell
# 1. Cài đặt ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Đợi sẵn sàng
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 3. Lấy password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# 4. Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 5. Truy cập: https://localhost:8080 (admin/<password>)
```

---

### ✅ 4.6 Setup Harbor (Local)

**Các bước:**
```powershell
# 1. Cài đặt Helm (nếu chưa có)
# Download từ https://helm.sh/docs/intro/install/

# 2. Add Harbor repo
helm repo add harbor https://helm.goharbor.io
helm repo update

# 3. Cài đặt Harbor
kubectl create namespace harbor
cd infrastructure/kubernetes/harbor
helm install harbor harbor/harbor -f harbor-values.yaml -n harbor

# 4. Đợi sẵn sàng
kubectl wait --for=condition=available --timeout=600s deployment/harbor-core -n harbor

# 5. Port forward
kubectl port-forward svc/harbor-core -n harbor 8080:80

# 6. Truy cập: http://localhost:8080 (admin/Harbor12345)
```

**Lưu ý:** 
- Harbor cần storage, có thể dùng local-path-provisioner
- Có thể cần tăng resources cho local cluster

---

### ✅ 4.7 Setup Jenkins (Local)

**Các bước:**
```powershell
# 1. Deploy Jenkins
kubectl apply -f infrastructure/kubernetes/jenkins/namespace.yaml
kubectl apply -f infrastructure/kubernetes/jenkins/deployment.yaml
kubectl apply -f infrastructure/kubernetes/jenkins/service.yaml

# 2. Đợi sẵn sàng
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins

# 3. Get initial password
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword

# 4. Port forward
kubectl port-forward svc/jenkins -n jenkins 8080:8080

# 5. Truy cập: http://localhost:8080
```

---

### ✅ 4.8 Setup SonarQube (Local)

**Các bước:**
```powershell
# 1. Deploy SonarQube
kubectl apply -f infrastructure/kubernetes/sonarqube/namespace.yaml
kubectl apply -f infrastructure/kubernetes/sonarqube/deployment.yaml
kubectl apply -f infrastructure/kubernetes/sonarqube/service.yaml

# 2. Đợi sẵn sàng
kubectl wait --for=condition=available --timeout=600s deployment/sonarqube -n sonarqube

# 3. Port forward
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000

# 4. Truy cập: http://localhost:9000 (admin/admin)
```

---

### ✅ 4.11 Demo ArgoCD Image Updater (Local)

**Các bước:**
```powershell
# 1. Check ArgoCD applications
kubectl get applications -n argocd

# 2. Check annotations
kubectl get application api-gateway -n argocd -o yaml | Select-String "argocd-image-updater"

# 3. Verify Image Updater config
kubectl get configmap argocd-image-updater-config -n argocd -o yaml
```

---

## ❌ CÁC BƯỚC CẦN AWS (KHÔNG THỂ TEST KHÔNG CÓ AWS)

### ❌ 4.1 Setup AWS Infrastructure (Terraform)
- **Cần:** AWS account, AWS CLI, Terraform
- **Không thể test:** Cần tạo resources thực trên AWS

### ❌ 4.2 Setup K3s Cluster với Ansible
- **Cần:** EC2 instances từ Terraform
- **Không thể test:** Cần servers thực

---

## 📊 BẢNG TÓM TẮT

| Bước | Cần AWS? | Có thể test local? | Ghi chú |
|------|----------|-------------------|---------|
| 4.1 AWS Infrastructure | ✅ Cần | ❌ Không | Cần AWS account |
| 4.2 K3s với Ansible | ✅ Cần | ❌ Không | Cần EC2 instances |
| 4.3 Deploy Apps | ❌ Không | ✅ Có (với local K8s) | Dùng k3d/minikube |
| 4.4 Monitoring | ❌ Không | ✅ Có (với local K8s) | Dùng k3d/minikube |
| 4.5 ArgoCD | ❌ Không | ✅ Có (với local K8s) | Dùng k3d/minikube |
| 4.6 Harbor | ❌ Không | ✅ Có (với local K8s) | Dùng k3d/minikube |
| 4.7 Jenkins | ❌ Không | ✅ Có (với local K8s) | Dùng k3d/minikube |
| 4.8 SonarQube | ❌ Không | ✅ Có (với local K8s) | Dùng k3d/minikube |
| 4.9 PR Pipeline | ❌ Không | ✅ Có | Chỉ cần GitHub |
| 4.10 Terraform Plan | ❌ Không | ✅ Có | Plan only, không apply |
| 4.11 ArgoCD Image Updater | ❌ Không | ✅ Có (với local K8s) | Dùng k3d/minikube |

---

## 🎯 KHUYẾN NGHỊ THỨ TỰ TEST

### Phase 1: Không cần AWS (Có thể test ngay)
1. ✅ **4.9 PR Pipeline** - Test GitHub Actions
2. ✅ **4.10 Terraform Plan** - Validate Terraform code
3. ✅ **Setup local K8s cluster** (k3d/minikube)

### Phase 2: Với Local K8s Cluster
4. ✅ **4.4 Monitoring** - Dễ nhất
5. ✅ **4.8 SonarQube** - Đơn giản
6. ✅ **4.5 ArgoCD** - Quan trọng cho GitOps
7. ✅ **4.3 Deploy Apps** - Test application deployment
8. ✅ **4.6 Harbor** - Cần storage, phức tạp hơn
9. ✅ **4.7 Jenkins** - Cần storage, phức tạp hơn
10. ✅ **4.11 ArgoCD Image Updater** - Cần ArgoCD trước

### Phase 3: Cần AWS (Khi có account)
11. ❌ **4.1 AWS Infrastructure** - Setup AWS resources
12. ❌ **4.2 K3s với Ansible** - Setup cluster trên AWS

---

## 💡 TIPS

1. **Bắt đầu với k3d** - Nhẹ nhất, nhanh nhất
2. **Test từng bước một** - Đừng deploy tất cả cùng lúc
3. **Dùng port-forward** - Dễ hơn ingress cho local
4. **Check resources** - Local cluster có giới hạn resources
5. **Backup configs** - Trước khi test, backup các file config

---

## 🔧 TROUBLESHOOTING

### Local cluster không đủ resources
```powershell
# Tăng resources cho k3d
k3d cluster create eshelf-cluster --servers 1 --agents 2 --k3s-arg '--kubelet-arg=eviction-hard=memory.available<100Mi'
```

### Images không pull được
```powershell
# Sửa image pull policy
kubectl patch deployment <deployment-name> -n <namespace> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","imagePullPolicy":"IfNotPresent"}]}}}}'
```

### Storage issues
```powershell
# Cài local-path-provisioner cho k3d
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
```

---

## 📚 TÀI LIỆU THAM KHẢO

- [k3d Documentation](https://k3d.io/)
- [minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)

