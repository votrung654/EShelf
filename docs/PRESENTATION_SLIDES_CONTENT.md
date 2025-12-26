# Nội Dung Slide Thuyết Trình eShelf Project

## Slide 1: Title Slide

**Tiêu đề:** eShelf - Enterprise eBook Platform
**Phụ đề:** Microservices Architecture với DevOps & MLOps
**Thông tin:**
- Môn học: NT548 - DevOps & MLOps
- Trường: Đại học Công nghệ Thông tin (UIT)
- Team:
  - Võ Đình Trung (22521571)
  - Lê Văn Vũ (23521809)
  - Trương Phúc Trường (22521587)

---

## Slide 2: Tổng Quan Project

**Vấn đề:**
- Nền tảng đọc sách điện tử cần scalability và maintainability
- Monolithic architecture không đáp ứng được yêu cầu

**Giải pháp:**
- Microservices architecture
- DevOps practices
- MLOps integration

**Mục tiêu:**
- High availability
- Scalability
- Fast deployment
- Continuous integration

---

## Slide 3: Kiến Trúc Hệ Thống

**Diagram:** System Architecture

**Components:**
- Frontend (React 18 + Vite)
- API Gateway (Express.js)
- Microservices:
  - Auth Service (JWT authentication)
  - Book Service (CRUD, search)
  - User Service (Profile, favorites)
  - ML Service (Recommendations)
- Database (PostgreSQL)
- Cache (Redis)

**Flow:**
```
User → Frontend → API Gateway → Microservices → Database
```

---

## Slide 4: Microservices Chi Tiết

**Auth Service:**
- Port: 3001
- Technology: Express.js, Prisma
- Responsibilities: Authentication, authorization, JWT tokens

**Book Service:**
- Port: 3002
- Technology: Express.js, Prisma
- Responsibilities: Book CRUD, search, filtering

**User Service:**
- Port: 3003
- Technology: Express.js, Prisma
- Responsibilities: User profile, favorites, collections

**ML Service:**
- Port: 8000
- Technology: FastAPI, scikit-learn
- Responsibilities: Recommendations, similarity search

**Communication:** HTTP/REST

---

## Slide 5: Technology Stack

**Frontend:**
- React 18, Vite, TailwindCSS, React Router

**Backend:**
- Node.js 20, Express.js, Prisma ORM

**ML/AI:**
- Python 3.11, FastAPI, scikit-learn

**Database:**
- PostgreSQL 16, Redis 7

**DevOps:**
- Docker, Docker Compose
- Kubernetes (K3s)
- Terraform, CloudFormation
- Ansible

**CI/CD:**
- GitHub Actions
- Jenkins
- AWS CodePipeline

**GitOps:**
- ArgoCD

**Registry:**
- Harbor

**Monitoring:**
- Prometheus, Grafana, Loki, Alertmanager

---

## 3. Triển khai Hệ thống

### 3.1. Hạ tầng triển khai - Infrastructure as Code

**Terraform**

Hệ thống sử dụng Terraform để quản lý toàn bộ hạ tầng trên AWS theo mô hình Infrastructure as Code. Cấu trúc Terraform được tổ chức theo mô hình module-based, cho phép tái sử dụng và quản lý dễ dàng.

**Các module chính:**
- **VPC Module:** Tạo VPC với public và private subnets, Internet Gateway, NAT Gateway để đảm bảo network isolation và security
- **EC2 Module:** Quản lý EC2 instances cho K3s cluster, bao gồm 1 master node và 2 worker nodes, cùng bastion host cho SSH access
- **Security Groups Module:** Định nghĩa firewall rules cho từng tier (bastion, master, workers)
- **IAM Module:** Quản lý IAM roles và policies cho EC2 instances

**Triển khai:**
- Development environment đã được triển khai thành công trên AWS
- Terraform state được quản lý local (có thể chuyển sang S3 backend cho production)
- Hỗ trợ multi-environment với cấu trúc environments/dev, environments/staging, environments/prod

