# Architecture Deep Dive - eShelf Project

## Tổng Quan

Tài liệu này giải thích chi tiết cơ chế hoạt động của các tools và components trong kiến trúc eShelf.

## ArgoCD Automation Mechanism

### Cơ Chế Sync Tự Động

ArgoCD sử dụng GitOps pattern để quản lý Kubernetes resources:

1. **Git Repository là Source of Truth:**
   - Tất cả K8s manifests được lưu trong Git
   - ArgoCD monitor Git repository
   - Khi có changes, ArgoCD tự động sync

2. **Application Definition:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
    repoURL: https://github.com/your-org/eshelf-infra.git
    targetRevision: main
    path: infrastructure/kubernetes/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: eshelf-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

3. **Sync Process:**
   - ArgoCD poll Git repo mỗi 3 phút (default)
   - So sánh Git state với cluster state
   - Nếu khác biệt → tự động apply changes
   - `prune: true` → xóa resources không còn trong Git
   - `selfHeal: true` → tự động sync nếu cluster bị thay đổi thủ công

### ArgoCD Image Updater Mechanism

ArgoCD Image Updater tự động update image tags khi có image mới:

1. **Image Update Process:**
   - Image Updater poll container registry (Harbor)
   - Check for new tags matching update policy
   - Update manifest trong Git repo (Kustomize files)
   - ArgoCD detect Git changes và sync

2. **Update Policy:**
```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: api-gateway=harbor.yourdomain.com/eshelf/api-gateway
  argocd-image-updater.argoproj.io/write-back-method: git
  argocd-image-updater.argoproj.io/git-branch: main
  argocd-image-updater.argoproj.io/write-back-target: kustomization
```

3. **Write-Back Process:**
   - Image Updater tìm image mới trong registry
   - Update `kustomization.yaml` với tag mới
   - Commit và push changes vào Git
   - ArgoCD detect changes và sync cluster

### Tại Sao Chọn ArgoCD

- **GitOps Pattern:** Tất cả config trong Git, dễ audit và version control
- **Automated Sync:** Tự động sync, không cần manual kubectl apply
- **Self-Healing:** Tự động fix nếu cluster bị thay đổi
- **Multi-Environment:** Quản lý nhiều environments từ một Git repo
- **Image Updater:** Tự động update image tags, giảm manual work

---

## Smart Build System Mechanism

### Path-Based Filtering

1. **dorny/paths-filter Action:**
   - Filter files thay đổi theo paths
   - Nhanh và hiệu quả
   - Output boolean cho mỗi path pattern

2. **Code Change Detection:**
   - Script `check-service-changes.sh` phân tích git diff
   - Loại bỏ comment lines
   - Chỉ build nếu có code thực sự thay đổi

3. **Two-Stage Process:**
   - Stage 1: Path filter (nhanh) → identify changed services
   - Stage 2: Code analysis (chậm hơn) → verify real code changes

### Tại Sao Cần Smart Build

- **Microservices Architecture:** Nhiều services độc lập
- **Resource Optimization:** Chỉ build services thay đổi
- **Time Saving:** Giảm thời gian CI/CD
- **Cost Reduction:** Giảm compute resources

---

## Harbor Registry Integration

### Migration từ DockerHub

1. **Lý Do Migrate:**
   - DockerHub có rate limits
   - Harbor tự host, không phụ thuộc external service
   - Better security và access control
   - Image scanning tích hợp

2. **Migration Process:**
   - Deploy Harbor trên Kubernetes
   - Update workflows để push/pull từ Harbor
   - Update K8s manifests với Harbor registry URL
   - Migrate existing images (nếu cần)

3. **Workflow Changes:**
```yaml
- name: Login to Harbor
  uses: docker/login-action@v3
  with:
    registry: ${{ secrets.HARBOR_REGISTRY }}
    username: ${{ secrets.HARBOR_USERNAME }}
    password: ${{ secrets.HARBOR_PASSWORD }}
```

### Harbor Features

- **Image Scanning:** Tự động scan vulnerabilities
- **Access Control:** RBAC cho projects và repositories
- **Replication:** Sync images giữa các Harbor instances
- **Webhooks:** Trigger actions khi có image mới

---

## PR vs Push Pipeline Separation

### Pull Request Pipeline

**Trigger:** Khi tạo Pull Request

**Steps:**
1. Lint code
2. Run unit tests
3. Code quality scan (SonarQube)
4. Security scan (Trivy)
5. Build artifacts (không push)

**Không có:**
- Docker build
- Push to registry
- Deploy to cluster

### Push to Main Pipeline

**Trigger:** Khi merge vào main branch

**Steps:**
1. Lint code
2. Run unit tests
3. Security scan
4. Docker build
5. Push to Harbor
6. Update K8s manifests
7. Deploy to cluster (qua ArgoCD)

### Tại Sao Phân Biệt

- **Safety:** PR không deploy, tránh deploy code chưa review
- **Efficiency:** PR chỉ test, nhanh hơn
- **Compliance:** Tuân thủ best practices (code review trước khi deploy)

---

## Terraform Multi-Environment Strategy

