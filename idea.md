# MangaVerse - Manga Reading Platform

<p align="center">
  <img src="./docs/images/banner.png" alt="MangaVerse Banner" width="800"/>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#devops-pipeline">DevOps Pipeline</a> •
  <a href="#mlops">MLOps</a>
</p>

---

## 📖 Giới thiệu

**MangaVerse** là nền tảng đọc truyện tranh hiện đại với đầy đủ chức năng, được xây dựng theo kiến trúc microservices và áp dụng các best practices của DevOps/MLOps trong môi trường enterprise.

> 🎓 **Đồ án môn học**: DevOps & MLOps  
> 👥 **Nhóm**: [Tên nhóm]  
> 🏫 **Trường**: [Tên trường]

---

## ✅ Tiến độ dự án

### Phase 1: Foundation (Tuần 1-2) - Lab 1
- [ ] Setup AWS Infrastructure với Terraform
- [ ] Setup AWS Infrastructure với CloudFormation
- [ ] VPC, Subnets, Security Groups, NAT Gateway
- [ ] EC2 instances (Public/Private)
- [ ] Viết test cases cho infrastructure

### Phase 2: CI/CD Pipeline (Tuần 3-4) - Lab 2
- [ ] GitHub Actions cho Terraform + Checkov
- [ ] AWS CodePipeline + CodeBuild + cfn-lint + Taskcat
- [ ] Jenkins pipeline cho microservices
- [ ] SonarQube integration
- [ ] Container scanning (Trivy)

### Phase 3: Application Development (Tuần 5-8)
- [ ] Frontend development (Next.js)
- [ ] Backend microservices (NestJS)
- [ ] Database setup (PostgreSQL + Redis + Elasticsearch)
- [ ] ML model development

### Phase 4: Advanced DevOps (Tuần 9-12)
- [ ] Kubernetes deployment (EKS)
- [ ] GitOps với ArgoCD
- [ ] Observability stack (Prometheus + Grafana + Loki)
- [ ] MLOps pipeline

### Phase 5: Production Ready (Tuần 13-15)
- [ ] Blue/Green deployment
- [ ] Security hardening
- [ ] Performance optimization
- [ ] Documentation

---

## 🏗️ Architecture

### System Architecture
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (VPC)                                      │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      Public Subnet                                      │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │ │
│  │  │   Route 53   │  │     ALB      │  │   Bastion    │                  │ │
│  │  │   (DNS)      │  │ (Load Bal.)  │  │    Host      │                  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                         │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      Private Subnet                                     │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │ │
│  │  │                    EKS Cluster                                   │   │ │
│  │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │   │ │
│  │  │  │Frontend │ │  User   │ │ Manga   │ │ Comment │ │   ML    │   │   │ │
│  │  │  │ Service │ │ Service │ │ Service │ │ Service │ │ Service │   │   │ │
│  │  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘   │   │ │
│  │  └─────────────────────────────────────────────────────────────────┘   │ │
│  │                                                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │ │
│  │  │  PostgreSQL  │  │    Redis     │  │Elasticsearch │                  │ │
│  │  │    (RDS)     │  │(ElastiCache) │  │  (OpenSearch)│                  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                  │ │
│  │                                                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐                                    │ │
│  │  │   S3 Bucket  │  │     ECR      │                                    │ │
│  │  │  (Storage)   │  │  (Registry)  │                                    │ │
│  │  └──────────────┘  └──────────────┘                                    │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Microservices Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway (Kong/Nginx)                    │
└─────────────────────────────────────────────────────────────────┘
           │              │              │              │
           ▼              ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
    │   User   │   │  Manga   │   │ Chapter  │   │ Comment  │
    │ Service  │   │ Service  │   │ Service  │   │ Service  │
    │ (NestJS) │   │ (NestJS) │   │ (NestJS) │   │ (NestJS) │
    └──────────┘   └──────────┘   └──────────┘   └──────────┘
           │              │              │              │
           ▼              ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
    │PostgreSQL│   │PostgreSQL│   │ S3/Minio │   │PostgreSQL│
    │  + Redis │   │  + Redis │   │  + Redis │   │  + Redis │
    └──────────┘   └──────────┘   └──────────┘   └──────────┘

    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │  Search  │   │    ML    │   │  Notify  │
    │ Service  │   │ Service  │   │ Service  │
    │ (NestJS) │   │ (FastAPI)│   │ (NestJS) │
    └──────────┘   └──────────┘   └──────────┘
           │              │              │
           ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │Elastics. │   │  MLflow  │   │  Redis   │
    │          │   │ + S3     │   │  + SQS   │
    └──────────┘   └──────────┘   └──────────┘
