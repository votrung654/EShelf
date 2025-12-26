# Tài Liệu Ôn Tập eShelf Project

Tài liệu này giúp hiểu 100% về project và trả lời câu hỏi của giảng viên, đặc biệt về kiến trúc microservices.

---

## 1. Kiến Trúc Microservices

### 1.1. Tổng Quan

**Câu hỏi thường gặp:** "Tại sao chọn microservices architecture?"

**Trả lời:**
- **Scalability:** Mỗi service có thể scale độc lập theo nhu cầu
- **Independent Deployment:** Deploy service riêng lẻ không ảnh hưởng services khác
- **Technology Diversity:** Mỗi service có thể dùng technology stack phù hợp (Node.js cho backend, Python cho ML)
- **Team Autonomy:** Teams có thể làm việc độc lập trên từng service
- **Fault Isolation:** Lỗi ở một service không làm crash toàn bộ system

### 1.2. Service Breakdown

**Auth Service (Port 3001):**
- **Responsibility:** Authentication và authorization
- **Technology:** Express.js, Prisma ORM, PostgreSQL
- **Endpoints:** `/auth/login`, `/auth/register`, `/auth/refresh`
- **Dependencies:** PostgreSQL database
- **Standalone:** Có thể chạy độc lập

**Book Service (Port 3002):**
- **Responsibility:** Book CRUD operations, search, filtering
- **Technology:** Express.js, Prisma ORM, PostgreSQL
- **Endpoints:** `/books`, `/books/search`, `/books/:id`
- **Dependencies:** PostgreSQL database
- **Can call:** ML Service cho recommendations

**User Service (Port 3003):**
- **Responsibility:** User profile, favorites, collections
- **Technology:** Express.js, Prisma ORM, PostgreSQL
- **Endpoints:** `/users/profile`, `/users/favorites`, `/users/collections`
- **Dependencies:** PostgreSQL database

**ML Service (Port 8000):**
- **Responsibility:** Book recommendations, similarity search
- **Technology:** FastAPI, scikit-learn, Python
- **Endpoints:** `/recommendations`, `/similarity`
- **Dependencies:** Model files, có thể call Book Service
- **Standalone:** Có thể chạy độc lập

### 1.3. Service Communication

**Pattern:** API Gateway

**Flow:**
```
User Request → Frontend → API Gateway → Service → Database
                                    ↓
                            Response ← Service ← Database
```

**API Gateway Responsibilities:**
- Request routing
- Authentication (JWT validation)
- Rate limiting
- Request/Response transformation
- Load balancing (future)

**Service-to-Service Communication:**
- HTTP/REST
- Synchronous communication
- Future: Message queues cho async communication

### 1.4. Database Architecture

**Current State:**
- Shared PostgreSQL database
- Schema separation by service (tables prefixed)
- Prisma ORM cho type safety

**Future State:**
- Database per service
- Event-driven architecture cho data consistency
- Saga pattern cho distributed transactions

**Why Shared Database Initially:**
- Simpler setup
- Easier development
- Can migrate to database per service later

---

## 2. Infrastructure as Code

### 2.1. Terraform

**What:** Infrastructure provisioning tool

**What We Manage:**
- VPC với public/private subnets
- Security Groups
- EC2 instances (3 nodes cho K3s)
- Internet Gateway, NAT Gateway
- Route tables

**Structure:**
```
infrastructure/terraform/
  modules/
    vpc/
    ec2/
    security/
  environments/
    dev/
    staging/ (future)
    prod/ (future)
```

**Benefits:**
- Version control cho infrastructure
- Reproducible deployments
- Environment consistency
- Easy rollback

### 2.2. Ansible

**What:** Configuration management tool

**What We Do:**
- Install K3s trên master node
- Join worker nodes vào cluster
- Configure kubeconfig
- Setup tools và dependencies

**Playbooks:**
- `k3s-cluster.yml`: Setup cluster
- `setup-tools.yml`: Install tools

**Benefits:**
- Automated configuration
- Idempotent operations
- Easy to maintain

### 2.3. CloudFormation

**What:** AWS native IaC tool

**What We Use For:**
- CodePipeline setup
- EC2 stack templates

**Why Both Terraform and CloudFormation:**
- Terraform cho main infrastructure
- CloudFormation cho AWS-specific services

---

## 3. Kubernetes & K3s

### 3.1. Why K3s?

**K3s là gì:**
- Lightweight Kubernetes distribution
- Single binary, < 50MB
- Designed cho edge computing và development

**Tại sao chọn K3s:**
- Resource efficient (phù hợp với tài nguyên hạn chế)
- Easy setup và maintenance
- Full Kubernetes API compatibility
- Good cho development và testing

