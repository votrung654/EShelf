# Architecture Diagram - eShelf Project

## Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKFLOW                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Git Push/PR   │
                    │   GitHub Repo  │
                    └────────┬────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
        ┌───────────────┐         ┌──────────────┐
        │  Pull Request │         │ Push to Main │
        │    Pipeline   │         │   Pipeline   │
        └───────┬───────┘         └──────┬───────┘
                │                         │
    ┌───────────┴──────────┐    ┌────────┴──────────┐
    │                      │    │                    │
    ▼                      ▼    ▼                    ▼
┌─────────┐         ┌─────────┐ ┌─────────┐   ┌─────────┐
│  Lint   │         │  Test   │ │  Build  │   │  Scan   │
└─────────┘         └─────────┘ └────┬────┘   └─────────┘
                                      │
                                      ▼
                            ┌─────────────────┐
                            │  Docker Build   │
                            │  Multi-stage    │
                            └────────┬────────┘
                                     │
                                     ▼
                            ┌─────────────────┐
                            │  Push to Harbor │
                            │   Registry      │
                            └────────┬────────┘
                                     │
                                     ▼
                            ┌─────────────────┐
                            │ Update Manifests│
                            │  (yq/kustomize) │
                            └────────┬────────┘
                                     │
                                     ▼
                            ┌─────────────────┐
                            │  Git Commit     │
                            │  (Image Tags)   │
                            └────────┬────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                         GITOPS LAYER                            │
└─────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
                            ┌─────────────────┐
                            │    ArgoCD       │
                            │  Image Updater  │
                            └────────┬────────┘
                                     │
                                     ▼
                            ┌─────────────────┐
                            │  ArgoCD Sync    │
                            │  (Git Repo)     │
                            └────────┬────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER (K3s)                      │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Master     │  │   Worker 1    │  │   Worker 2   │         │
│  │   Node       │  │               │  │              │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    NAMESPACES                             │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │   eshelf-dev │  │   monitoring │  │    harbor    │   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │ api-gateway  │  │  Prometheus  │  │  Harbor Core │   │  │
│  │  │ auth-service │  │   Grafana    │  │  Harbor Redis │   │  │
│  │  │ book-service │  │     Loki     │  │  Harbor Nginx │   │  │
│  │  │ user-service │  │ Alertmanager │  │              │   │  │
│  │  │  ml-service  │  │   Promtail   │  │              │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │    argocd    │  │    jenkins   │  │   sonarqube  │   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │ ArgoCD Server│  │ Jenkins Pod  │  │  SonarQube  │   │  │
│  │  │ Applications │  │   Pipeline   │  │   Postgres   │   │  │
│  │  │ Image Updater│  │              │  │              │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Chi Tiết Từng Layer

### 1. Source Control Layer

**GitHub Repository:**
- Main branch: Production code
- Develop branch: Development code
- Pull Requests: Code review và validation

**Triggers:**
- Pull Request: Chạy PR pipeline (test, lint, scan)
- Push to main: Chạy full pipeline (build, push, deploy)

### 2. CI/CD Pipeline Layer

**GitHub Actions Workflows:**

**PR Pipeline (pr-only.yml):**
```
PR Created → Lint → Type Check → Unit Tests → 
Static Analysis → Security Scan → Upload Artifacts
```

**Push Pipeline (smart-build.yml, ci.yml):**
```
Push to Main → Detect Changes → Build Changed Services → 
Docker Build → Security Scan → Push to Harbor → 
Update Manifests → Git Commit → ArgoCD Sync
```

**Smart Build System:**
- Path-based filtering
- Chỉ build services có file changes
- Matrix strategy cho parallel builds

### 3. Container Registry Layer

**Harbor Registry:**
- Internal service: `harbor-core.harbor.svc.cluster.local`
- Project: `eshelf`
- Images: `harbor-core.harbor.svc.cluster.local/eshelf/<service>:<tag>`
- Image scanning: Trivy integration
- Access control: User authentication

**Image Tagging:**
- Commit SHA: `harbor-core.../eshelf/api-gateway:abc123`
- Latest tag: `harbor-core.../eshelf/api-gateway:latest`
- Dev tag: `harbor-core.../eshelf/api-gateway:dev`

### 4. GitOps Layer

**ArgoCD:**
- Applications: 6 applications (api-gateway, auth-service, book-service, user-service, ml-service, monitoring)
- Sync policy: Automated với self-heal
- Source: Git repository với Kustomize overlays
- Destination: Kubernetes cluster

**ArgoCD Image Updater:**
- Monitor Harbor registry
- Detect new image tags
- Update Kustomize manifests
- Commit changes to Git
- Trigger ArgoCD sync

