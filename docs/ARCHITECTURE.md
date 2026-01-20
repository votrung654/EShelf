# Kiến trúc eShelf

## Tổng quan

eShelf là nền tảng quản lý sách điện tử dựa trên microservices với kiến trúc sau:

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend (React)                      │
│                    http://localhost:5173                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    API Gateway (Express)                     │
│                    http://localhost:3000                    │
└───────┬───────────┬───────────┬───────────┬────────────────┘
        │           │           │           │
        ▼           ▼           ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│   Auth   │ │   Book   │ │   User   │ │    ML     │
│ Service  │ │ Service  │ │ Service  │ │ Service   │
│  :3001   │ │  :3002   │ │  :3003   │ │  :8000    │
└────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
     │           │           │           │
     └───────────┴───────────┴───────────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
┌──────────────┐  ┌──────────────┐
│  PostgreSQL  │  │    Redis     │
│    :5432     │  │    :6379     │
└──────────────┘  └──────────────┘
```

## Kiến trúc Hạ tầng

### Hạ tầng AWS (Terraform/CloudFormation)

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────▼───────┐
                    │  Internet GW   │
                    └───────┬───────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                         │
┌───────▼────────┐                    ┌─────────▼────────┐
│  Public Subnet │                    │  Private Subnet  │
│                │                    │                  │
│ ┌────────────┐ │                    │ ┌──────────────┐ │
│ │  Bastion  │ │                    │ │ K3s Master   │ │
│ │   Host    │ │                    │ │              │ │
│ └────────────┘ │                    │ └──────────────┘ │
│                │                    │                  │
│                │                    │ ┌──────────────┐ │
│                │                    │ │ K3s Worker 1 │ │
│                │                    │ └──────────────┘ │
│                │                    │                  │
│                │                    │ ┌──────────────┐ │
│                │                    │ │ K3s Worker 2 │ │
│                │                    │ └──────────────┘ │
└────────────────┘                    └─────────────────┘
```

### Kiến trúc Kubernetes

```
┌─────────────────────────────────────────────────────────────┐
│                    K3s Cluster (3 nodes)                     │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Master     │    │   Worker 1   │    │   Worker 2    │  │
│  │              │    │              │    │               │  │
│  │ - API Server │    │ - Pods       │    │ - Pods        │  │
│  │ - etcd       │    │ - Services   │    │ - Services    │  │
│  │ - Scheduler  │    │              │    │               │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                              │
│  Namespaces:                                                 │
│  - eshelf-prod: Application services                        │
│  - monitoring: Prometheus, Grafana, Loki                    │
│  - argocd: GitOps deployment                                │
│  - harbor: Container registry                               │
│  - mlops: MLflow, model serving                             │
└─────────────────────────────────────────────────────────────┘
```

## Kiến trúc CI/CD

### GitHub Actions Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│                                                              │
│  Push/PR ──► CI Pipeline ──► Build ──► Test ──► Security  │
│     │                                                         │
│     └──► Smart Build (only changed services)                │
│                                                              │
│  Push to main ──► CD Pipeline ──► Build Image ──► Push     │
│                      │                                        │
│                      └──► Deploy to K8s ──► ArgoCD Sync     │
└─────────────────────────────────────────────────────────────┘
```

### AWS CodePipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    CodePipeline                              │
│                                                              │
│  Source ──► Build ──► Deploy                                │
│    │         │         │                                     │
│    │         │         └──► Kubernetes                      │
│    │         │                                               │
│    │         └──► Docker Build ──► ECR/Harbor              │
│    │                                                         │
│    └──► GitHub Webhook                                       │
└─────────────────────────────────────────────────────────────┘
```

## Kiến trúc Monitoring

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Stack                          │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │  Prometheus  │    │   Grafana    │    │    Loki      │   │
│  │              │    │              │    │              │   │
│  │ - Metrics    │    │ - Dashboards │    │ - Logs      │   │
│  │ - Alerts     │    │ - Visualization│  │ - Aggregation│   │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘   │
│         │                    │                    │           │
│         └────────────────────┴────────────────────┘           │
│                            │                                 │
│                    ┌───────▼───────┐                         │
│                    │  Promtail     │                         │
│                    │  (DaemonSet)  │                         │
│                    └───────┬───────┘                         │
│                            │                                 │
│                    ┌───────▼───────┐                         │
│                    │  Alertmanager │                         │
│                    │  (Notifications)                        │
│                    └────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

## Kiến trúc MLOps

```
┌─────────────────────────────────────────────────────────────┐
│                    MLOps Pipeline                            │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │   Training   │    │   MLflow     │    │  Deployment │   │
│  │              │    │              │    │             │   │
│  │ - GitHub     │    │ - Tracking   │    │ - Canary    │   │
│  │   Actions    │    │ - Registry   │    │ - Rollback  │   │
│  │ - Model      │    │ - Artifacts  │    │ - A/B Test  │   │
│  │   Training   │    │              │    │             │   │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘   │
│         │                    │                    │           │
│         └────────────────────┴────────────────────┘           │
│                            │                                 │
│                    ┌───────▼───────┐                         │
│                    │  ML Service   │                         │
│                    │  (FastAPI)    │                         │
│                    │  - Recommender│                         │
│                    │  - Similarity │                         │
│                    │  - Reading    │                         │
│                    │    Time       │                         │
│                    └────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

## Kiến trúc Bảo mật

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                           │
│                                                              │
│  1. Network Security                                         │
│     - VPC với public/private subnets                       │
│     - Security groups (firewall rules)                      │
│     - NAT Gateway cho outbound traffic                      │
│                                                              │
│  2. Application Security                                     │
│     - JWT authentication                                     │
│     - HTTPS/TLS encryption                                  │
│     - Input validation                                      │
│                                                              │
│  3. Container Security                                       │
│     - Trivy vulnerability scanning                          │
│     - Harbor image scanning                                 │
│     - Non-root containers                                   │
│                                                              │
│  4. Infrastructure Security                                  │
│     - Terraform/CloudFormation (IaC)                        │
│     - Secrets management (AWS Secrets Manager)              │
│     - RBAC trong Kubernetes                                 │
└─────────────────────────────────────────────────────────────┘
```

## Luồng Dữ liệu

### Luồng User Request

```
User → Frontend → API Gateway → Service → Database
                    │
                    └──► Redis (cache)
```

### Luồng CI/CD

```
Code Push → GitHub Actions → Build → Test → Security Scan
                                    │
                                    └──► Docker Build → Push to Registry
                                                          │
                                                          └──► ArgoCD → K8s
```

### Luồng Monitoring

```
Application → Prometheus (metrics)
           → Promtail → Loki (logs)
           → Alertmanager (alerts)
```

## Technology Stack

### Frontend
- React 18
- Vite
- Tailwind CSS
- Axios

### Backend
- Node.js 20
- Express.js
- Prisma ORM
- PostgreSQL
- Redis

### ML/AI
- Python 3.11
- FastAPI
- scikit-learn
- MLflow

### Infrastructure
- Kubernetes (K3s)
- Docker
- Terraform
- CloudFormation
- Ansible

### CI/CD
- GitHub Actions
- AWS CodePipeline
- ArgoCD
- Harbor

### Monitoring
- Prometheus
- Grafana
- Loki
- Alertmanager