**Lợi ích:**
- Version control cho toàn bộ infrastructure configuration
- Reproducible deployments - có thể tạo lại hạ tầng bất cứ lúc nào
- Environment consistency - dev, staging, prod sử dụng cùng một template
- Cost optimization - dễ dàng destroy và recreate resources

**CloudFormation**

Bên cạnh Terraform, project cũng sử dụng AWS CloudFormation cho một số components cụ thể:

- **VPC Stack:** Template để tạo VPC, subnets, routing tables
- **EC2 Stack:** Template để tạo EC2 instances với security groups
- **CodePipeline Stack:** Template để setup AWS CodePipeline cho automated deployment

**Lý do sử dụng cả hai:**
- Terraform cho infrastructure chính (linh hoạt, state management tốt)
- CloudFormation cho AWS-native services (CodePipeline, tích hợp tốt với AWS ecosystem)

**Gợi ý hình ảnh:**
- Sơ đồ kiến trúc AWS với VPC, subnets, EC2 instances
- Terraform module structure diagram
- CloudFormation stack relationships

---

### 3.2. Container hóa hệ thống

**Docker**

Tất cả các microservices được container hóa bằng Docker với các best practices:

**Multi-stage builds:** Giảm kích thước image bằng cách tách build stage và runtime stage. Ví dụ, Node.js services sử dụng base image để build, sau đó copy chỉ các file cần thiết vào runtime image.

**Security hardening:**
- Non-root users: Tất cả containers chạy với non-root user để giảm attack surface
- Minimal base images: Sử dụng Alpine Linux hoặc distroless images khi có thể
- Health checks: Mỗi service có health check endpoint được định nghĩa trong Dockerfile

**Dockerfile structure:**
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Runtime stage
FROM node:20-alpine
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
USER nodejs
COPY --from=builder /app /app
HEALTHCHECK --interval=30s --timeout=3s CMD node healthcheck.js
```

**Docker Compose**

Docker Compose được sử dụng cho local development và testing:

**Service orchestration:**
- PostgreSQL database với automatic initialization
- Redis cache service
- Migration service tự động chạy Prisma migrations trước khi services khởi động
- Tất cả microservices (API Gateway, Auth, Book, User, ML) với proper dependencies

**Features:**
- Automatic database migrations qua dedicated migration service
- Service dependencies được định nghĩa rõ ràng (services đợi database ready)
- Volume mounts cho hot reload trong development
- Environment variables management qua .env files

**Lợi ích:**
- Consistent development environment cho tất cả developers
- Dễ dàng test locally với production-like setup
- Fast iteration cycle với hot reload

**Gợi ý hình ảnh:**
- Docker multi-stage build diagram
- Docker Compose service dependencies graph
- Container layers visualization

---

### 3.3. Điều phối container với Kubernetes

**Kubernetes K3s**

Project sử dụng K3s - một lightweight distribution của Kubernetes, phù hợp cho resource-constrained environments và edge computing.

**Lý do chọn K3s:**
- **Lightweight:** Chỉ cần 512MB RAM cho master node, phù hợp với tài nguyên hạn chế
- **Đơn giản:** Single binary, không cần nhiều dependencies như full Kubernetes
- **Tương thích:** 100% compatible với Kubernetes API, có thể migrate sang full K8s sau
- **Nhanh:** Startup time nhanh hơn đáng kể so với full Kubernetes

**Cluster Architecture:**

**3-node cluster trên AWS EC2:**
- **Master node (1):** Chạy K3s server, quản lý cluster, lưu trữ etcd data
- **Worker nodes (2):** Chạy K3s agent, execute workloads (pods)

**Deployment process:**
1. Terraform tạo EC2 instances với proper security groups
2. Ansible playbooks tự động install K3s trên master node
3. Worker nodes được join vào cluster qua join token
4. Kubeconfig được export để quản lý cluster từ local machine

**Kustomize**

Quản lý Kubernetes manifests với Kustomize để hỗ trợ multi-environment:

**Base configuration:**
- Common manifests cho tất cả services (deployments, services, configmaps)
- Định nghĩa trong `infrastructure/kubernetes/base/`

**Environment overlays:**
- **Dev overlay:** Development-specific configurations (resource limits, replica counts)
- **Staging overlay:** Staging environment với production-like settings
- **Prod overlay:** Production configurations với high availability

**Features:**
- Image tag management qua kustomization.yaml
- Environment-specific resource limits và requests
- Namespace separation cho mỗi environment
- Patch-based customization (strategic merge patches)

**Workflow:**
```bash
# Apply dev environment
kubectl apply -k infrastructure/kubernetes/overlays/dev