**Kustomize Overlays:**
```
infrastructure/kubernetes/
├── base/
│   ├── api-gateway-deployment.yaml
│   ├── auth-service-deployment.yaml
│   └── ...
└── overlays/
    ├── dev/
    │   └── kustomization.yaml (image: ...:dev)
    ├── staging/
    │   └── kustomization.yaml (image: ...:staging)
    └── prod/
        └── kustomization.yaml (image: ...:prod)
```

### 5. Kubernetes Infrastructure Layer

**K3s Cluster:**
- 1 Master node: Control plane, etcd
- 2 Worker nodes: Application pods
- Network: Flannel CNI
- Storage: Local path provisioner

**Namespaces:**
- `eshelf-dev`: Application deployments
- `monitoring`: Prometheus, Grafana, Loki
- `harbor`: Container registry
- `argocd`: GitOps controller
- `jenkins`: CI/CD server
- `sonarqube`: Code quality
- `kube-system`: System components

**Network Policies:**
- Isolation giữa namespaces
- Allow specific traffic patterns
- Deny by default

### 6. Application Layer

**Microservices:**
- API Gateway: Entry point, routing
- Auth Service: Authentication, authorization
- User Service: User management
- Book Service: Book catalog
- ML Service: Machine learning features

**Deployment Strategy:**
- Replicas: 2 cho dev, tăng dần cho staging/prod
- Health checks: Liveness và readiness probes
- Resource limits: CPU và memory
- Image pull secrets: Harbor authentication

### 7. Monitoring & Observability Layer

**Prometheus:**
- Metrics collection
- Service discovery
- Alert rules
- Scrape configs

**Grafana:**
- Dashboards
- Data sources: Prometheus, Loki
- Alerting
- Visualization

**Loki:**
- Log aggregation
- Log queries
- Integration với Grafana

**Promtail:**
- Log collection
- DaemonSet trên tất cả nodes
- Ship logs to Loki

**Alertmanager:**
- Alert routing
- Notification channels
- Alert grouping

### 8. Security & Quality Layer

**Security Scanning:**
- Trivy: Container image scanning
- CodeQL: Code security analysis
- npm audit: Dependency vulnerabilities

**Code Quality:**
- SonarQube: Code quality analysis
- ESLint: Code linting
- TypeScript: Type checking

**Infrastructure Security:**
- Network policies
- RBAC
- Secrets management
- Image pull secrets

## Data Flow

### 1. Code to Deployment Flow

```
Developer → Git Push → GitHub Actions → Build Image → 
Push to Harbor → Update Manifest → Git Commit → 
ArgoCD Detect → Sync to Cluster → Pods Running
```

### 2. Image Update Flow

```
New Image Tag in Harbor → ArgoCD Image Updater Detect → 
Update kustomization.yaml → Git Commit → 
ArgoCD Sync → Rolling Update → New Pods Running
```

### 3. Monitoring Flow

```
Pods → Prometheus Scrape → Metrics Storage → 
Grafana Query → Dashboard Display

Pods → Promtail Collect → Loki → 
Grafana Query → Log Visualization
```

### 4. Alert Flow

```
Prometheus Rule → Alert Fired → Alertmanager → 
Notification Channel → Team Notification
```

## Technology Stack

### Infrastructure
- **Cloud**: AWS EC2
- **IaC**: Terraform
- **Config Management**: Ansible
- **Kubernetes**: K3s

### CI/CD
- **CI/CD**: GitHub Actions
- **Build**: Docker, Multi-stage builds
- **Registry**: Harbor
- **GitOps**: ArgoCD

### Monitoring
- **Metrics**: Prometheus
- **Visualization**: Grafana
- **Logs**: Loki, Promtail
- **Alerts**: Alertmanager

### Security & Quality
- **Security Scan**: Trivy, CodeQL
- **Code Quality**: SonarQube
- **Linting**: ESLint
- **Type Check**: TypeScript

### Applications
- **Backend**: Node.js, Express
- **Frontend**: React
- **Database**: PostgreSQL (Prisma ORM)
- **ML**: Python, TensorFlow

## Key Features

### 1. Smart Build
- Chỉ build services có changes
- Path-based filtering
- Parallel builds

### 2. GitOps
- Declarative configuration
- Automated sync
- Self-healing
- Image auto-update

### 3. Multi-Environment
- Dev, Staging, Prod
- Environment-specific configs
- Promotion workflow

### 4. Security
- Image scanning
- Code scanning
- Network policies
- Secrets management

### 5. Observability
- Metrics collection
- Log aggregation
- Alerting
- Dashboards






