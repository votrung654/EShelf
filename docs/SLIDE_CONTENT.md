# Slide Content - eShelf Project Presentation

## Slide 1: Title Slide

**Title:** eShelf - Microservices Platform với CI/CD và GitOps

**Subtitle:** DevOps & MLOps Project

**Team Members:** [Tên nhóm]

**Date:** [Ngày]

---

## Slide 2: Tổng Quan Project

**eShelf là gì?**
- Nền tảng quản lý sách điện tử
- Kiến trúc Microservices
- Full-stack application (Frontend + Backend)

**Technology Stack:**
- Frontend: React, TypeScript
- Backend: Node.js, Express
- Database: PostgreSQL (Prisma ORM)
- Infrastructure: AWS, Terraform, Ansible
- Container: Docker, Kubernetes (K3s)
- CI/CD: GitHub Actions, Jenkins
- GitOps: ArgoCD
- Registry: Harbor
- Monitoring: Prometheus, Grafana, Loki

---

## Slide 3: Kiến Trúc Hạ Tầng

**AWS Infrastructure:**
- VPC với Public và Private Subnets
- Internet Gateway và NAT Gateway
- Security Groups
- EC2 instances (3 nodes cho K3s cluster)

**Kubernetes Cluster:**
- K3s lightweight distribution
- 1 Master node (control plane)
- 2 Worker nodes (application pods)
- Network: Flannel CNI
- Storage: Local path provisioner

**Infrastructure as Code:**
- Terraform modules (VPC, EC2, Security Groups, IAM)
- Ansible playbooks cho K3s deployment
- 3 environments: Dev, Staging, Prod

**Diagram:** [Architecture diagram từ ARCHITECTURE_DIAGRAM.md]

---

## Slide 4: Microservices Architecture

**Services:**
1. **API Gateway**: Entry point, routing, load balancing
2. **Auth Service**: Authentication, authorization, JWT tokens
3. **User Service**: User management, profiles
4. **Book Service**: Book catalog, search, recommendations
5. **ML Service**: Machine learning features, recommendations

**Communication:**
- RESTful APIs
- Service-to-service communication
- Database per service pattern

**Diagram:** [Microservices diagram]

---

## Slide 5: CI/CD Pipeline - Tổng Quan

**Hai Pipeline Riêng Biệt:**

**1. Pull Request Pipeline:**
- Trigger: Khi tạo/update PR
- Mục đích: Validation và quality checks
- Steps: Lint → Type Check → Unit Tests → Static Analysis → Security Scan
- **Không deploy**

**2. Push to Main Pipeline:**
- Trigger: Khi merge vào main
- Mục đích: Build, test, và deploy
- Steps: Validation → Docker Build → Security Scan → Push to Harbor → Update Manifests → ArgoCD Sync

**Diagram:** [CI/CD flow diagram]

---

## Slide 6: Smart Build System

**Vấn Đề:**
- Monorepo với nhiều microservices
- Build toàn bộ khi chỉ sửa 1 service → lãng phí thời gian và resources

**Giải Pháp:**
- Path-based filtering
- Chỉ build services có file changes
- Parallel builds cho multiple services

**Ví Dụ:**
```
Sửa backend/services/api-gateway/ → Chỉ build api-gateway
Sửa backend/services/auth-service/ → Chỉ build auth-service
Sửa cả 2 → Build cả 2 song song
```

**Implementation:**
- GitHub Actions với `dorny/paths-filter`
- Matrix strategy cho parallel execution
- Conditional job execution

**Demo:** [Show GitHub Actions workflow với path filtering]

---

## Slide 7: Container Registry - Harbor

**Tại Sao Harbor?**
- Self-hosted registry
- Image scanning (Trivy integration)
- Access control và security
- Thay thế DockerHub public

**Setup:**
- Deployed trên Kubernetes
- Internal service: `harbor-core.harbor.svc.cluster.local`
- Project: `eshelf`
- Image naming: `harbor-core.../eshelf/<service>:<tag>`

**Features:**
- Image vulnerability scanning
- Image retention policies
- User authentication
- Project-based organization

**Diagram:** [Harbor architecture]

---

## Slide 8: GitOps với ArgoCD

**GitOps Principles:**
- Declarative configuration
- Git as single source of truth
- Automated sync
- Self-healing

**ArgoCD Setup:**
- 6 Applications (api-gateway, auth-service, book-service, user-service, ml-service, monitoring)
- Automated sync policy
- Self-heal enabled
- Multi-environment support (dev, staging, prod)

**Workflow:**
```
Code Change → Build Image → Push to Harbor → 
Update Manifest (Git) → ArgoCD Detect → 
Sync to Cluster → Pods Running
```

**Diagram:** [ArgoCD sync flow]

---

## Slide 9: ArgoCD Image Updater

**Vấn Đề:**
- Khi có image mới, làm sao cluster biết để update?

**Giải Pháp:**
- ArgoCD Image Updater component
- Monitor Harbor registry
- Detect new image tags
- Tự động update Kustomize manifests
- Commit changes to Git
- Trigger ArgoCD sync

**Configuration:**
- Image Updater ConfigMap
- Application annotations
- Write-back method: Git
- Update strategy: Semver, latest, digest

**Ví Dụ:**
```
New image: harbor.../eshelf/api-gateway:abc123
→ Image Updater detect
→ Update kustomization.yaml: image: ...:abc123
→ Git commit
→ ArgoCD sync
→ Rolling update pods
```