### Environment Separation

1. **Dev Environment:**
   - Development và testing
   - Smaller instance types
   - Single AZ deployment
   - Cost-optimized

2. **Staging Environment:**
   - Pre-production testing
   - Similar to prod nhưng smaller scale
   - Multi-AZ deployment
   - Full monitoring

3. **Production Environment:**
   - Production workload
   - Larger instance types
   - Multi-AZ với high availability
   - Full security và monitoring

### S3 Backend Configuration

```hcl
backend "s3" {
  bucket         = "eshelf-terraform-state"
  key            = "prod/terraform.tfstate"
  region         = "ap-southeast-1"
  encrypt        = true
  dynamodb_table = "eshelf-terraform-locks"
}
```

**Lợi ích:**
- Remote state storage
- State locking (DynamoDB)
- Team collaboration
- State versioning

### Module Reusability

- Same modules cho tất cả environments
- Environment-specific variables
- Consistent infrastructure across environments

---

## Kustomize Overlay Strategy

### Base Manifests

- Common configuration cho tất cả environments
- Service definitions
- Base resource limits

### Environment Overlays

1. **Dev Overlay:**
   - 1 replica per service
   - Lower resource limits
   - Dev-specific configs

2. **Staging Overlay:**
   - 2 replicas per service
   - Medium resource limits
   - Staging-specific configs

3. **Prod Overlay:**
   - 3 replicas per service
   - Higher resource limits
   - Production-specific configs

### Image Tag Management

- Base manifest dùng `latest` tag
- Overlays override với specific tags
- ArgoCD Image Updater update tags trong overlays

---

## SonarQube Integration

### Code Quality Analysis

1. **Analysis Process:**
   - SonarQube scan source code
   - Detect code smells, bugs, vulnerabilities
   - Calculate code coverage
   - Generate quality gate

2. **Quality Gate:**
   - Pass/Fail criteria
   - Block merge nếu fail (optional)
   - Report trong PR comments

3. **Integration Points:**
   - GitHub Actions PR pipeline
   - Jenkins pipeline
   - Pre-commit hooks (optional)

### Metrics Tracked

- Code coverage
- Code duplication
- Technical debt
- Security vulnerabilities
- Code smells
- Maintainability rating

---

## Jenkins on Kubernetes

### Deployment Architecture

1. **Jenkins Master:**
   - Single pod với persistent volume
   - Manages pipelines
   - Connects to agents

2. **Jenkins Agents:**
   - Dynamic pods (Kubernetes plugin)
   - Created on-demand
   - Deleted after job completion

3. **Benefits:**
   - Scalable (agents scale automatically)
   - Resource efficient (agents only run when needed)
   - Isolated builds (each job gets fresh pod)

### Pipeline as Code

- Jenkinsfile trong Git
- Version controlled
- Reviewable như code
- Reusable across projects

---

## Monitoring Stack Architecture

### Prometheus

- Pull-based metrics collection
- Service discovery trong K8s
- Time-series database
- Alerting rules

### Grafana

- Visualization layer
- Dashboards từ Prometheus data
- Alert notifications
- Custom dashboards per service

### Loki

- Log aggregation
- Similar to Prometheus nhưng cho logs
- Label-based indexing
- Query logs qua LogQL

### Promtail

- Log shipper
- DaemonSet trên mỗi node
- Collect logs từ pods
- Send to Loki

---

## Security Layers

### Network Security

- VPC với public/private subnets
- Security groups
- NAT Gateway cho outbound
- Bastion host cho SSH access

### Container Security

- Non-root containers
- Read-only filesystems (where possible)
- Resource limits
- Security contexts

### Image Security

- Trivy scanning trong CI/CD
- Harbor image scanning
- Only signed images (future)
- Regular base image updates

### Access Control

- RBAC trong Kubernetes
- IAM roles cho AWS resources
- Secrets management (AWS Secrets Manager)
- Least privilege principle

---

## MLOps Pipeline

### Model Training

1. **Trigger:** GitHub Actions workflow
2. **Process:**
   - Train model với MLflow tracking
   - Save model artifacts
   - Register model trong MLflow
   - Generate metrics

3. **MLflow Integration:**
   - Track experiments
   - Version models
   - Compare runs
   - Model registry

### Model Deployment

1. **Canary Deployment:**
   - Deploy new model to small percentage
   - Monitor metrics
   - Gradually increase traffic
   - Rollback nếu metrics degrade

2. **Rollback Strategy:**
   - Automatic rollback nếu health check fail
   - Manual rollback qua workflow
   - Model versioning trong MLflow

---

## Kết Luận

Kiến trúc eShelf sử dụng nhiều tools và patterns:
- **GitOps** với ArgoCD
- **Smart Build** để optimize CI/CD
- **Multi-environment** với Terraform và Kustomize
- **Container Registry** với Harbor
- **Code Quality** với SonarQube
- **CI/CD** với GitHub Actions và Jenkins
- **Monitoring** với Prometheus stack

Tất cả components được tích hợp để tạo một hệ thống tự động, an toàn, và scalable.