```

---

## 🛠️ Tech Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| Next.js 14 | React framework với App Router |
| TypeScript | Type safety |
| TailwindCSS | Styling |
| Shadcn/UI | Component library |
| React Query | Data fetching & caching |
| Zustand | State management |
| React Hook Form | Form handling |
| Zod | Schema validation |

### Backend (Microservices)
| Technology | Purpose |
|------------|---------|
| NestJS | Node.js framework |
| FastAPI | Python framework (ML Service) |
| TypeScript/Python | Languages |
| Prisma | ORM |
| GraphQL | API (optional) |
| gRPC | Inter-service communication |
| Bull | Job queue |

### Database & Storage
| Technology | Purpose |
|------------|---------|
| PostgreSQL | Primary database |
| Redis | Caching & session |
| Elasticsearch | Full-text search |
| MinIO/S3 | Object storage (images) |
| MongoDB | ML metadata (optional) |

### DevOps
| Technology | Purpose |
|------------|---------|
| Terraform | Infrastructure as Code |
| CloudFormation | AWS IaC (alternative) |
| Docker | Containerization |
| Kubernetes (EKS) | Container orchestration |
| Helm | Kubernetes package manager |
| ArgoCD | GitOps continuous delivery |
| GitHub Actions | CI/CD |
| Jenkins | CI/CD (enterprise) |
| AWS CodePipeline | AWS native CI/CD |

### Security & Quality
| Technology | Purpose |
|------------|---------|
| Checkov | IaC security scanning |
| Trivy | Container vulnerability scanning |
| SonarQube | Code quality analysis |
| Snyk | Dependency scanning |
| OWASP ZAP | Security testing |
| cfn-lint | CloudFormation linting |
| Taskcat | CloudFormation testing |

### Observability
| Technology | Purpose |
|------------|---------|
| Prometheus | Metrics collection |
| Grafana | Visualization & dashboards |
| Loki | Log aggregation |
| Jaeger | Distributed tracing |
| Alertmanager | Alert management |
| AWS CloudWatch | AWS native monitoring |

### MLOps
| Technology | Purpose |
|------------|---------|
| MLflow | Model registry & tracking |
| DVC | Data version control |
| Kubeflow | ML pipelines (optional) |
| Evidently | Model monitoring & drift detection |
| BentoML | Model serving |

---

## 🎯 Features

### 👤 User Service
- [ ] Đăng ký/Đăng nhập (Email, Google, Facebook)
- [ ] JWT Authentication + Refresh Token
- [ ] OAuth 2.0 integration
- [ ] Quản lý profile
- [ ] Avatar upload
- [ ] Password reset
- [ ] Email verification
- [ ] Two-factor authentication (2FA)
- [ ] User roles & permissions (RBAC)
- [ ] Activity logging

### 📚 Manga Service
- [ ] CRUD manga
- [ ] Manga categories/genres
- [ ] Manga status (ongoing, completed, hiatus)
- [ ] Cover image management
- [ ] Manga metadata (author, artist, year)
- [ ] Alternative titles
- [ ] Related manga
- [ ] Manga statistics (views, ratings)

### 📖 Chapter Service
- [ ] CRUD chapters
- [ ] Image upload & optimization
- [ ] Reading progress tracking
- [ ] Chapter ordering
- [ ] Scanlation group credits
- [ ] Multi-language support
- [ ] Chapter scheduling (publish later)

### 💬 Comment Service
- [ ] Comments on manga/chapter
- [ ] Nested replies
- [ ] Like/dislike
- [ ] Report system
- [ ] Mention users
- [ ] Rich text formatting
- [ ] Comment moderation

### 🔖 Bookmark Service
- [ ] Follow manga
- [ ] Reading list
- [ ] Custom lists
- [ ] Reading history
- [ ] Continue reading
- [ ] Import/export lists

### 🔔 Notification Service
- [ ] New chapter notifications
- [ ] Comment replies
- [ ] System announcements
- [ ] Email notifications
- [ ] Push notifications (Web Push)
- [ ] Notification preferences

### 🔍 Search Service
- [ ] Full-text search (Elasticsearch)
- [ ] Advanced filters
- [ ] Search suggestions
- [ ] Search history
- [ ] Trending searches
- [ ] Similar manga

### 🤖 ML Service (MLOps)
- [ ] **Recommendation System**: Gợi ý manga dựa trên lịch sử đọc
- [ ] **Content-based Filtering**: Gợi ý dựa trên genre, tags
- [ ] **Collaborative Filtering**: Gợi ý dựa trên users tương tự
- [ ] **Image Classification**: Tự động gán tags cho manga covers
- [ ] **Sentiment Analysis**: Phân tích cảm xúc comments
- [ ] **Spam Detection**: Phát hiện spam comments
- [ ] **OCR**: Trích xuất text từ manga pages
- [ ] **Image Quality Assessment**: Đánh giá chất lượng ảnh upload

### 📊 Analytics Service
- [ ] User analytics
- [ ] Manga popularity tracking
- [ ] Reading statistics
- [ ] A/B testing
- [ ] Real-time dashboards

### 🛡️ Admin Panel
- [ ] User management
- [ ] Content moderation
- [ ] System configuration
- [ ] Analytics dashboard
- [ ] Audit logs
- [ ] Bulk operations

---

## 🚀 DevOps Pipeline

### Complete CI/CD Pipeline
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DEVELOPMENT                                       │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐                   │
│  │  Code   │───▶│  Commit │───▶│  Push   │───▶│   PR    │                   │
│  │ Changes │    │  Local  │    │ Branch  │    │ Created │                   │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PR CI CHECKS (GitHub Actions)                        │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐   │
│  │  Lint   │───▶│  Unit   │───▶│  Type   │───▶│ Static  │───▶│  Build  │   │
│  │ ESLint  │    │  Test   │    │  Check  │    │Analysis │    │Artefact │   │
│  │Prettier │    │  Jest   │    │   TSC   │    │SonarQube│    │         │   │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    IMAGE BUILD & SCAN (GitHub Actions/Jenkins)               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │ Multi-stage │───▶│  Container  │───▶│  Security   │───▶│   Push to   │  │
│  │Docker Build │    │ Scan Trivy  │    │ Scan Snyk   │    │   ECR/GCR   │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE AS CODE (Terraform)                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │  Terraform  │───▶│   Checkov   │───▶│  Terraform  │───▶│  Terraform  │  │
│  │    Init     │    │   Scan      │    │    Plan     │    │    Apply    │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                                                                              │
│  Resources: VPC, EKS, RDS, ElastiCache, S3, ECR, IAM, ALB, Route53          │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CONFIG MANAGEMENT (Helm/Kustomize)                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                      │
│  │    Helm     │───▶│  Kustomize  │───▶│   ArgoCD    │                      │
│  │   Charts    │    │  Overlays   │    │    Sync     │                      │
│  └─────────────┘    └─────────────┘    └─────────────┘                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DEPLOY STAGING                                       │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Deploy    │───▶│Integration  │───▶│    E2E      │───▶│Performance  │  │
│  │   to K8s    │    │   Tests     │    │   Tests     │    │   Tests     │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DEPLOY PRODUCTION                                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Manual    │───▶│ Blue/Green  │───▶│   Smoke     │───▶│  Canary     │  │
│  │  Approval   │    │   Deploy    │    │   Tests     │    │  Analysis   │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OBSERVABILITY                                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │ Prometheus  │    │   Grafana   │    │    Loki     │    │   Jaeger    │  │
│  │  Metrics    │    │ Dashboards  │    │    Logs     │    │   Traces    │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                              │                                               │
│                              ▼                                               │
│                      ┌─────────────┐                                        │
│                      │Alertmanager │                                        │
│                      │   Alerts    │                                        │
│                      └─────────────┘                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ROLLBACK & AUDIT                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                      │
│  │  Automatic  │    │   Audit     │    │  Retention  │                      │
│  │  Rollback   │    │    Logs     │    │   Policy    │                      │
│  └─────────────┘    └─────────────┘    └─────────────┘                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Pipeline Details

#### 1. PR CI Checks
```yaml
# .github/workflows/pr-checks.yml
- Linting: ESLint, Prettier, Stylelint
- Unit Tests: Jest with coverage > 80%
- Type Check: TypeScript strict mode
- Static Analysis: SonarQube quality gate
- Build: Next.js production build
- Bundle Analysis: Size limit checks
```

#### 2. Image Build & Scan
```yaml
# .github/workflows/docker-build.yml
- Multi-stage Docker build (minimize image size)
- Trivy: Container vulnerability scan (CRITICAL, HIGH)
- Snyk: Dependency vulnerability scan
- Push to Amazon ECR with semantic versioning
```

#### 3. Infrastructure as Code
```yaml
# .github/workflows/terraform.yml
- Terraform fmt & validate
- Checkov: IaC security compliance
- Terraform plan (PR comment)
- Terraform apply (on merge)
- State management: S3 + DynamoDB locking
```

#### 4. GitOps with ArgoCD
```yaml
# Automated sync from infra repo
- Application manifests in separate repo
- ArgoCD watches for changes
- Automatic sync to staging
- Manual sync to production
- Rollback on failed health checks
```

---

## 🤖 MLOps Pipeline

### ML Pipeline Architecture
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATA PIPELINE                                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │    Data     │───▶│    Data     │───▶│   Feature   │───▶│   Feature   │  │
│  │  Ingestion  │    │  Validation │    │ Engineering │    │    Store    │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TRAINING PIPELINE                                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Model     │───▶│   Model     │───▶│   Model     │───▶│   Model     │  │
│  │  Training   │    │ Evaluation  │    │ Validation  │    │  Registry   │  │
│  │             │    │             │    │             │    │  (MLflow)   │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DEPLOYMENT PIPELINE                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Model     │───▶│   Canary    │───▶│   A/B       │───▶│   Full      │  │
│  │  Packaging  │    │   Deploy    │    │   Testing   │    │  Rollout    │  │
│  │  (BentoML)  │    │             │    │             │    │             │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MONITORING                                           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Model     │    │    Data     │    │  Prediction │    │   Auto      │  │
│  │Performance  │    │   Drift     │    │  Monitoring │    │  Retrain    │  │
│  │             │    │ (Evidently) │    │             │    │  Trigger    │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### ML Models

#### 1. Recommendation System
```python
# Collaborative Filtering + Content-based Hybrid
- Input: User reading history, ratings, manga metadata
- Output: Top-N manga recommendations
- Metrics: Precision@K, Recall@K, NDCG
- Retrain: Weekly or on significant drift
```

#### 2. Image Classification
```python
# CNN-based genre/tag classifier
- Input: Manga cover images
- Output: Genre probabilities, tags
- Model: ResNet50 / EfficientNet fine-tuned
- Metrics: Accuracy, F1-score
```

#### 3. Sentiment Analysis
```python
# Transformer-based comment classifier
- Input: User comments
- Output: Positive/Negative/Neutral
- Model: PhoBERT (Vietnamese) / BERT
- Use: Content moderation, analytics
```

#### 4. Spam Detection
```python
# Binary classifier for spam comments
- Input: Comment text + metadata
- Output: Spam probability
- Model: Gradient Boosting + Text features
- Auto-action: Flag or delete
```

---

## 📁 Project Structure

```
mangaverse/
├── .github/
│   └── workflows/
│       ├── pr-checks.yml
│       ├── docker-build.yml
│       ├── terraform.yml
│       ├── deploy-staging.yml
│       └── deploy-prod.yml
├── apps/
│   ├── web/                      # Next.js Frontend
│   │   ├── src/
│   │   │   ├── app/              # App Router
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── lib/
│   │   │   └── styles/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── api-gateway/              # Kong/Nginx config
│   └── admin/                    # Admin Panel (Next.js)
├── services/
│   ├── user-service/             # NestJS
│   ├── manga-service/            # NestJS
│   ├── chapter-service/          # NestJS
│   ├── comment-service/          # NestJS
│   ├── search-service/           # NestJS + Elasticsearch
│   ├── notification-service/     # NestJS
│   └── ml-service/               # FastAPI + ML models
├── infrastructure/
│   ├── terraform/
│   │   ├── modules/
│   │   │   ├── vpc/
│   │   │   ├── eks/
│   │   │   ├── rds/
│   │   │   ├── elasticache/
│   │   │   ├── s3/
│   │   │   └── ecr/
│   │   ├── environments/
│   │   │   ├── dev/
│   │   │   ├── staging/
│   │   │   └── prod/
│   │   └── main.tf
│   ├── cloudformation/
│   │   ├── templates/
│   │   └── stacks/
│   └── ansible/
│       ├── playbooks/
│       └── roles/
├── kubernetes/
│   ├── base/
│   │   ├── deployments/
│   │   ├── services/
│   │   ├── configmaps/
│   │   └── secrets/
│   ├── overlays/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── helm/
│       ├── mangaverse/
│       └── observability/
├── ml/
│   ├── notebooks/
│   ├── pipelines/
│   ├── models/
│   │   ├── recommendation/
│   │   ├── image-classification/
│   │   └── sentiment/
│   ├── mlflow/
│   └── dvc/
├── observability/
│   ├── prometheus/
│   ├── grafana/
│   │   └── dashboards/
│   ├── loki/
│   └── alertmanager/
├── scripts/
│   ├── setup.sh
│   ├── deploy.sh
│   └── rollback.sh
├── docs/
│   ├── architecture/
│   ├── api/
│   ├── deployment/
│   └── runbooks/
├── docker-compose.yml            # Local development
├── docker-compose.prod.yml
├── Makefile
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- Node.js >= 18
- Docker & Docker Compose
- kubectl
- Terraform >= 1.5
- AWS CLI configured
- Helm 3

