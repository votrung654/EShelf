# NT548.Q11 - CÔNG NGHỆ DEVOPS VÀ ỨNG DỤNG

# DEPLOY AN EBOOK PLATFORM ON KUBERNETES USING GITHUB ACTIONS AND ARGOCD

THỰC HIỆN BỞI NHÓM 15
22521571 - Võ Đình Trung
22521587 - Trương Phúc Trường
23521809 - Lê Văn Vũ

GVHD: ThS. Lê Anh Tuấn

---

# Overview

- Giới thiệu đề tài 01
- Kiến trúc hệ thống 02
- Triển khai hệ thống 03
- Demo 04
- Tổng kết 05

---

# 1. Giới thiệu đề tài

## Giới thiệu

**eShelf** là nền tảng đọc sách điện tử được xây dựng theo kiến trúc **microservices**, áp dụng các mô hình DevOps hiện đại như container hóa, Kubernetes và CI/CD.

Đề tài hướng tới việc mô phỏng quy trình triển khai và vận hành hệ thống phần mềm trên môi trường cloud với các công nghệ:

- **Infrastructure as Code**: Terraform, Ansible
- **Container Orchestration**: Kubernetes (K3s)
- **CI/CD**: GitHub Actions, Jenkins
- **GitOps**: ArgoCD với Image Updater
- **Container Registry**: Harbor
- **Monitoring**: Prometheus, Grafana, Loki
- **Security**: Trivy, CodeQL, SonarQube

## Mục tiêu

Hệ thống nhằm triển khai tự động các microservices trên Kubernetes bằng Infrastructure as Code và GitOps.

**Phạm vi đồ án:**
- ✅ Kiến trúc triển khai (Infrastructure as Code)
- ✅ CI/CD Pipeline với Smart Build System
- ✅ GitOps với ArgoCD và Image Updater
- ✅ Bảo mật (Security scanning, Code quality)
- ✅ Monitoring và Observability
- ✅ Khả năng rollback
- ✅ Nghiệp vụ được xây dựng ở mức phục vụ cho demo và đánh giá kỹ thuật

**Trạng thái hoàn thành: ~78-90%**

---

# 2. KIẾN TRÚC HỆ THỐNG

---

# 2.1. Các công nghệ sử dụng

## Infrastructure

- **HashiCorp Terraform**: Infrastructure as Code cho AWS (VPC, EC2, Security Groups)
- **AWS CloudFormation**: VPC, EC2, CodePipeline stacks
- **Ansible**: Cấu hình và triển khai K3s cluster
- **AWS EC2**: Cloud infrastructure (3 nodes cho K3s cluster)

## Container Management

- **Docker**: Container hóa các microservices
- **K3s**: Lightweight Kubernetes distribution
- **Kustomize**: Configuration management cho multi-environment

## Registry

- **Harbor**: Self-hosted container registry với image scanning

## CI/CD

- **GitHub Actions**: CI/CD pipelines với Smart Build System
- **Jenkins**: Pipeline trên Kubernetes với SonarQube integration
- **AWS CodePipeline**: Automated deployment pipeline

---

# 2.1. Các công nghệ sử dụng (tiếp)

## GitOps

- **ArgoCD**: GitOps continuous delivery tool
- **ArgoCD Image Updater**: Tự động update image tags từ registry

## Monitoring & Logging

- **Prometheus**: Metrics collection và storage
- **Grafana**: Visualization và dashboards
- **Grafana Loki**: Log aggregation
- **Promtail**: Log collection agent
- **Alertmanager**: Alert routing và notification

## Security

- **Trivy**: Container image vulnerability scanning
- **CodeQL**: Code security analysis
- **SonarQube**: Code quality analysis
- **Checkov**: Infrastructure as Code security scanning

---

# 2.2. Kiến trúc hệ thống

## Infrastructure Architecture

**AWS Infrastructure:**
- VPC với Public và Private Subnets
- Internet Gateway và NAT Gateway
- Security Groups cho network isolation
- EC2 instances: 3 nodes (1 master + 2 workers)