# Apply staging
kubectl apply -k infrastructure/kubernetes/overlays/staging
```

**Gợi ý hình ảnh:**
- K3s cluster architecture diagram (master + 2 workers)
- Kustomize base và overlay structure
- Pod distribution across nodes
- Network topology trong cluster

---

### 3.4. Quản lý image & Registry

**Harbor Container Registry**

Harbor được triển khai trên Kubernetes cluster để quản lý container images thay thế Docker Hub.

**Tại sao chọn Harbor:**
- **Self-hosted:** Kiểm soát hoàn toàn images, không phụ thuộc external services
- **Security features:** Image scanning, vulnerability detection, content trust
- **RBAC:** Fine-grained access control cho teams và projects
- **Replication:** Có thể replicate images giữa các Harbor instances

**Deployment:**
- Harbor được deploy trên Kubernetes cluster trong namespace `harbor`
- Sử dụng Helm chart để quản lý deployment
- Persistent volumes cho image storage
- Ingress configuration để expose Harbor UI

**Features đã triển khai:**
- **Project management:** Tạo project `eshelf` để quản lý tất cả application images
- **Image scanning:** Tự động scan images khi push để phát hiện vulnerabilities
- **Access control:** User authentication và authorization
- **Image retention policies:** Tự động xóa old images để tiết kiệm storage

**Integration với CI/CD:**
- GitHub Actions workflows push images lên Harbor sau khi build
- Image tags sử dụng commit SHA và `latest` tag
- Kubernetes deployments pull images từ Harbor registry

**Image naming convention:**
```
harbor-core.harbor.svc.cluster.local/eshelf/api-gateway:dev
harbor-core.harbor.svc.cluster.local/eshelf/auth-service:dev
```

**Gợi ý hình ảnh:**
- Harbor architecture diagram
- Image push/pull flow từ CI/CD đến Kubernetes
- Harbor UI screenshots (project view, image scanning results)

---

### 3.5. CI/CD – Tự động hóa triển khai

**GitHub Actions**

GitHub Actions là công cụ CI/CD chính của project, với hai pipeline riêng biệt cho Pull Request và Push to main.

**PR Pipeline (Pull Request):**
- **Trigger:** Khi tạo hoặc update Pull Request
- **Mục đích:** Validation và quality checks, không deploy
- **Steps:**
  - Frontend: Lint, type check, build
  - Backend services: Lint, unit tests, static analysis
  - Security scanning: Trivy filesystem scan
  - Code quality: SonarQube analysis (nếu có)
- **Output:** Artifacts và security reports, không tạo images

**Push to Main Pipeline:**
- **Trigger:** Khi merge code vào main branch
- **Mục đích:** Build, test, và deploy
- **Steps:**
  - Tất cả validation steps từ PR pipeline
  - Docker build cho các services có changes
  - Push images lên Harbor registry
  - Update Kubernetes manifests với image tags mới
  - ArgoCD tự động sync changes

**Smart Build System:**
- **Path-based filtering:** Chỉ build services có file changes
- **Code change detection:** Phân biệt code changes vs comment/whitespace changes
- **Giảm build time:** Chỉ build services thực sự thay đổi, tiết kiệm ~60% thời gian CI/CD

**Jenkins**

Jenkins được cấu hình sẵn trên Kubernetes cluster (manifests trong `infrastructure/kubernetes/jenkins/`):

- **Pipeline trên Kubernetes:** Jenkins chạy như một pod trong cluster
- **SonarQube integration:** Tích hợp với SonarQube cho code quality analysis
- **Flexible pipelines:** Có thể tạo custom pipelines cho specific workflows

**AWS CodePipeline**

CloudFormation template sẵn sàng để setup AWS CodePipeline:

- **Source stage:** Lấy code từ GitHub repository
- **Build stage:** Build Docker images và push lên ECR hoặc Harbor
- **Deploy stage:** Deploy lên Kubernetes cluster

**Lợi ích của multi-tool approach:**
- **GitHub Actions:** Fast feedback, tích hợp tốt với GitHub
- **Jenkins:** Flexible, có thể customize phức tạp
- **CodePipeline:** Native AWS integration, phù hợp cho AWS-heavy workloads

**Gợi ý hình ảnh:**
- CI/CD pipeline flow diagram (PR vs Push)
- Smart Build logic flowchart
- GitHub Actions workflow visualization
- Jenkins pipeline diagram

---

### 3.6. GitOps với ArgoCD

**Quản lý manifest Kubernetes**

ArgoCD triển khai GitOps pattern, nơi Git repository là single source of truth cho tất cả Kubernetes configurations.

**Application Definitions:**
- Mỗi service có một ArgoCD Application definition
- Applications monitor Git repository và tự động sync khi có changes
- Applications được định nghĩa trong `infrastructure/kubernetes/argocd/applications/`

**Sync Policies:**
- **Automated sync:** Tự động apply changes từ Git
- **Self-healing:** Tự động revert manual changes về Git state
- **Prune:** Tự động xóa resources không còn trong Git

**Tự động đồng bộ & triển khai**

**ArgoCD Image Updater:**

ArgoCD Image Updater tự động update image tags khi có images mới trong registry:

1. **Image detection:** Image Updater poll Harbor registry để tìm images mới
2. **Update policy:** Kiểm tra update policy (semver, regex, latest)
3. **Git write-back:** Update `kustomization.yaml` với image tag mới
4. **Auto-sync:** ArgoCD detect Git changes và tự động sync cluster

**Workflow:**
```
Developer push code → CI/CD build image → Push to Harbor
    ↓