**Limitations:**
- Không phù hợp cho production scale lớn
- Một số advanced features có thể thiếu

### 3.2. Cluster Architecture

**3 Nodes:**
- 1 Master node: Control plane (API server, etcd, scheduler)
- 2 Worker nodes: Application pods

**Namespaces:**
- `eshelf-dev`: Application services
- `monitoring`: Prometheus, Grafana, Loki
- `argocd`: GitOps deployment
- `harbor`: Container registry
- `default`: System pods

### 3.3. Kustomize

**What:** Kubernetes native configuration management

**Structure:**
```
infrastructure/kubernetes/
  base/: Common configurations
  overlays/
    dev/: Dev-specific overrides
    staging/: Staging-specific (future)
    prod/: Prod-specific (future)
```

**What We Override:**
- Image tags
- Replica counts
- Resource limits
- Environment variables

**Benefits:**
- DRY principle
- Environment-specific configs
- Easy to maintain

---

## 4. GitOps với ArgoCD

### 4.1. GitOps Pattern

**Core Principle:**
- Git repository là source of truth
- All changes qua Git
- Automated sync từ Git đến cluster

**Benefits:**
- Audit trail
- Version control
- Rollback capability
- Team collaboration

### 4.2. ArgoCD Workflow

**Setup:**
1. Define applications trong Git
2. ArgoCD monitor Git repository
3. Detect changes và sync cluster

**Sync Process:**
- ArgoCD poll Git mỗi 3 phút (default)
- Compare Git state với cluster state
- Apply changes nếu có differences
- Self-healing: Revert manual changes

### 4.3. ArgoCD Image Updater

**What:** Automatically update image tags

**How It Works:**
1. Monitor container registry (Harbor)
2. Detect new images matching policy
3. Update manifests trong Git
4. ArgoCD sync changes

**Configuration:**
- Annotations trên ArgoCD Applications
- Update policies (semver, latest, etc.)
- Write-back method (git)

---

## 5. CI/CD Pipeline

### 5.1. GitHub Actions

**PR Pipeline:**
- Trigger: Pull Request
- Steps:
  1. Lint code
  2. Run tests
  3. Security scan (Trivy, Checkov)
  4. Code quality (SonarQube)
- **Không deploy**

**Push to Main Pipeline:**
- Trigger: Merge vào main
- Steps:
  1. Lint và test
  2. Security scan
  3. Build Docker images
  4. Push to Harbor
  5. Update Kubernetes manifests
  6. ArgoCD sync (automatic)

### 5.2. Smart Build System

**Problem:** Build tất cả services mất thời gian và tài nguyên

**Solution:** Chỉ build services có code changes thực sự

**How It Works:**
1. Path-based filtering: Identify changed services
2. Code analysis: Loại bỏ comment-only changes
3. Build only changed services

**Benefits:**
- Giảm 60% build time
- Tiết kiệm CI/CD resources
- Faster feedback

### 5.3. Security Scanning

**Trivy:**
- Container image vulnerability scanning
- Scan Docker images trước khi push
- Fail build nếu có critical vulnerabilities

**Checkov:**
- IaC security scanning
- Scan Terraform và CloudFormation
- Detect misconfigurations

**SonarQube:**
- Code quality analysis
- Security vulnerabilities
- Code smells
- Technical debt

---

## 6. Container Registry - Harbor

### 6.1. Why Harbor?

**DockerHub Limitations:**
- Rate limits
- External dependency
- Limited control

**Harbor Benefits:**
- Self-hosted
- Image scanning tích hợp
- Access control (RBAC)
- Replication support

### 6.2. Harbor Setup

**Deployment:**
- Deploy trên Kubernetes
- Persistent storage cho images
- Ingress hoặc port-forward để access

**Configuration:**
- Projects và repositories
- User management
- Image scanning policies

### 6.3. Image Management

**Tagging Strategy:**
- `dev`: Development images
- `staging`: Staging images
- `prod`: Production images
- `latest`: Latest build
- Commit SHA: Specific versions

**Image Pull:**
- Kubernetes pull từ Harbor
- ImagePullSecrets cho authentication
- Internal service DNS: `harbor-core.harbor.svc.cluster.local`

---

## 7. Monitoring Stack

### 7.1. Prometheus

**What:** Metrics collection và time-series database

**How It Works:**
- Pull-based metrics collection
- Service discovery trong Kubernetes
- Store metrics với labels
- Query với PromQL

**What We Monitor:**
- CPU và memory usage
- Request rates và latencies
- Error rates
- Pod status

