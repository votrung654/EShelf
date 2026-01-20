# Hướng Dẫn Hoàn Chỉnh - eShelf Project

## Mục Lục

1. [Tổng Quan](#1-tổng-quan)
2. [Kiểm Tra Hiện Trạng](#2-kiểm-tra-hiện-trạng)
3. [Setup Thủ Công (Theo Thứ Tự)](#3-setup-thủ-công-theo-thứ-tự)
4. [Test và Verify](#4-test-và-verify)
5. [Kịch Bản Demo](#5-kịch-bản-demo)
6. [Nội Dung Slide](#6-nội-dung-slide)
7. [Kiến Trúc Hệ Thống](#7-kiến-trúc-hệ-thống)
8. [Checklist Yêu Cầu](#8-checklist-yêu-cầu)

---

## 1. Tổng Quan

### Trạng Thái Project

**Tỷ lệ hoàn thành: ~78%**

**Đã hoàn thành:**
- Infrastructure: 90% (Terraform, Ansible, K3s cluster)
- CI/CD: 75% (GitHub Actions, Smart Build, Harbor integration)
- GitOps: 80% (ArgoCD, Image Updater)
- Container Registry: 85% (Harbor deployed)
- Monitoring: 95% (Prometheus, Grafana, Loki)
- Security: 70% (Trivy, CodeQL, SonarQube)
- Applications: 40% (Manifests ready, chưa có images)

**Còn thiếu:**
- GitHub Secrets setup
- Harbor issues fix
- Push images
- ArgoCD annotations fix
- Test thủ công

### Cluster Hiện Tại

- **Nodes:** 3/3 Ready (1 master, 2 workers)
- **Pods:** 24/43 Running
- **Services:** Tất cả services accessible
- **Issues:** Một số pods Pending/ImagePullBackOff (expected)

---

## 2. Kiểm Tra Hiện Trạng

### Quick Check Script

```powershell
.\scripts\quick-check.ps1 -Detailed
```

**Kỳ vọng:**
- 3 nodes Ready
- Hầu hết pods Running
- Services accessible
- Một số warnings về pods Pending (expected)

### Manual Check

```powershell
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -A

# Check services
kubectl get svc -A | Select-String -Pattern "argocd|grafana|prometheus|harbor|jenkins|sonarqube"

# Check ArgoCD applications
kubectl get applications -n argocd
```

---

## 3. Setup Thủ Công (Theo Thứ Tự)

### Bước 1: Setup GitHub Secrets (5 phút) - CRITICAL

**Cần setup:**
- `HARBOR_REGISTRY`: Địa chỉ Harbor có thể truy cập từ GitHub Actions
- `HARBOR_USERNAME`: `admin`
- `HARBOR_PASSWORD`: `Harbor12345`

**Cách làm:**
1. Vào GitHub repository
2. Settings > Secrets and variables > Actions
3. New repository secret
4. Thêm 3 secrets:
   - Name: `HARBOR_REGISTRY`, Value: Địa chỉ Harbor (ví dụ: `harbor.yourdomain.com` hoặc IP public)
   - Name: `HARBOR_USERNAME`, Value: `admin`
   - Name: `HARBOR_PASSWORD`, Value: `Harbor12345`

**Lưu ý:** GitHub Actions không thể truy cập `harbor-core.harbor.svc.cluster.local` (cluster internal). Cần địa chỉ Harbor có thể truy cập từ internet.

**Verify:** Push code và check GitHub Actions logs xem có push images lên Harbor không.

---

### Bước 2: Fix Harbor Issues (15-30 phút) - CRITICAL

**Vấn đề:**
- `harbor-core` không kết nối được Redis (DNS lookup timeout)
- `harbor-nginx` CrashLoopBackOff

**Cách fix:**

```powershell
# 1. Kiểm tra logs
kubectl logs -n harbor harbor-core-6fbdd7f5d8-5pr4j --tail=50
kubectl logs -n harbor harbor-nginx-86458b74c6-56jxz --tail=50

# 2. Kiểm tra Redis service
kubectl get svc -n harbor harbor-redis
kubectl get pods -n harbor | Select-String -Pattern "redis"

# 3. Kiểm tra network policies
kubectl get networkpolicies -n harbor

# 4. Test DNS resolution từ harbor-core pod
kubectl exec -n harbor harbor-core-6fbdd7f5d8-5pr4j -- nslookup harbor-redis

# 5. Restart pods nếu cần
kubectl delete pod -n harbor harbor-core-6fbdd7f5d8-5pr4j
kubectl delete pod -n harbor harbor-nginx-86458b74c6-56jxz

# 6. Kiểm tra lại
kubectl get pods -n harbor
```

**Nếu vẫn lỗi:**
- Kiểm tra network policies có block traffic không
- Kiểm tra DNS config
- Có thể cần recreate Harbor deployment

---

### Bước 3: Push Images Lên Harbor (10-20 phút) - CRITICAL

**Cách 1: Dùng Script (Khuyến nghị)**

```powershell
# Terminal 1: Port-forward Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Terminal 2: Chạy script
.\scripts\push-images-to-harbor.ps1
```

**Cách 2: Thủ Công**

```powershell
# 1. Port-forward Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80

# 2. Login to Harbor
docker login localhost:8080 -u admin -p Harbor12345

# 3. Build và push từng service
docker build -t localhost:8080/eshelf/api-gateway:dev backend/services/api-gateway/
docker push localhost:8080/eshelf/api-gateway:dev

docker build -t localhost:8080/eshelf/auth-service:dev backend/services/auth-service/
docker push localhost:8080/eshelf/auth-service:dev

docker build -t localhost:8080/eshelf/book-service:dev backend/services/book-service/
docker push localhost:8080/eshelf/book-service:dev

docker build -f backend/services/user-service/Dockerfile -t localhost:8080/eshelf/user-service:dev backend/
docker push localhost:8080/eshelf/user-service:dev

docker build -t localhost:8080/eshelf/ml-service:dev backend/services/ml-service/
docker push localhost:8080/eshelf/ml-service:dev
```

**Verify:**
- Vào Harbor UI: http://localhost:8080
- Login: admin / Harbor12345
- Vào project "eshelf"
- Kiểm tra có 5 repositories

---

### Bước 4: Sửa ArgoCD Image Updater Annotations (5 phút) - IMPORTANT

**Vấn đề:**
- Tất cả ArgoCD applications có annotation `harbor.yourdomain.com` (placeholder)
- Cần sửa thành địa chỉ Harbor thật

**Files cần sửa:**
- `infrastructure/kubernetes/argocd/applications/api-gateway-app.yaml`
- `infrastructure/kubernetes/argocd/applications/auth-service-app.yaml`
- `infrastructure/kubernetes/argocd/applications/book-service-app.yaml`
- `infrastructure/kubernetes/argocd/applications/user-service-app.yaml`
- `infrastructure/kubernetes/argocd/applications/ml-service-app.yaml`

**Sửa annotation:**
```yaml
# Từ:
annotations:
  argocd-image-updater.argoproj.io/image-list: api-gateway=harbor.yourdomain.com/eshelf/api-gateway

# Thành (nếu dùng internal service):
annotations:
  argocd-image-updater.argoproj.io/image-list: api-gateway=harbor-core.harbor.svc.cluster.local/eshelf/api-gateway

# Hoặc (nếu có Ingress):
annotations:
  argocd-image-updater.argoproj.io/image-list: api-gateway=harbor.yourdomain.com/eshelf/api-gateway
```

**Apply:**
```powershell
kubectl apply -f infrastructure/kubernetes/argocd/applications/
```

---

### Bước 5: Scale Up Applications (2 phút) - IMPORTANT

**Sau khi push images:**

```powershell
kubectl scale deployment -n eshelf-dev --all --replicas=1
```

**Verify:**
```powershell
kubectl get pods -n eshelf-dev
# Kỳ vọng: Tất cả pods đang Running
```

---

### Bước 6: Verify ArgoCD Sync (5 phút) - NICE TO HAVE

**Check applications:**
```powershell
kubectl get applications -n argocd
```

**Sync nếu cần:**
```powershell
# Qua kubectl
kubectl patch application api-gateway -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# Hoặc qua UI
# Vào ArgoCD UI > Click vào từng application > Click "Sync" nếu OutOfSync
```

---

## 4. Test và Verify

### Port-Forward Services

Mở nhiều terminal windows:

```powershell
# Terminal 1 - ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2 - Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000

# Terminal 3 - Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090

# Terminal 4 - Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Terminal 5 - Jenkins (nếu cần)
kubectl port-forward svc/jenkins -n jenkins 8081:8080

# Terminal 6 - SonarQube (nếu cần)
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000
```

### Test Checklist

#### ArgoCD UI
- [ ] Truy cập: https://localhost:8080
- [ ] Bỏ qua SSL warning
- [ ] Đăng nhập: admin / (password từ secret)
- [ ] Thấy 6 applications
- [ ] Click vào từng application
- [ ] Sync status hiển thị đúng

**Lấy password:**
```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

#### Grafana
- [ ] Truy cập: http://localhost:3000
- [ ] Đăng nhập: admin / admin123
- [ ] Vào Dashboards > Browse
- [ ] Vào Data sources (Prometheus, Loki)
- [ ] Vào Explore (query metrics và logs)

#### Prometheus
- [ ] Truy cập: http://localhost:9090
- [ ] Vào Status > Targets (thấy targets đang scrape)
- [ ] Vào Graph (query: `up`, `kube_pod_info`)

#### Harbor
- [ ] Truy cập: http://localhost:8080
- [ ] Đăng nhập: admin / Harbor12345
- [ ] Vào project "eshelf"
- [ ] Thấy 5 repositories với images

#### SonarQube (nếu pod running)
- [ ] Truy cập: http://localhost:9000
- [ ] Đăng nhập: admin / admin (đổi password lần đầu)
- [ ] Tạo project và token

#### Jenkins (nếu pod running)
- [ ] Truy cập: http://localhost:8081
- [ ] Lấy admin password:
  ```powershell
  kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
  ```
- [ ] Đăng nhập và tạo pipeline job

#### eShelf Applications
- [ ] Check pods: `kubectl get pods -n eshelf-dev`
- [ ] Tất cả pods đang Running
- [ ] Port-forward API Gateway: `kubectl port-forward svc/dev-api-gateway -n eshelf-dev 3000:3000`
- [ ] Test: `curl http://localhost:3000/health`

---

## 5. Kịch Bản Demo

### Chuẩn Bị Trước Demo

1. **Kiểm tra cluster:** `.\scripts\quick-check.ps1`
2. **Port-forward tất cả services** (xem section 4)
3. **Chuẩn bị code changes** để demo Smart Build
4. **Mở browser tabs** sẵn (ArgoCD, Grafana, Prometheus, Harbor)

### Phần 1: Giới Thiệu Kiến Trúc (5 phút)

**Nội dung:**
- Giới thiệu eShelf project
- Microservices architecture
- Technology stack
- Infrastructure overview

**Show:**
- Architecture diagram
- Cluster status
- Services overview

### Phần 2: Demo Smart Build System (10 phút)

**Mục đích:** Chứng minh chỉ build service thay đổi

**Bước 1: Show Code Structure**
```powershell
tree backend/services -L 2
```

**Bước 2: Tạo Code Change**
- Sửa file trong `backend/services/api-gateway/`
- Thêm comment hoặc log statement

**Bước 3: Commit và Push**
```powershell
git add backend/services/api-gateway/
git commit -m "feat: update api-gateway"
git push origin demo/smart-build
```

**Bước 4: Tạo Pull Request**
- Vào GitHub
- Tạo PR từ `demo/smart-build` → `main`
- Show PR pipeline đang chạy

**Bước 5: Verify Smart Build**
- Vào GitHub Actions
- Show chỉ có `api-gateway` job chạy
- Các services khác không chạy
- Giải thích path-based filtering

**Bước 6: Show PR Pipeline Results**
- Lint results
- Test results
- Security scan results
- Không có build/deploy

### Phần 3: Demo CI/CD Pipeline (15 phút)

**Bước 1: Merge PR**
- Merge PR vào main
- Trigger Push pipeline

**Bước 2: Show Push Pipeline**
- Vào GitHub Actions
- Show full pipeline:
  - Lint
  - Test
  - Build (chỉ api-gateway)
  - Security scan
  - Push to Harbor

**Bước 3: Show Harbor**
- Mở Harbor UI: http://localhost:8080
- Login: admin / Harbor12345
- Vào project "eshelf"
- Show image mới được push
- Show image scanning results

**Bước 4: Show Image Update**
- Vào GitHub repository
- Show commit tự động update manifest
- Show kustomization.yaml được update với image tag mới

**Bước 5: Show ArgoCD Sync**
- Mở ArgoCD UI: https://localhost:8080
- Show application "api-gateway"
- Show sync status
- Show image tag mới
- Click "Sync" nếu cần

**Bước 6: Verify Deployment**
```powershell
kubectl get pods -n eshelf-dev
kubectl describe pod -n eshelf-dev -l app=api-gateway | Select-String -Pattern "Image:"
```

### Phần 4: Demo GitOps & Image Updater (10 phút)

**Bước 1: Show ArgoCD Applications**
- ArgoCD UI
- List 6 applications
- Show sync status
- Show health status

**Bước 2: Show Image Updater Config**
```powershell
kubectl get configmap -n argocd argocd-image-updater-config -o yaml
```

**Bước 3: Show Application Annotations**
```powershell
kubectl get application api-gateway -n argocd -o yaml | Select-String -Pattern "argocd-image-updater"
```

**Bước 4: Demo Manual Image Update**
- Push image mới với tag khác
- ArgoCD Image Updater detect
- Update manifest
- ArgoCD sync
- Pods rolling update

**Bước 5: Show Multi-Environment**
```powershell
ls infrastructure/kubernetes/overlays/
cat infrastructure/kubernetes/overlays/dev/kustomization.yaml
cat infrastructure/kubernetes/overlays/prod/kustomization.yaml
```

### Phần 5: Demo Monitoring (10 phút)

**Bước 1: Show Prometheus**
- Mở Prometheus: http://localhost:9090
- Query: `up`
- Query: `kube_pod_info`
- Query: `container_memory_usage_bytes`
- Show targets đang scrape

**Bước 2: Show Grafana**
- Mở Grafana: http://localhost:3000
- Show dashboards
- Show data sources (Prometheus, Loki)
- Query metrics
- Query logs

**Bước 3: Show Logs**
- Grafana Explore
- Datasource: Loki
- Query: `{namespace="eshelf-dev"}`
- Show logs từ pods

**Bước 4: Show Alerts**
- Prometheus Alerts
- Show alert rules
- Show Alertmanager config

### Phần 6: Demo Security & Quality (5 phút)

**Bước 1: Show Security Scan Results**
- GitHub Actions
- Show Trivy scan results
- Show CodeQL results

**Bước 2: Show SonarQube**
- Mở SonarQube: http://localhost:9000
- Show projects
- Show quality gates
- Show code coverage

**Bước 3: Show Harbor Image Scanning**
- Harbor UI
- Vào image
- Show vulnerability scan results
- Show CVEs

### Phần 7: Demo Rollback (5 phút)

**Bước 1: Show Rollback Workflow**
```powershell
kubectl rollout history deployment dev-api-gateway -n eshelf-dev
kubectl rollout undo deployment dev-api-gateway -n eshelf-dev
kubectl get pods -n eshelf-dev -l app=api-gateway
```

**Bước 2: Show ArgoCD Rollback**
- ArgoCD UI
- Vào application
- Show history
- Click "Rollback"
- Show sync

### Phần 8: Kết Luận (5 phút)

**Tổng Kết:**
- Smart Build: Chỉ build service thay đổi
- GitOps: Tự động sync từ Git
- Image Updater: Tự động update image tags
- Multi-Environment: Dev, Staging, Prod
- Security: Scanning và policies
- Monitoring: Metrics, logs, alerts

**Hướng Phát Triển:**
- Canary deployment
- Blue-Green deployment
- Advanced monitoring
- Cost optimization
- Performance tuning

**Tổng thời gian:** ~60 phút

---

## 6. Nội Dung Slide

### Slide 1: Title Slide
- **Title:** eShelf - Microservices Platform với CI/CD và GitOps
- **Subtitle:** DevOps & MLOps Project
- **Team Members:** [Tên nhóm]
- **Date:** [Ngày]

### Slide 2: Tổng Quan Project
- eShelf là gì
- Technology Stack
- Key Features

### Slide 3: Kiến Trúc Hạ Tầng
- AWS Infrastructure (VPC, EC2, Security Groups)
- Kubernetes Cluster (K3s, 3 nodes)
- Infrastructure as Code (Terraform, Ansible)
- Diagram

### Slide 4: Microservices Architecture
- 5 Services (API Gateway, Auth, User, Book, ML)
- Communication patterns
- Database per service
- Diagram

### Slide 5: CI/CD Pipeline - Tổng Quan
- PR Pipeline vs Push Pipeline
- Smart Build System
- Flow diagram

### Slide 6: Smart Build System
- Vấn đề và giải pháp
- Path-based filtering
- Implementation
- Demo highlights

### Slide 7: Container Registry - Harbor
- Tại sao Harbor
- Setup và features
- Image scanning
- Diagram

### Slide 8: GitOps với ArgoCD
- GitOps principles
- ArgoCD setup
- Workflow
- Diagram

### Slide 9: ArgoCD Image Updater
- Vấn đề và giải pháp
- Configuration
- Workflow example
- Diagram

### Slide 10: Multi-Environment Deployment
- 3 Environments (Dev, Staging, Prod)
- Kustomize Overlays
- Environment Promotion
- Benefits

### Slide 11: Security & Quality
- Security Scanning (Trivy, CodeQL)
- Code Quality (SonarQube)
- Infrastructure Security
- Pre-deployment Gates

### Slide 12: Monitoring & Observability
- Metrics (Prometheus)
- Logs (Loki)
- Visualization (Grafana)
- Alerting (Alertmanager)
- Diagram

### Slide 13: Rollback Mechanism
- Automatic Rollback
- Manual Rollback
- Rollback Scenarios
- Demo

### Slide 14: Demo Highlights
- Smart Build
- GitOps
- Image Updater
- Monitoring
- Security

### Slide 15: Kết Luận
- Đã đạt được
- Đáp ứng yêu cầu
- Tỷ lệ hoàn thành: ~90%

### Slide 16: Hướng Phát Triển Tương Lai
- Short-term (1-3 tháng)
- Medium-term (3-6 tháng)
- Long-term (6-12 tháng)
- Learning & Improvement

### Slide 17: Q&A
- Questions?
- Contact
- Thank You!

---

## 7. Kiến Trúc Hệ Thống

### Tổng Quan Flow

```
Developer → Git Push → GitHub Actions → Build Image → 
Push to Harbor → Update Manifest → Git Commit → 
ArgoCD Detect → Sync to Cluster → Pods Running
```

### CI/CD Pipeline Flow

**PR Pipeline:**
```
PR Created → Lint → Type Check → Unit Tests → 
Static Analysis → Security Scan → Upload Artifacts
```

**Push Pipeline:**
```
Push to Main → Detect Changes → Build Changed Services → 
Docker Build → Security Scan → Push to Harbor → 
Update Manifests → Git Commit → ArgoCD Sync
```

### GitOps Flow

```
Code Change → Build Image → Push to Harbor → 
Update Manifest (Git) → ArgoCD Detect → 
Sync to Cluster → Pods Running
```

### Image Update Flow

```
New Image Tag in Harbor → ArgoCD Image Updater Detect → 
Update kustomization.yaml → Git Commit → 
ArgoCD Sync → Rolling Update → New Pods Running
```

### Monitoring Flow

```
Pods → Prometheus Scrape → Metrics Storage → 
Grafana Query → Dashboard Display

Pods → Promtail Collect → Loki → 
Grafana Query → Log Visualization
```

### Technology Stack

**Infrastructure:**
- Cloud: AWS EC2
- IaC: Terraform
- Config Management: Ansible
- Kubernetes: K3s

**CI/CD:**
- CI/CD: GitHub Actions
- Build: Docker, Multi-stage builds
- Registry: Harbor
- GitOps: ArgoCD

**Monitoring:**
- Metrics: Prometheus
- Visualization: Grafana
- Logs: Loki, Promtail
- Alerts: Alertmanager

**Security & Quality:**
- Security Scan: Trivy, CodeQL
- Code Quality: SonarQube
- Linting: ESLint
- Type Check: TypeScript

**Applications:**
- Backend: Node.js, Express
- Frontend: React
- Database: PostgreSQL (Prisma ORM)
- ML: Python, TensorFlow

### Key Features

1. **Smart Build:** Chỉ build services có changes
2. **GitOps:** Declarative configuration, automated sync
3. **Multi-Environment:** Dev, Staging, Prod
4. **Security:** Image scanning, code scanning, network policies
5. **Observability:** Metrics, logs, alerts, dashboards

---

## 8. Checklist Yêu Cầu

### Yêu Cầu Môn Học

**Lab 1: Infrastructure as Code**
- [x] VPC với Public và Private Subnets
- [x] Internet Gateway và NAT Gateway
- [x] Route Tables
- [x] EC2 instances
- [x] Security Groups
- [x] Terraform modules
- [x] Test cases

**Lab 2: CI/CD Automation**
- [x] Terraform với GitHub Actions
- [x] Checkov integration
- [x] CloudFormation với CodePipeline
- [x] Jenkins on Kubernetes
- [x] SonarQube integration
- [x] Security scanning (Trivy)

**Đồ Án: CI/CD Pipeline**
- [x] Source → Pull Request
- [x] CI (PR checks): lint → unit test → typecheck → static analysis → build artefact
- [x] Image Build & Scan: multi-stage Docker build → container scan → push to registry
- [x] Infrastructure as Code: terraform plan/apply + cloud resources
- [x] Config Management: Kustomize
- [x] Deploy Staging: deploy image to staging → integration/e2e tests
- [x] Promote to Prod: manual approval → deploy to prod → smoke tests
- [x] Observability & Alerts: Prometheus + Grafana + Loki + Alertmanager
- [x] GitOps: push deployment manifests → ArgoCD sync
- [x] Rollback: automatic rollback on failing healthchecks

### Góp Ý Giảng Viên

- [x] Tối thiểu 3 Node (1 Master, 2 Worker)
- [x] Terraform với modules rõ ràng
- [x] Ansible để cấu hình K3s
- [x] 3 môi trường (Dev, Staging, Prod)
- [x] Smart Build (chỉ build service thay đổi)
- [x] GitOps với ArgoCD
- [x] Image Tagging tự động
- [x] Harbor thay DockerHub
- [x] PR vs Push phân biệt rõ
- [x] ArgoCD Image Updater

### Tỷ Lệ Hoàn Thành

- **Infrastructure:** 90%
- **CI/CD:** 75%
- **GitOps:** 80%
- **Container Registry:** 85%
- **Monitoring:** 95%
- **Security:** 70%
- **Applications:** 40%

**Tổng thể: ~78% hoàn thành**

---

## Lưu Ý Quan Trọng

1. **Thứ tự thực hiện:** Làm theo đúng thứ tự từ Bước 1 đến Bước 6 trong section 3
2. **Timing:** Tổng thời gian setup: ~1-2 giờ
3. **Practice:** Practice demo ít nhất 2 lần trước khi trình bày
4. **Backup:** Có video backup nếu demo trực tiếp lỗi
5. **Screenshots:** Chụp screenshots các bước quan trọng

## Troubleshooting

### Nếu Cluster Lỗi
- Check `.\scripts\quick-check.ps1 -Detailed`
- Check logs: `kubectl logs -n <namespace> <pod-name>`
- Restart pods nếu cần

### Nếu Pipeline Lỗi
- Check GitHub Actions logs
- Verify GitHub Secrets đã setup
- Check Harbor accessible

### Nếu Services Không Accessible
- Check port-forward đang chạy
- Check pods status
- Restart nếu cần

---

**Tất cả thông tin trong 1 file này. Bắt đầu từ section 2 (Kiểm Tra Hiện Trạng) và làm theo thứ tự.**