**K3s Cluster:**
- Master node: Control plane
- Worker nodes: Application pods
- Network: Flannel CNI
- Storage: Local path provisioner

**Infrastructure as Code:**
- Terraform modules: VPC, EC2, Security Groups, IAM
- Ansible playbooks: K3s deployment và configuration
- 3 environments: Dev, Staging, Prod (Kustomize overlays)

## Microservices Architecture

**5 Microservices:**
1. **API Gateway**: Entry point, routing, load balancing
2. **Auth Service**: Authentication, authorization, JWT tokens
3. **User Service**: User management, profiles, collections
4. **Book Service**: Book catalog, search, genres
5. **ML Service**: Machine learning features, recommendations

**Communication:**
- RESTful APIs
- Service-to-service communication
- Database per service pattern (PostgreSQL với Prisma ORM)

---

# 3. TRIỂN KHAI HỆ THỐNG

---

# 3.1. Infrastructure as Code

## Terraform

**Modules:**
- ✅ VPC module: Public và Private subnets
- ✅ EC2 module: 3 instances cho K3s cluster
- ✅ Security Groups: Network isolation
- ✅ IAM roles và policies

**Environments:**
- Dev environment: Fully configured và deployed
- Staging/Prod: Configs ready (Kustomize overlays)

**Status:** ✅ 90% hoàn thành

## Ansible

**Playbooks:**
- ✅ K3s master node installation
- ✅ K3s worker nodes join
- ✅ Cluster configuration
- ✅ Network policies setup

**Status:** ✅ Deployed và tested

---

# 3.2. CI/CD Pipeline

## GitHub Actions Workflows

**1. Smart Build System (`smart-build.yml`):**
- ✅ Path-based filtering: Chỉ build services có thay đổi
- ✅ Parallel builds cho multiple services
- ✅ Code change detection (ignores comments/whitespace)

**2. CI Pipeline (`ci.yml`):**
- ✅ Frontend CI: Lint, type check, build
- ✅ Backend CI: Lint, type check, unit tests (matrix strategy)
- ✅ Docker build: Multi-stage builds cho 5 services

**3. PR-only Pipeline (`pr-only.yml`):**
- ✅ Validation only: Lint, test, security scan
- ✅ Không deploy (chỉ check quality)

**4. Security Scanning:**
- ✅ Trivy: Container image scanning
- ✅ CodeQL: Code security analysis
- ✅ SonarQube: Code quality analysis

**5. Terraform Pipeline (`terraform.yml`):**
- ✅ Checkov: IaC security scanning
- ✅ Terraform plan/validate

**6. MLOps Workflows:**
- ✅ Model training pipeline
- ✅ Model deployment với canary strategy

**Status:** ✅ 75% hoàn thành (cần setup GitHub Secrets để push images)

---

# 3.3. Container Registry - Harbor

## Deployment

**Status:** ✅ Deployed trên Kubernetes
- 8/8 pods deployed
- Services: harbor-core, harbor-nginx, harbor-redis, harbor-database, etc.

**Configuration:**
- Project: `eshelf`
- Image naming: `harbor-core.harbor.svc.cluster.local/eshelf/<service>:<tag>`
- ImagePullSecrets: Created và configured

**Features:**
- ✅ Image vulnerability scanning (Trivy integration)
- ✅ Access control và authentication
- ✅ Project-based organization

**Issues cần fix:**
- ⚠️ Harbor Redis connection (cần troubleshoot)
- ⚠️ Harbor nginx CrashLoopBackOff (cần fix)

**Status:** ✅ 85% hoàn thành

---

# 3.4. GitOps với ArgoCD

## ArgoCD Deployment

**Status:** ✅ Fully deployed
- 7/7 pods Running
- ArgoCD Server, Application Controller, Repo Server, etc.

**Applications:**
- ✅ 6 ArgoCD Applications configured:
  1. api-gateway
  2. auth-service
  3. book-service
  4. user-service
  5. ml-service
  6. monitoring

**Configuration:**
- ✅ Automated sync policy
- ✅ Self-heal enabled
- ✅ Multi-environment support (dev, staging, prod)
- ✅ Kustomize overlays