### 7.2. Grafana

**What:** Visualization và dashboards

**Features:**
- Dashboards từ Prometheus data
- Alert notifications
- Custom dashboards per service
- Data source integration

**Dashboards:**
- Cluster overview
- Service metrics
- Resource usage
- Custom business metrics

### 7.3. Loki

**What:** Log aggregation system

**How It Works:**
- Promtail collect logs từ pods
- Send logs đến Loki
- Index logs với labels
- Query logs qua LogQL

**Benefits:**
- Centralized logging
- Fast queries
- Cost-effective storage

### 7.4. Alertmanager

**What:** Alert routing và notification

**Features:**
- Alert grouping
- Routing rules
- Notification channels (email, Slack, etc.)
- Silence và inhibition

---

## 8. Security

### 8.1. Container Security

**Best Practices:**
- Non-root users trong containers
- Minimal base images
- Regular base image updates
- Security scanning (Trivy)

**Implementation:**
- Dockerfile với `USER` directive
- Alpine Linux base images
- Multi-stage builds

### 8.2. Secrets Management

**Kubernetes Secrets:**
- Store sensitive data (passwords, tokens)
- Mount vào pods
- Base64 encoded (not encrypted by default)

**Best Practices:**
- Không commit secrets vào Git
- Rotate secrets regularly
- Use external secret management (future: AWS Secrets Manager)

### 8.3. Network Security

**VPC:**
- Public subnets cho bastion
- Private subnets cho application nodes
- Security Groups cho firewall rules

**Network Policies:**
- Kubernetes Network Policies
- Control traffic giữa pods
- Namespace isolation

---

## 9. MLOps

### 9.1. ML Service Architecture

**Technology:**
- FastAPI cho REST API
- scikit-learn cho ML algorithms
- Python 3.11

**Endpoints:**
- `/recommendations`: Book recommendations
- `/similarity`: Similar books
- `/health`: Health check

**Model Serving:**
- Load model khi service start
- In-memory inference
- Future: Model versioning với MLflow

### 9.2. Model Training

**Current:**
- Manual training
- Model files trong repository

**Future:**
- Automated training pipeline (GitHub Actions)
- MLflow cho model tracking
- Model registry

### 9.3. Model Deployment

**Current:**
- Model trong container image
- Deploy như service khác

**Future:**
- Canary deployment
- A/B testing
- Automatic rollback

---

## 10. Câu Hỏi Thường Gặp từ Giảng Viên

### Q1: "Tại sao chọn microservices thay vì monolithic?"

**Trả lời:**
- **Scalability:** Mỗi service scale độc lập. Book Service có thể cần nhiều resources hơn Auth Service
- **Technology Diversity:** ML Service dùng Python, backend services dùng Node.js
- **Independent Deployment:** Deploy Book Service không ảnh hưởng Auth Service
- **Team Autonomy:** Teams có thể làm việc độc lập
- **Fault Isolation:** Lỗi ở ML Service không làm crash toàn bộ system

### Q2: "Làm thế nào đảm bảo data consistency giữa các services?"

**Trả lời:**
- **Current:** Shared database với schema separation. Transactions đảm bảo consistency
- **Future:** Database per service với event-driven architecture. Eventual consistency với Saga pattern
- **Trade-offs:** Strong consistency vs availability. Chọn phù hợp với use case

### Q3: "Xử lý service failures như thế nào?"

**Trả lời:**
- **Health Checks:** Kubernetes liveness và readiness probes
- **Retry Mechanisms:** API Gateway retry failed requests
- **Circuit Breaker:** (Future) Prevent cascade failures
- **Monitoring:** Prometheus và Grafana detect issues sớm
- **Alerting:** Alertmanager notify khi có problems

### Q4: "CI/CD pipeline có gì đặc biệt?"

**Trả lời:**
- **Smart Build:** Chỉ build services có changes, giảm 60% build time
- **PR vs Push Separation:** PR chỉ test, không deploy. Push mới deploy
- **Security Scanning:** Trivy, Checkov, SonarQube tự động
- **GitOps:** ArgoCD tự động sync từ Git
- **Automated Rollback:** (Future) Rollback nếu health checks fail

### Q5: "Monitoring strategy là gì?"

**Trả lời:**
- **Metrics:** Prometheus collect metrics từ services
- **Visualization:** Grafana dashboards cho real-time visibility
- **Logs:** Loki aggregate logs từ tất cả pods
- **Alerts:** Alertmanager notify khi có issues
- **Coverage:** Monitor cả infrastructure và application metrics

### Q6: "Tại sao chọn K3s thay vì full Kubernetes?"