Image Updater detect new image → Update kustomization.yaml → Commit to Git
    ↓
ArgoCD detect Git changes → Auto-sync → Deploy to cluster
```

**Lợi ích:**
- **Zero-downtime deployments:** Rolling updates tự động
- **Audit trail:** Tất cả changes được track trong Git history
- **Rollback capability:** Dễ dàng rollback về version trước qua Git
- **Team collaboration:** Multiple developers có thể review changes trước khi deploy

**Multi-environment support:**
- ArgoCD quản lý nhiều environments (dev, staging, prod) từ cùng một Git repo
- Mỗi environment có Application riêng với sync policy riêng
- Environment promotion: Dev → Staging → Prod

**Gợi ý hình ảnh:**
- GitOps workflow diagram
- ArgoCD UI screenshot (application sync status)
- Image Updater flow diagram
- Multi-environment GitOps architecture

---

### 3.7. Giám sát & Logging hệ thống

**Prometheus**

Prometheus đóng vai trò metrics collection và time-series database:

**Metrics collection:**
- **Service discovery:** Tự động discover services trong Kubernetes cluster
- **Scraping:** Poll metrics từ services qua HTTP endpoints
- **Storage:** Time-series database lưu trữ metrics với retention policy
- **Query language:** PromQL để query và aggregate metrics

**Alert rules:**
- Định nghĩa alert rules trong `infrastructure/kubernetes/monitoring/prometheus/alerts.yaml`
- Alerts cho: high CPU/memory usage, pod crashes, service downtime
- Alert rules được evaluate và gửi đến Alertmanager

**Grafana**

Grafana cung cấp visualization và dashboards:

**Dashboards:**
- **Pre-built dashboards:** Kubernetes cluster metrics, node metrics, pod metrics
- **Custom dashboards:** Service-specific dashboards cho từng microservice
- **Dashboard configuration:** Stored trong ConfigMap, version controlled

**Features:**
- **Real-time visualization:** Live updates của metrics
- **Alert notifications:** Tích hợp với Alertmanager để hiển thị alerts
- **Multi-data source:** Có thể query từ Prometheus và Loki cùng lúc

**Loki**

Loki là log aggregation system, tương tự như Prometheus nhưng cho logs:

**Log collection:**
- **Promtail:** DaemonSet chạy trên mỗi node để collect logs
- **Label-based indexing:** Logs được index theo labels (namespace, pod, container)
- **Efficient storage:** Chỉ index metadata, logs được compress và store

**Query:**
- **LogQL:** Query language tương tự PromQL nhưng cho logs
- **Integration với Grafana:** Query logs trực tiếp từ Grafana UI
- **Log correlation:** Có thể correlate logs với metrics

**Alertmanager**

Alertmanager quản lý alert routing và notifications:

**Features:**
- **Alert routing:** Route alerts đến đúng notification channels
- **Grouping:** Group related alerts để tránh spam
- **Inhibition:** Suppress alerts khi có alert quan trọng hơn
- **Notification channels:** Email, Slack, PagerDuty (có thể configure)

**Alert flow:**
```
Prometheus → Evaluate alert rules → Send to Alertmanager
    ↓