**Status:** ✅ 80% hoàn thành

---

# 3.5. ArgoCD Image Updater

## Configuration

**Setup:**
- ✅ ArgoCD Image Updater ConfigMap
- ✅ Image Updater annotations trong applications
- ✅ Write-back method: Git
- ✅ Update strategy: Semver, latest, digest

**Workflow:**
```
New Image in Harbor → Image Updater Detect → 
Update kustomization.yaml → Git Commit → 
ArgoCD Sync → Rolling Update
```

**Status:** ✅ 80% hoàn thành (cần sửa annotations từ placeholder sang địa chỉ Harbor thật)

---

# 3.6. Multi-Environment Deployment

## Kustomize Overlays

**Structure:**
```
infrastructure/kubernetes/
├── base/
│   └── deployments/ (5 services)
└── overlays/
    ├── dev/ (replicas: 1, image: ...:dev)
    ├── staging/ (replicas: 2, image: ...:staging)
    └── prod/ (replicas: 3, image: ...:prod)
```

**Environments:**
- ✅ Dev: Fully configured
- ✅ Staging: Configs ready
- ✅ Prod: Configs ready

**Environment Promotion:**
- Dev → Staging: Automated (có thể)
- Staging → Prod: Manual approval

**Status:** ✅ 90% hoàn thành

---

# 3.7. Monitoring & Observability

## Monitoring Stack

**Prometheus:**
- ✅ Deployed và running
- ✅ Scraping metrics từ pods và nodes
- ✅ Alert rules configured

**Grafana:**
- ✅ Deployed và running
- ✅ Dashboards configured
- ✅ Data sources: Prometheus, Loki

**Loki:**
- ✅ Deployed và running
- ✅ Log aggregation từ tất cả pods

**Promtail:**
- ✅ DaemonSet deployed
- ✅ Collecting logs từ pods

**Alertmanager:**
- ✅ Deployed và running
- ✅ Alert routing configured

**Status:** ✅ 95% hoàn thành

---

# 3.8. Security & Quality

## Security Scanning

**Trivy:**
- ✅ Container image scanning trong CI/CD
- ✅ Harbor image scanning integration

**CodeQL:**
- ✅ Code security analysis trong GitHub Actions

**Checkov:**
- ✅ Infrastructure as Code scanning (Terraform, CloudFormation)

**npm audit:**
- ✅ Dependency vulnerability scanning

## Code Quality

**SonarQube:**
- ✅ Deployed trên Kubernetes
- ✅ Integration trong CI/CD pipeline
- ⚠️ Pod đang start (cần đợi ready)

**ESLint:**
- ✅ Code linting trong CI pipeline

**TypeScript:**
- ✅ Type checking trong CI pipeline

**Status:** ✅ 70% hoàn thành

---

# 3.9. Applications Deployment

## Microservices

**5 Services:**
1. ✅ api-gateway: Deployment manifest ready
2. ✅ auth-service: Deployment manifest ready
3. ✅ book-service: Deployment manifest ready
4. ✅ user-service: Deployment manifest ready
5. ✅ ml-service: Deployment manifest ready

**Configuration:**
- ✅ Services và Ingress configured
- ✅ ImagePullSecrets added
- ✅ Image references đã sửa sang Harbor
- ✅ Health checks configured
- ✅ Resource limits configured

**Status:** ✅ 40% hoàn thành (manifests ready, cần push images)

---

# 4. DEMO

---

# 4. Demo Highlights

## 1. Smart Build System

**Mục đích:** Chứng minh chỉ build service thay đổi

**Kịch bản:**
- Sửa code trong `backend/services/api-gateway/`
- Push code → GitHub Actions detect changes
- Chỉ `api-gateway` job chạy, các services khác skip
- Show parallel builds khi sửa multiple services

## 2. CI/CD Pipeline

**PR Pipeline:**
- Tạo Pull Request
- Show: Lint → Test → Security Scan
- Không có build/deploy

**Push Pipeline:**
- Merge PR vào main
- Show: Build → Scan → Push to Harbor → Update Manifests
- Show Harbor UI với image mới