**Trả lời:**
- **Resource Efficiency:** K3s nhẹ hơn, phù hợp với tài nguyên hạn chế
- **Easy Setup:** Setup nhanh hơn, ít phức tạp hơn
- **Full Compatibility:** 100% Kubernetes API compatible
- **Use Case:** Development và testing, không phải production scale lớn
- **Trade-off:** Một số advanced features có thể thiếu, nhưng đủ cho project này

### Q7: "GitOps với ArgoCD hoạt động như thế nào?"

**Trả lời:**
- **Source of Truth:** Git repository chứa tất cả Kubernetes manifests
- **Automatic Sync:** ArgoCD poll Git và sync cluster
- **Self-Healing:** ArgoCD revert manual changes về Git state
- **Image Updater:** Tự động update image tags khi có images mới
- **Benefits:** Audit trail, version control, easy rollback

### Q8: "Làm thế nào handle service communication?"

**Trả lời:**
- **API Gateway Pattern:** Single entry point, handle routing và authentication
- **HTTP/REST:** Synchronous communication giữa services
- **Service Discovery:** Kubernetes DNS cho service names
- **Future:** Message queues cho async communication, service mesh cho advanced traffic management

### Q9: "Database architecture như thế nào?"

**Trả lời:**
- **Current:** Shared PostgreSQL database với schema separation
- **Rationale:** Simpler setup, easier development, can migrate later
- **Future:** Database per service với event-driven architecture
- **Consistency:** Transactions cho strong consistency hiện tại, eventual consistency trong tương lai

### Q10: "Security measures là gì?"

**Trả lời:**
- **Container Security:** Non-root users, minimal images, Trivy scanning
- **Secrets Management:** Kubernetes Secrets, không commit vào Git
- **Network Security:** VPC, Security Groups, Network Policies
- **Code Security:** SonarQube, Checkov, Trivy trong CI/CD
- **Authentication:** JWT tokens, API Gateway validation

---

## 11. Key Concepts để Nhớ

### Microservices Patterns
- API Gateway
- Service Discovery
- Circuit Breaker (future)
- Saga Pattern (future)

### DevOps Practices
- Infrastructure as Code
- GitOps
- CI/CD Automation
- Monitoring và Observability

### Kubernetes Concepts
- Pods, Services, Deployments
- Namespaces
- ConfigMaps, Secrets
- Ingress, Network Policies

### Tools và Technologies
- Terraform, Ansible, CloudFormation
- K3s, Kustomize, ArgoCD
- Prometheus, Grafana, Loki
- Harbor, Trivy, Checkov

---

## 12. Demo Preparation

### Commands để Nhớ

**Kubernetes:**
```bash
kubectl get nodes
kubectl get pods -A
kubectl get services -A
kubectl logs -n eshelf-dev deployment/dev-api-gateway
kubectl describe pod <pod-name> -n <namespace>
```

**ArgoCD:**
```bash
kubectl get applications -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Monitoring:**
```bash
kubectl port-forward svc/grafana -n monitoring 3000:3000
kubectl port-forward svc/prometheus -n monitoring 9090:9090
```

**Harbor:**
```bash
kubectl port-forward svc/harbor-core -n harbor 8080:80
```

### URLs để Truy Cập
- ArgoCD: https://localhost:8080
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
- Harbor: http://localhost:8080
- Frontend: http://localhost:5173

---

## 13. Troubleshooting Guide

### Service không start
- Check logs: `kubectl logs <pod-name> -n <namespace>`
- Check events: `kubectl describe pod <pod-name> -n <namespace>`
- Check resources: `kubectl top pods -n <namespace>`

### Image pull errors
- Check ImagePullSecrets: `kubectl get secrets -n <namespace>`
- Check image exists trong Harbor
- Check network connectivity

### ArgoCD không sync
- Check Git repository access
- Check application status: `kubectl get application -n argocd`
- Check ArgoCD logs: `kubectl logs -n argocd deployment/argocd-application-controller`

---

## 14. Study Checklist

Trước khi presentation, đảm bảo bạn có thể:

- [ ] Giải thích kiến trúc microservices và tại sao chọn
- [ ] Mô tả communication giữa services
- [ ] Giải thích Infrastructure as Code với Terraform và Ansible
- [ ] Mô tả Kubernetes deployment với K3s
- [ ] Giải thích GitOps pattern và ArgoCD
- [ ] Mô tả CI/CD pipeline và Smart Build
- [ ] Giải thích monitoring stack
- [ ] Mô tả security measures
- [ ] Giải thích MLOps integration
- [ ] Trả lời câu hỏi về trade-offs và design decisions