**Diagram:** [Image Updater flow]

---

## Slide 10: Multi-Environment Deployment

**3 Environments:**
- **Dev**: Development và testing
- **Staging**: Pre-production testing
- **Prod**: Production

**Kustomize Overlays:**
```
infrastructure/kubernetes/
├── base/
│   └── deployments/
└── overlays/
    ├── dev/ (replicas: 1, image: ...:dev)
    ├── staging/ (replicas: 2, image: ...:staging)
    └── prod/ (replicas: 3, image: ...:prod)
```

**Environment Promotion:**
- Dev → Staging: Automated (có thể)
- Staging → Prod: Manual approval

**Benefits:**
- Environment-specific configs
- Isolated testing
- Gradual rollout

---

## Slide 11: Security & Quality

**Security Scanning:**
- **Trivy**: Container image vulnerability scanning
- **CodeQL**: Code security analysis
- **npm audit**: Dependency vulnerabilities
- **Harbor scanning**: Image scanning on push

**Code Quality:**
- **SonarQube**: Code quality analysis, code coverage
- **ESLint**: Code linting
- **TypeScript**: Type checking

**Infrastructure Security:**
- **Network Policies**: Isolation giữa namespaces
- **RBAC**: Role-based access control
- **Secrets Management**: Kubernetes secrets
- **Image Pull Secrets**: Harbor authentication

**Pre-deployment Gates:**
- Security scan must pass
- Code quality gates
- No critical vulnerabilities

---

## Slide 12: Monitoring & Observability

**Metrics (Prometheus):**
- Container metrics (CPU, memory, network)
- Application metrics (request rate, latency)
- Kubernetes metrics (pods, nodes)
- Custom business metrics

**Logs (Loki):**
- Centralized log aggregation
- Log queries và filtering
- Integration với Grafana

**Visualization (Grafana):**
- Dashboards cho metrics
- Log exploration
- Alert visualization

**Alerting (Alertmanager):**
- Alert rules
- Notification channels
- Alert grouping và routing

**Diagram:** [Monitoring stack]

---

## Slide 13: Rollback Mechanism

**Automatic Rollback:**
- Health check failures
- Deployment failures
- Pod crash loops

**Manual Rollback:**
- ArgoCD UI: Click "Rollback"
- kubectl: `kubectl rollout undo`
- Git: Revert manifest changes

**Rollback Scenarios:**
1. **Failed Health Checks:**
   - Liveness probe fails
   - Readiness probe fails
   - Automatic rollback

2. **Deployment Errors:**
   - Image pull errors
   - Configuration errors
   - Resource constraints

3. **Performance Issues:**
   - High latency
   - Error rate increase
   - Manual rollback

**Demo:** [Show rollback process]

---

## Slide 14: Demo Highlights

**1. Smart Build:**
- Show code change trong 1 service
- Show chỉ service đó được build
- Show parallel builds

**2. GitOps:**
- Show image push to Harbor
- Show manifest update
- Show ArgoCD sync
- Show pods rolling update

**3. Image Updater:**
- Show new image tag
- Show automatic manifest update
- Show ArgoCD sync

**4. Monitoring:**
- Show Prometheus metrics
- Show Grafana dashboards
- Show Loki logs

**5. Security:**
- Show Trivy scan results
- Show SonarQube analysis
- Show Harbor image scanning

---

## Slide 15: Kết Luận

**Đã Đạt Được:**
- Smart Build System (chỉ build service thay đổi)
- GitOps với ArgoCD (tự động sync)
- Image auto-update mechanism
- Multi-environment deployment
- Security scanning và quality gates
- Monitoring và observability
- Automated rollback

**Đáp Ứng Yêu Cầu:**
- Infrastructure as Code (Terraform, Ansible)
- CI/CD Automation (GitHub Actions, Jenkins)
- GitOps (ArgoCD)
- Container Registry (Harbor)
- Monitoring (Prometheus, Grafana, Loki)
- Security (Trivy, CodeQL, SonarQube)

**Tỷ Lệ Hoàn Thành:** ~90%

---

## Slide 16: Hướng Phát Triển Tương Lai

**Short-term (1-3 tháng):**
- Canary deployment strategy
- Blue-Green deployment
- Advanced monitoring dashboards
- Cost optimization (auto shutdown/startup)
- Environment promotion automation

**Medium-term (3-6 tháng):**
- MLOps pipeline (nếu có ML service)
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

**Learning & Improvement:**
- Best practices từ industry
- Community contributions
- Continuous optimization

---

## Slide 17: Q&A

**Questions?**

**Contact:**
- GitHub: [Repository link]
- Documentation: [Docs link]

**Thank You!**

---

## Phụ Lục: Diagrams Cần Vẽ

1. **Infrastructure Diagram:**
   - AWS VPC với subnets
   - K3s cluster topology
   - Network flow

2. **CI/CD Flow Diagram:**
   - PR pipeline flow
   - Push pipeline flow
   - Smart Build logic

3. **GitOps Flow Diagram:**
   - Code to deployment flow
   - Image update flow
   - ArgoCD sync flow

4. **Microservices Architecture:**
   - Service communication
   - Database per service
   - API Gateway pattern

5. **Monitoring Stack:**
   - Prometheus scrape flow
   - Loki log flow
   - Grafana visualization