## 3. GitOps & Image Updater

**Workflow:**
- Show ArgoCD UI với 6 applications
- Show Image Updater detect new image
- Show manifest tự động update
- Show ArgoCD sync và pods rolling update

## 4. Monitoring

**Show:**
- Prometheus: Metrics queries
- Grafana: Dashboards và logs
- Loki: Log exploration

## 5. Security

**Show:**
- Trivy scan results
- SonarQube analysis
- Harbor image scanning

## 6. Rollback

**Show:**
- Manual rollback qua ArgoCD UI
- kubectl rollout undo
- Automatic rollback on health check failure

---

# 5. Tổng kết

## Kết quả đạt được

✅ **Infrastructure as Code:**
- Xây dựng thành công K3s cluster (3 nodes) trên AWS bằng Terraform
- Ansible playbooks cho K3s deployment và configuration
- 3 environments (Dev, Staging, Prod) với Kustomize overlays

✅ **CI/CD Pipeline:**
- Smart Build System: Chỉ build services có thay đổi
- GitHub Actions workflows: PR pipeline và Push pipeline
- Security scanning: Trivy, CodeQL, SonarQube
- Harbor integration: Push images và scanning

✅ **GitOps:**
- ArgoCD deployed và configured với 6 applications
- ArgoCD Image Updater: Tự động update image tags
- Automated sync và self-healing

✅ **Monitoring & Observability:**
- Prometheus: Metrics collection
- Grafana: Visualization dashboards
- Loki: Log aggregation
- Alertmanager: Alert routing

✅ **Security:**
- Container scanning (Trivy)
- Code scanning (CodeQL)
- Code quality (SonarQube)
- Infrastructure scanning (Checkov)

✅ **Applications:**
- 5 microservices với deployment manifests
- Multi-environment support
- Health checks và resource limits

**Tỷ lệ hoàn thành: ~78-90%**

---

# 5. Tổng kết (tiếp)

## Hạn chế & Hướng phát triển

### Hạn chế hiện tại

⚠️ **Cần setup thủ công:**
- GitHub Secrets (HARBOR_REGISTRY, HARBOR_USERNAME, HARBOR_PASSWORD)
- Push images lên Harbor
- Fix Harbor Redis connection issue
- Sửa ArgoCD Image Updater annotations (harbor.yourdomain.com → địa chỉ thật)

⚠️ **Cần hoàn thiện:**
- Environment promotion workflow automation
- Auto shutdown/startup scripts cho AWS resources
- Advanced deployment strategies (Canary, Blue-Green)
- MLOps pipeline (có config nhưng chưa test đầy đủ)

### Hướng phát triển tương lai

**Short-term (1-3 tháng):**
- Canary deployment strategy
- Blue-Green deployment
- Advanced monitoring dashboards
- Cost optimization (auto shutdown/startup)
- Environment promotion automation

**Medium-term (3-6 tháng):**
- MLOps pipeline hoàn chỉnh
- Advanced security scanning
- Performance optimization
- Multi-region deployment
- Disaster recovery

**Long-term (6-12 tháng):**
- Service mesh (Istio/Linkerd)
- Advanced observability (distributed tracing)
- Chaos engineering
- Auto-scaling policies
- Advanced GitOps patterns

---

# THANK YOU!

NHÓM 15

---

## Phụ lục: Thống kê Project

### Tỷ lệ hoàn thành theo component

- **Infrastructure:** 90%
- **CI/CD:** 75%
- **GitOps:** 80%
- **Container Registry:** 85%
- **Monitoring:** 95%
- **Security:** 70%
- **Applications:** 40%

**Tổng thể: ~78-90% hoàn thành**

### Số lượng files và components

- **Terraform modules:** 12 files
- **Ansible playbooks:** 4 playbooks
- **Kubernetes manifests:** 50+ files
- **GitHub Actions workflows:** 9 workflows
- **Microservices:** 5 services
- **ArgoCD Applications:** 6 applications
- **Monitoring components:** 5 components (Prometheus, Grafana, Loki, Promtail, Alertmanager)