### Local Development

```bash
# Clone repository
git clone https://github.com/[your-org]/mangaverse.git
cd mangaverse

# Copy environment files
cp .env.example .env.local

# Start all services with Docker Compose
docker-compose up -d

# Or start specific services
docker-compose up -d postgres redis elasticsearch

# Install dependencies
npm install

# Run database migrations
npm run db:migrate

# Start development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

### Deploy to AWS (Terraform)

```bash
# Navigate to terraform directory
cd infrastructure/terraform/environments/dev

# Initialize Terraform
terraform init

# Plan infrastructure
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

### Deploy to Kubernetes

```bash
# Configure kubectl
aws eks update-kubeconfig --name mangaverse-cluster --region ap-southeast-1

# Deploy with Helm
helm upgrade --install mangaverse ./kubernetes/helm/mangaverse \
  -f ./kubernetes/helm/mangaverse/values-staging.yaml \
  -n mangaverse --create-namespace

# Or with Kustomize
kubectl apply -k kubernetes/overlays/staging
```

---

## 📊 Monitoring & Dashboards

### Grafana Dashboards
- **Application Dashboard**: Request rate, latency, errors
- **Kubernetes Dashboard**: Pod status, resource usage
- **Database Dashboard**: Connections, queries, slow logs
- **ML Dashboard**: Model predictions, accuracy, drift