Alertmanager → Group & route → Send notifications
```

**Monitoring stack architecture:**
- Tất cả components chạy trong `monitoring` namespace
- Prometheus scrape metrics từ services và Kubernetes API
- Promtail collect logs từ all pods và send đến Loki
- Grafana query cả Prometheus và Loki để hiển thị unified view

**Gợi ý hình ảnh:**
- Monitoring stack architecture diagram
- Grafana dashboard screenshots
- Prometheus metrics visualization
- Log flow diagram (Promtail → Loki → Grafana)

---

### 3.8. Bảo mật trong quá trình triển khai

**Checkov (IaC scanning)**

Checkov được tích hợp vào CI/CD pipeline để scan Infrastructure as Code:

**Terraform scanning:**
- Scan Terraform files để tìm security misconfigurations
- Check compliance với best practices (AWS security best practices)
- Detect hardcoded secrets, overly permissive security groups
- Validate IAM policies và permissions

**CloudFormation scanning:**
- Tương tự Terraform, scan CloudFormation templates
- Detect insecure configurations trong stack definitions

**Integration:**
- Chạy trong GitHub Actions workflow
- Fail build nếu tìm thấy critical security issues
- Report kết quả scan trong PR comments

**Trivy (Container scanning)**

Trivy scan container images để phát hiện vulnerabilities:

**Image scanning:**
- Scan base images và dependencies trong Docker images
- Detect known CVEs (Common Vulnerabilities and Exposures)
- Check for outdated packages và libraries

**Multi-stage scanning:**
- **Filesystem scan:** Scan code và dependencies trong CI pipeline
- **Image scan:** Scan built Docker images trước khi push
- **Harbor integration:** Harbor tự động scan images khi push

**Severity levels:**
- Critical và High severity vulnerabilities sẽ fail build
- Medium và Low được report nhưng không block deployment

**SonarQube (Code quality & security)**

SonarQube cung cấp static code analysis:

**Code quality:**
- Detect code smells, bugs, và technical debt
- Code coverage analysis
- Duplicate code detection
- Code complexity metrics

**Security analysis:**
- Detect security vulnerabilities trong code
- OWASP Top 10 coverage
- Injection attacks detection (SQL injection, XSS, etc.)
- Insecure cryptography usage

**Integration:**
- **GitHub Actions:** SonarQube analysis trong PR pipeline
- **Jenkins:** SonarQube plugin trong Jenkins pipeline
- **Quality gates:** Fail build nếu code quality không đạt threshold

**Security best practices trong deployment:**

**Container security:**
- Non-root users trong containers
- Minimal base images (Alpine, distroless)
- Regular image updates và vulnerability scanning
- Read-only filesystems khi có thể

**Network security:**
- VPC với public/private subnets isolation
- Security groups với least privilege principle
- Network policies trong Kubernetes để restrict pod-to-pod communication

**Secrets management:**
- Kubernetes Secrets cho sensitive data
- Environment variables cho non-sensitive configs
- .gitignore để tránh commit secrets
- Future: AWS Secrets Manager integration

**RBAC:**
- Kubernetes RBAC để control access đến cluster resources
- Service accounts với minimal permissions
- IAM roles cho AWS resources với least privilege

**Gợi ý hình ảnh:**
- Security scanning pipeline diagram
- Trivy scan results visualization
- SonarQube quality gate dashboard
- Security layers diagram (defense in depth)

---

## Slide 6: Infrastructure as Code

**Terraform:**
- VPC với public/private subnets
- Security Groups
- EC2 instances cho K3s cluster
- 3-node cluster: 1 master + 2 workers
- Internet Gateway, NAT Gateway

**CloudFormation:**
- CodePipeline setup
- EC2 stack templates

**Ansible:**
- K3s cluster setup
- Configuration management
- Automated deployment

**Benefits:**
- Version control cho infrastructure
- Reproducible deployments
- Environment consistency

---

## Slide 7: CI/CD Pipeline

**GitHub Actions:**

**PR Pipeline:**
- Trigger: Pull Request
- Steps: Lint, test, security scan
- Không deploy

**Push to Main Pipeline:**
- Trigger: Merge vào main
- Steps: Build images, push to Harbor, deploy
- Smart Build: Chỉ build services có changes

**Jenkins:**
- Pipeline trên Kubernetes
- SonarQube integration

**AWS CodePipeline:**
- Automated deployment pipeline

**Benefits:**
- Fast feedback
- Automated testing
- Security scanning
- Reduced manual work

---

## Slide 8: Containerization

**Docker:**
- Multi-stage builds
- Non-root users
- Health checks
- Minimal base images

**Docker Compose:**
- Local development
- Service dependencies
- Automatic migrations

**Kubernetes:**
- Production deployment
- Resource management
- Auto-scaling (future)

**Benefits:**
- Consistent environments
- Easy deployment
- Resource efficiency

---

## Slide 9: Kubernetes Deployment

**K3s Cluster:**
- Lightweight Kubernetes
- Deploy trên AWS EC2
- 3 nodes: 1 master + 2 workers

**Kustomize:**
- Base configurations
- Environment overlays (dev, staging, prod)
- Image tag management

**ArgoCD:**
- GitOps deployment
- Automatic sync
- Image updater

**Harbor:**
- Container registry
- Image scanning
- Access control

---

## Slide 10: GitOps với ArgoCD

**GitOps Pattern:**
- Git repository là source of truth
- ArgoCD monitor Git và sync cluster
- All changes qua Git

**ArgoCD Features:**
- Automatic sync
- Self-healing
- Multi-environment support
- Image updater

**Workflow:**
1. Code changes → Git push
2. CI/CD build images → Push to Harbor
3. ArgoCD detect changes → Sync cluster

**Benefits:**
- Audit trail
- Rollback capability
- Team collaboration

---

## Slide 11: Monitoring Stack

**Prometheus:**
- Metrics collection
- Service discovery
- Alert rules
- Time-series database

**Grafana:**
- Dashboards
- Data visualization
- Alert notifications
- Custom dashboards per service

**Loki:**
- Log aggregation
- Label-based indexing
- Query logs qua LogQL

**Alertmanager:**
- Alert routing
- Notification channels
- Alert grouping

**Benefits:**
- Real-time visibility
- Proactive issue detection
- Performance optimization

---

## Slide 12: Security

**Container Security:**
- Trivy vulnerability scanning
- Harbor image scanning
- Non-root containers
- Minimal base images

**Secrets Management:**
- Kubernetes Secrets
- Environment variables
- .gitignore cho sensitive files

**Network Security:**
- VPC với public/private subnets
- Security Groups
- Network Policies

**Code Quality:**
- SonarQube integration
- Security scanning trong CI/CD
- Pre-deployment gates

---

## Slide 13: MLOps

**ML Service:**
- FastAPI service
- Recommendation algorithms
- Similarity search

**Model Training:**
- GitHub Actions workflow
- Model versioning
- MLflow integration (future)

**Model Deployment:**
- Kubernetes deployment
- Canary deployment (future)
- Rollback mechanism

**Benefits:**
- Automated model updates
- Version control
- A/B testing capability

---

## Slide 14: Demo Highlights

**Local Development:**
- Docker Compose setup
- Automatic database migrations
- Hot reload

**CI/CD Flow:**
- GitHub Actions workflows
- Smart Build system
- Automated deployment

**Kubernetes:**
- ArgoCD GitOps
- Service discovery
- Resource management

**Monitoring:**
- Grafana dashboards
- Prometheus metrics
- Log aggregation

---

## Slide 15: Challenges & Solutions

**Challenge 1: Service Communication**
- Problem: Service-to-service communication complexity
- Solution: API Gateway pattern, HTTP/REST

**Challenge 2: Database Management**
- Problem: Schema synchronization
- Solution: Prisma migrations, auto-build service

**Challenge 3: Deployment Complexity**
- Problem: Manual deployment errors
- Solution: GitOps với ArgoCD, automated pipelines

**Challenge 4: Resource Constraints**
- Problem: Limited cluster resources
- Solution: Resource optimization, overcommit strategy

---

## Slide 16: Best Practices

**Microservices:**
- Single responsibility principle
- Independent deployment
- API-first design
- Service boundaries

**DevOps:**
- Infrastructure as Code
- Automated testing
- Continuous deployment
- Monitoring và observability

**Security:**
- Least privilege
- Secrets management
- Regular scanning
- Defense in depth

**Code Quality:**
- Code reviews
- Automated testing
- Static analysis
- Documentation

---

## Slide 17: Future Improvements

**Service Mesh:**
- Istio hoặc Linkerd
- Advanced traffic management
- mTLS

**Event-Driven Architecture:**
- Message queues (RabbitMQ, Kafka)
- Event sourcing
- CQRS pattern

**Database per Service:**
- Complete service independence
- Eventual consistency
- Saga pattern

**Advanced Monitoring:**
- Distributed tracing (Jaeger)
- APM tools
- Real-time alerting

---

## Slide 18: Lessons Learned

**Microservices:**
- Cần planning tốt cho service boundaries
- Communication overhead
- Distributed system complexity

**CI/CD:**
- Automation là key
- Smart Build giảm thời gian CI/CD
- Security scanning sớm

**Monitoring:**
- Critical cho production
- Metrics và logs quan trọng
- Alerting cần fine-tuning

**Documentation:**
- Quan trọng cho team
- Keep documentation updated
- Clear setup instructions

---

## Slide 19: Metrics & Results

**Infrastructure:**
- 3-node K3s cluster
- 4 microservices
- 5 namespaces

**CI/CD:**
- PR pipeline: ~5 phút
- Push pipeline: ~15 phút
- Smart Build: Giảm 60% build time

**Monitoring:**
- 7 monitoring components
- Real-time dashboards
- Automated alerting

**Security:**
- Automated scanning
- Zero known vulnerabilities
- Security best practices

---

## Slide 20: Q&A

**Questions?**

**Contact:**
- GitHub: https://github.com/votrung654/EShelf
- Documentation: README.md và docs/

**Thank you!**

---

## Slide 21: Appendix - Architecture Diagrams

**System Architecture:**
- High-level overview
- Service communication
- Data flow

**Microservices:**
- Service details
- Dependencies
- Communication patterns

**CI/CD Flow:**
- Pipeline diagram
- Smart Build logic
- Deployment flow

**Kubernetes:**
- Cluster architecture
- Namespace organization
- Resource allocation

---

## Notes cho Presenter

**Slide 3:** Nhấn mạnh API Gateway pattern và service independence
**Slide 4:** Giải thích tại sao tách thành 4 services riêng biệt
**Slide 6:** Show Terraform code examples nếu có thời gian
**Slide 7:** Demo GitHub Actions workflow nếu có thể
**Slide 9:** Giải thích tại sao chọn K3s thay vì full Kubernetes
**Slide 10:** Nhấn mạnh GitOps benefits và self-healing
**Slide 11:** Show Grafana dashboard nếu có thể
**Slide 13:** Giải thích ML Service architecture và model serving
**Slide 15:** Be honest về challenges và cách giải quyết
**Slide 17:** Show roadmap và priorities

**Timing:**
- Mỗi slide: 1-2 phút
- Demo slides: 3-5 phút
- Q&A: 5-10 phút
- Tổng: 20-25 phút