### Alerts
- High error rate (> 1%)
- Latency P99 > 2s
- Pod crashes
- Database connection exhaustion
- Model accuracy degradation

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Architecture Decision Records](./docs/adr/) | Design decisions |
| [API Documentation](./docs/api/) | OpenAPI specs |
| [Deployment Guide](./docs/deployment/) | Step-by-step deployment |
| [Runbooks](./docs/runbooks/) | Incident response |
| [Contributing Guide](./CONTRIBUTING.md) | How to contribute |

---

## 👥 Team

| Member | Role | Responsibilities |
|--------|------|------------------|
| [Tên 1] | Team Lead / DevOps | Infrastructure, CI/CD |
| [Tên 2] | Backend Developer | Microservices, API |
| [Tên 3] | Frontend Developer | Web application |
| [Tên 4] | ML Engineer | ML models, MLOps |
| [Tên 5] | QA Engineer | Testing, Security |

---

## 📄 License

This project is for educational purposes only.

---

## 🙏 Acknowledgments

- Inspired by [TruyenDex](https://github.com/zennomi/truyendex)
- [MangaDex](https://mangadex.org/) for API reference
- All open-source tools and libraries used in this project

----------------------------------------------------------------------------
## Học được gì từ TruyenDex

### ✅ Có thể tham khảo
| Aspect | Học được |
|--------|----------|
| **Next.js App Router** | Cấu trúc app, routing, layouts |
| **TypeScript** | Type definitions, interfaces |
| **UI Components** | TailwindCSS, component patterns |
| **API Integration** | Cách gọi external API, error handling |
| **Environment Config** | .env.example pattern |

### ❌ Không có trong TruyenDex
- Backend/Microservices
- Database schema
- Docker/Kubernetes
- CI/CD pipelines
- Infrastructure as Code
- Monitoring/Observability

---

## 🌟 Repos nổi tiếng nên tham khảo

### 1. **Microservices Reference**

| Repo | Tech Stack | Học được |
|------|------------|----------|
| [microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) | Go, Python, gRPC, K8s | Microservices mẫu của Google, Kubernetes manifests, Skaffold |
| [eShopOnContainers](https://github.com/dotnet-architecture/eShopOnContainers) | .NET, Docker, K8s | Enterprise microservices patterns, DDD |
| [spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices) | Java Spring | API Gateway, Config Server, Service Discovery |
| [nestjs-realworld-example-app](https://github.com/lujakob/nestjs-realworld-example-app) | NestJS, TypeScript | Clean architecture với NestJS |

### 2. **DevOps/Infrastructure**

| Repo | Focus | Học được |
|------|-------|----------|
| [terraform-aws-modules](https://github.com/terraform-aws-modules) | Terraform | Best practices cho AWS modules |
| [kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way) | Kubernetes | Hiểu sâu K8s từ gốc |
| [gitops-argocd](https://github.com/argoproj/argocd-example-apps) | ArgoCD | GitOps patterns |
| [awesome-cicd](https://github.com/cicdops/awesome-cicd) | CI/CD | Collection các tools và patterns |

### 3. **MLOps**

| Repo | Focus | Học được |
|------|-------|----------|
| [mlops-zoomcamp](https://github.com/DataTalksClub/mlops-zoomcamp) | MLOps | Course đầy đủ về MLOps |
| [made-with-ml](https://github.com/GokuMohandas/Made-With-ML) | MLOps | End-to-end ML pipeline |
| [mlflow](https://github.com/mlflow/mlflow/tree/master/examples) | MLflow | Model tracking, registry |

### 4. **Full-Stack với Ops** ⭐ Recommended

| Repo | Description |
|------|-------------|
| [**realworld**](https://github.com/gothinkster/realworld) | "Medium.com clone" - Có cả FE, BE nhiều ngôn ngữ |
| [**excalidraw**](https://github.com/excalidraw/excalidraw) | React + TypeScript, có CI/CD tốt |
| [**cal.com**](https://github.com/calcom/cal.com) | Next.js, Prisma, tRPC, có Docker |
| [**immich**](https://github.com/immich-app/immich) | Photo app với microservices, K8s, ML |

---

## 🎯 Đề xuất cho bạn

### Clone và nghiên cứu theo thứ tự:

```
1. Google Microservices Demo (tuần 1-2)
   └── Học microservices patterns, K8s basics
   
2. Terraform AWS Modules (tuần 2-3)
   └── Học viết Terraform modules chuẩn
   
3. ArgoCD Example Apps (tuần 3-4)
   └── Học GitOps workflow
   
4. MLOps Zoomcamp (song song)
   └── Học MLOps từ cơ bản đến nâng cao
```

### Quick start với Google Microservices Demo:

```powershell
# Clone
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
cd microservices-demo

# Run locally with Docker
docker-compose up

# Hoặc deploy lên K8s
kubectl apply -f ./release/kubernetes-manifests.yaml
```

Repo này có sẵn:
- ✅ 11 microservices (Go, Python, Node.js, C#, Java)
- ✅ gRPC communication
- ✅ Kubernetes manifests
- ✅ Helm charts
- ✅ Terraform (GCP)
- ✅ CI/CD với Cloud Build
- ✅ Monitoring với Prometheus/Grafana
- ✅ Tracing với Jaeger

---

## 📋 Kế hoạch gợi ý

| Tuần | Việc làm |
|------|----------|
| 1-2 | Clone Google demo, chạy local, đọc hiểu code |
| 3-4 | Viết Terraform modules cho AWS (Lab 1) |
| 5-6 | Setup CI/CD với GitHub Actions + Jenkins (Lab 2) |
| 7-10 | Phát triển project riêng (FE + BE + DB) |
| 11-12 | Thêm ML service + MLOps |
| 13-15 | Hoàn thiện monitoring, security, documentation |

---------------------------------------------------------------------------
## Đánh giá Kế Hoạch eShelf

### ✅ Đáp ứng tốt

| Yêu cầu | Status | Prompts |
|---------|--------|---------|
| **Lab 1** - VPC, Subnets, IGW | ✅ | 5.1 |
| **Lab 1** - Route Tables, NAT | ✅ | 5.2 |
| **Lab 1** - EC2 Public/Private | ✅ | 5.3 |
| **Lab 1** - Security Groups | ✅ | 5.4 |
| **Lab 1** - CloudFormation | ✅ | 5.6, 5.7 |
| **Lab 1** - Test Cases | ✅ | 5.8 |
| **Lab 2** - Terraform + GitHub Actions + Checkov | ✅ | 6.1 |
| **Lab 2** - CloudFormation + CodePipeline | ✅ | 6.2 |
| **Lab 2** - Jenkins + SonarQube + K8s | ✅ | 6.3-6.5 |
| **Lab 2** - Trivy/Snyk | ✅ | 6.4 |
| **Đồ án** - Microservices | ✅ | Phase 2 |
| **Đồ án** - Kubernetes + Helm | ✅ | Phase 7 |
| **Đồ án** - GitOps ArgoCD | ✅ | 7.6 |
| **Đồ án** - Monitoring Stack | ✅ | Phase 8 |
| **Đồ án** - MLOps | ✅ | Phase 9 |

---

### ⚠️ Thiếu hoặc cần bổ sung

| Thiếu | Quan trọng | Bổ sung |
|-------|------------|---------|
| **Ansible** (Config Management) | 🔴 Cao | Thêm Phase riêng |
| **Blue/Green Deployment** chi tiết | 🔴 Cao | Thêm prompt |
| **Canary Deployment** chi tiết | 🔴 Cao | Thêm prompt |
| **E2E Tests** (Cypress/Playwright) | 🟡 Trung bình | Thêm prompt |
| **OWASP ZAP** (Security testing) | 🟡 Trung bình | Thêm vào 6.4 |
| **DVC** (Data Version Control) | 🟡 Trung bình | Thêm vào MLOps |
| **Audit Logging** | 🟡 Trung bình | Thêm prompt |
| **Secrets Management** (Vault/AWS Secrets Manager) | 🔴 Cao | Thêm prompt |
| **Database Backup/Restore** | 🟡 Trung bình | Thêm prompt |
| **Disaster Recovery** | 🟡 Trung bình | Thêm prompt |

---

## 📝 Prompts bổ sung cần thêm

````markdown
## 🎯 PHASE 5.5: CONFIG MANAGEMENT (BỔ SUNG)

### Prompt 5.9 - Ansible Server Provisioning
```
Tạo Ansible Playbooks cho eShelf:
1. infrastructure/ansible/inventory/
   - hosts.yml với groups: bastion, app_servers, db_servers
2. infrastructure/ansible/playbooks/
   - common.yml: update packages, install Docker, configure users
   - app-server.yml: deploy application, configure nginx
   - monitoring.yml: install node_exporter, promtail
3. infrastructure/ansible/roles/
   - docker/
   - nginx/
   - node-exporter/
4. Group vars và Host vars
5. Ansible Vault cho secrets
6. Integration với Terraform (dynamic inventory)
```

### Prompt 5.10 - AWS Secrets Manager Integration
```
Tạo Secrets Management cho eShelf:
1. infrastructure/terraform/modules/secrets/
2. AWS Secrets Manager resources
3. IAM policies cho EC2/EKS access
4. Rotation configuration
5. Application integration (SDK usage)
6. Kubernetes ExternalSecrets Operator setup
```

---

## 🎯 PHASE 6.5: ADVANCED CI/CD (BỔ SUNG)

### Prompt 6.8 - E2E Testing Pipeline
```
Tạo E2E Testing với Playwright:
1. frontend/e2e/
2. Test cases: login, browse books, add to favorites, reading
3. GitHub Actions integration
4. Visual regression testing
5. Test reports và screenshots on failure
6. Parallel test execution
```

### Prompt 6.9 - OWASP Security Testing
```
Tạo Security Testing Pipeline:
1. OWASP ZAP scan trong CI/CD
2. DAST (Dynamic Application Security Testing)
3. API security scan
4. Report generation
5. Fail thresholds configuration
6. Integration với Jenkins/GitHub Actions
```

---

## 🎯 PHASE 7.5: DEPLOYMENT STRATEGIES (BỔ SUNG)

### Prompt 7.7 - Blue/Green Deployment
```
Implement Blue/Green Deployment cho eShelf:
1. infrastructure/kubernetes/blue-green/
2. Service switching mechanism
3. Health check validation
4. Automated rollback
5. Traffic shifting với Ingress
6. Deployment script với kubectl
```

### Prompt 7.8 - Canary Deployment với Flagger
```
Implement Canary Deployment:
1. Flagger installation và configuration
2. Canary resource definitions
3. Metrics analysis (success rate, latency)
4. Progressive traffic shifting (10% → 50% → 100%)
5. Automated rollback on failure
6. Slack notifications
```

---

## 🎯 PHASE 8.5: AUDIT & COMPLIANCE (BỔ SUNG)

### Prompt 8.5 - Audit Logging System
```
Tạo Audit Logging cho eShelf:
1. Audit log middleware trong API Gateway
2. Log format: who, what, when, where, result
3. Store trong Elasticsearch
4. Retention policies (90 days hot, 1 year cold)
5. Grafana dashboard cho audit queries
6. Compliance reports generation
```

### Prompt 8.6 - Backup & Disaster Recovery
```
Tạo Backup Strategy cho eShelf:
1. Database backup với pg_dump (daily)
2. S3 cross-region replication
3. Elasticsearch snapshots
4. Restore procedures và runbooks
5. RTO/RPO documentation
6. Disaster recovery testing script
```

---

## 🎯 PHASE 9.5: MLOPS ADVANCED (BỔ SUNG)

### Prompt 9.5 - DVC Data Pipeline
```
Tạo DVC Pipeline cho eShelf ML:
1. DVC initialization và remote storage (S3)
2. Data versioning cho training datasets
3. dvc.yaml pipeline definition
4. Integration với CI/CD
5. Data registry và catalog
```

### Prompt 9.6 - Model A/B Testing
```
Implement Model A/B Testing:
1. Feature flags cho model selection
2. Traffic splitting configuration
3. Metrics collection per model version
4. Statistical significance testing
5. Dashboard cho A/B results
6. Automated winner selection
```
````

---

## 📚 Tham khảo thêm từ TruyenDex

| Aspect | File/Pattern | Học được |
|--------|--------------|----------|
| **Next.js App Router** | app | Cấu trúc routing, layouts |
| **API Calls** | `src/lib/` hoặc `src/services/` | Axios/fetch patterns |
| **TypeScript Types** | `types/` | Interface definitions |
| **Environment Config** | .env.example | Biến môi trường pattern |
| **Component Structure** | components | Atomic design |

---

## 🌟 Tham khảo từ Project chuyên nghiệp

### Bắt buộc clone để học:

```powershell
# 1. Google Microservices Demo - Học K8s manifests, gRPC
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git

# 2. Terraform AWS Modules - Học viết modules chuẩn
git clone https://github.com/terraform-aws-modules/terraform-aws-vpc.git

# 3. ArgoCD Example - Học GitOps patterns
git clone https://github.com/argoproj/argocd-example-apps.git
```

### Học gì từ mỗi repo:

| Repo | Copy/Học |
|------|----------|
| **microservices-demo** | `kubernetes-manifests/`, `helm-chart/`, Makefile |
| **terraform-aws-vpc** | Module structure, variables.tf, outputs.tf patterns |
| **argocd-example-apps** | Application.yaml structure, Kustomize overlays |

---

## ✅ Thứ tự thực hiện cập nhật

```
Week 1-2:   Phase 5 (Lab 1) + Prompt 5.9, 5.10
Week 3-4:   Phase 6 (Lab 2) + Prompt 6.8, 6.9
Week 5-6:   Phase 2-3 (Backend + DB)
Week 7-8:   Phase 1 (Frontend enhancements)
Week 9-10:  Phase 7 + Prompt 7.7, 7.8
Week 11-12: Phase 4 + Phase 9 + Prompt 9.5, 9.6
Week 13-14: Phase 8 + Prompt 8.5, 8.6
Week 15:    Documentation + Testing + Demo prep
```

---

## 📊 Tổng kết

| Tiêu chí | Trước bổ sung | Sau bổ sung |
|----------|---------------|-------------|
| Lab 1 | ✅ 100% | ✅ 100% |
| Lab 2 | ✅ 100% | ✅ 100% |
| Đồ án Pipeline | ⚠️ 85% | ✅ 100% |
| MLOps | ⚠️ 80% | ✅ 95% |
| Enterprise-ready | ⚠️ 75% | ✅ 95% |

**Kết luận**: Kế hoạch của bạn đã rất tốt, chỉ cần thêm **8 prompts bổ sung** ở trên là đầy đủ cho đồ án chuyên nghiệp.

-------------------------------------------------------------------
## Gợi ý Features hay cho DevOps + MLOps

### 🎯 Frontend Features có giá trị DevOps

| Feature | Giá trị DevOps | Độ khó |
|---------|---------------|--------|
| **Feature Flags Dashboard** | A/B testing, Canary deploy | 🟡 |
| **Real-time Health Status** | Observability demo | 🟢 |
| **Error Boundary + Sentry** | Error tracking | 🟢 |
| **Performance Metrics UI** | Web Vitals monitoring | 🟡 |
| **Admin Audit Logs Viewer** | Compliance, security | 🟡 |

### 🤖 AI/ML Features có giá trị MLOps

| Feature | ML Model | Giá trị MLOps | Độ khó |
|---------|----------|---------------|--------|
| **Smart Search Autocomplete** | NLP/Embedding | Model serving, latency | 🟡 |
| **"For You" Recommendations** | Collaborative Filtering | Full ML pipeline | 🟡 |
| **Similar Books** | Content-based | Batch inference | 🟢 |
| **Spam Comment Detection** | Text Classification | Real-time inference | 🟢 |
| **Auto-tagging Images** | CNN/Vision | Model versioning | 🔴 |
| **Reading Time Estimation** | Regression | Simple ML demo | 🟢 |
| **Sentiment Analysis (Reviews)** | NLP | Monitoring drift | 🟡 |

---

## 📝 Prompts bổ sung đề xuất

### Frontend - DevOps Value

````markdown
### Prompt 1.FE1 - Feature Flags Dashboard (Admin)
```
Tạo Feature Flags Dashboard cho eShelf Admin:

1. FeatureFlagsPage.jsx trong /admin/feature-flags
2. Danh sách flags với toggle on/off
3. Flag types:
   - Boolean (on/off)
   - Percentage (rollout %)
   - User segment (beta users)
4. Flag configuration:
   - Name, description
   - Environment (dev/staging/prod)
   - Rollout percentage
5. Integration với backend API
6. Audit log khi thay đổi flag

Giá trị DevOps:
- Demo Canary deployment
- Demo A/B testing infrastructure
- Demo gradual rollout
```

### Prompt 1.FE2 - System Health Dashboard (Admin)
```
Tạo System Health Dashboard cho eShelf Admin:

1. HealthDashboardPage.jsx trong /admin/health
2. Service status cards:
   - API Gateway: ✅ Healthy / ❌ Down
   - Auth Service: ✅ / ❌
   - Book Service: ✅ / ❌
   - ML Service: ✅ / ❌
   - Database: ✅ / ❌
   - Redis: ✅ / ❌
3. Real-time updates (polling 30s hoặc WebSocket)
4. Response time metrics per service
5. Error rate chart (last 24h)
6. Uptime percentage

Giá trị DevOps:
- Demo /health endpoints
- Demo Prometheus metrics visualization
- Demo alerting (nếu service down)
```

### Prompt 1.FE3 - Error Tracking Integration
```
Tích hợp Error Tracking cho eShelf:

1. Setup Sentry SDK trong Frontend
2. ErrorBoundary component với fallback UI
3. Capture errors với context:
   - User info
   - Current route
   - Browser info
4. Custom error pages (404, 500, offline)
5. Release tracking (version tag)

Giá trị DevOps:
- Demo production error monitoring
- Demo release tracking
- Demo source maps upload trong CI/CD
```
````

### AI/ML Features

````markdown
### Prompt 4.ML1 - Smart Search Autocomplete
```
Tạo Smart Search với Autocomplete cho eShelf:

Frontend:
1. SearchBar.jsx với autocomplete dropdown
2. Debounced API calls (300ms)
3. Highlight matched text
4. Recent searches (localStorage)
5. Trending searches

Backend (ML Service):
1. GET /search/autocomplete?q=
2. Embedding-based similarity (sentence-transformers)
3. Caching popular queries (Redis)
4. Fallback to simple text match

MLOps Value:
- Demo model serving latency requirements (<100ms)
- Demo caching strategy for ML
- Demo A/B testing (embedding vs simple search)
```

### Prompt 4.ML2 - "For You" Personalized Recommendations
```
Tạo Personalized Recommendations cho eShelf:

Frontend:
1. ForYouSection.jsx trên Homepage
2. Horizontal scroll của recommended books
3. "Why recommended" tooltip (optional)
4. Skeleton loading

Backend (ML Service):
1. GET /recommendations/{user_id}
2. Collaborative Filtering (user-item matrix)
3. Hybrid: CF + Content-based
4. Cold start handling (popular items)

MLOps Value:
- Demo full training pipeline
- Demo model registry (MLflow)
- Demo A/B testing models
- Demo recommendation metrics (CTR, precision)
```

### Prompt 4.ML3 - Similar Books (Content-Based)
```
Tạo Similar Books feature:

Frontend:
1. SimilarBooks.jsx trong BookDetail page
2. Grid 4-6 similar books
3. "Readers also liked" section

Backend (ML Service):
1. GET /similar/{book_id}
2. TF-IDF on book descriptions + genres
3. Cosine similarity
4. Pre-computed similarity matrix (batch job)
5. Cache results (Redis)

MLOps Value:
- Demo batch inference pipeline
- Demo scheduled retraining (weekly)
- Demo model artifact storage
```

### Prompt 4.ML4 - Spam Comment Detection
```
Tạo Spam Detection cho Comments:

Frontend:
1. Comment bị flag hiển thị warning
2. Admin queue để review flagged comments
3. User report button

Backend (ML Service):
1. POST /moderate/comment
2. Text classification model (spam/not_spam)
3. Confidence threshold (>0.8 = auto-remove)
4. Flagged queue (0.5-0.8 confidence)

MLOps Value:
- Demo real-time inference
- Demo model monitoring (accuracy over time)
- Demo human-in-the-loop feedback
- Demo model retraining với new data
```

### Prompt 4.ML5 - Reading Time Estimation
```
Tạo Reading Time Estimation cho Books:

Frontend:
1. Hiển thị "⏱️ ~45 min read" trên book card
2. Trong book detail: estimated total time
3. Per chapter estimation

Backend (ML Service):
1. Simple regression model
2. Features: page_count, word_count, genre, avg_user_time
3. Train trên historical reading data

MLOps Value:
- Demo simple ML pipeline
- Demo feature engineering
- Demo model serving
- Good starter ML task
```

### Prompt 4.ML6 - Review Sentiment Analysis
```
Tạo Sentiment Analysis cho Reviews:

Frontend:
1. Sentiment indicator bên cạnh review
   - 😊 Positive (green)
   - 😐 Neutral (gray)
   - 😞 Negative (red)
2. Overall sentiment summary cho book
3. Sentiment trend chart (Admin)

Backend (ML Service):
1. POST /analyze/sentiment
2. Pre-trained model (PhoBERT for Vietnamese hoặc BERT)
3. Confidence scores

MLOps Value:
- Demo pre-trained model deployment
- Demo sentiment drift monitoring
- Demo batch analysis for existing reviews
```
````

---

## 🏢 Tham khảo từ các công ty lớn

| Company | Feature | Áp dụng cho eShelf |
|---------|---------|-------------------|
| **Netflix** | Recommendation + A/B | "For You" + Feature Flags |
| **Spotify** | Discover Weekly | Weekly personalized list |
| **Amazon** | "Customers also bought" | Similar Books |
| **YouTube** | Watch time prediction | Reading time estimation |
| **Twitter** | Spam detection | Comment moderation |
| **Google** | Smart autocomplete | Search suggestions |

---

## ✅ Prompts đề xuất thêm vào kế hoạch

```diff
PHASE 1: FRONTEND
  1.0   Header & Navigation
  1.1   Auth & Profile
  1.5   Admin Layout
  1.0.1 Admin Sidebar
  1.6   Admin CRUD
+ 1.FE1 Feature Flags Dashboard     ← DevOps value
+ 1.FE2 System Health Dashboard     ← DevOps value
+ 1.FE3 Error Tracking (Sentry)     ← DevOps value
  1.NEW Observability Endpoints

PHASE 4: ML/AI
  4.1   ML Service Setup
  4.2   Recommendation System
+ 4.ML1 Smart Search Autocomplete   ← MLOps value
+ 4.ML3 Similar Books               ← MLOps value (simpler)
+ 4.ML4 Spam Comment Detection      ← MLOps value
+ 4.ML5 Reading Time Estimation     ← MLOps value (starter)
```

---

## 🎯 Ưu tiên nếu thời gian hạn chế

| Ưu tiên | Feature | Lý do |
|---------|---------|-------|
| 1️⃣ | Reading Time Estimation | Đơn giản nhất, demo full ML pipeline |
| 2️⃣ | Similar Books | Content-based, không cần user data |
| 3️⃣ | Spam Detection | Real-time inference demo |
| 4️⃣ | Feature Flags Dashboard | Canary + A/B testing demo |
| 5️⃣ | Health Dashboard | Observability demo |

**Làm 2-3 ML features** là đủ impressive cho đồ án MLOps.