Collecting workspace information# 📋 Kế Hoạch Prompt Chi Tiết cho Dự Án eShelf

Tôi hiểu ý bạn! Dưới đây là danh sách các prompt được tổ chức theo từng giai đoạn, mỗi prompt đủ cụ thể để tôi có thể hoàn thành trong giới hạn token.

---

## 🎯 PHASE 1: FRONTEND ENHANCEMENT

### Prompt 1.1 - User Profile Page
```
Dựa trên cấu trúc hiện tại của eShelf (React + Vite + TailwindCSS), hãy tạo:
1. Component UserProfile.jsx trong src/pages/
2. Component ProfileSidebar.jsx, ProfileStats.jsx trong src/components/user/
3. Tích hợp routing trong main.jsx
4. Bao gồm: Avatar, thông tin cá nhân, thống kê đọc sách, danh sách yêu thích
5. Sử dụng pattern giống các page hiện có (BookDetail.jsx, Feedback.jsx)
```

### Prompt 1.2 - Collections & Favorites
```
Tạo tính năng Collections và Favorites cho eShelf:
1. Component Collections.jsx (page) - hiển thị các bộ sưu tập sách
2. Component CollectionCard.jsx, CreateCollectionModal.jsx
3. Tích hợp với data structure từ book-details.json
4. UI: Grid layout, add/remove books, rename collection
5. Lưu state bằng localStorage (tạm thời trước khi có backend)
```

### Prompt 1.3 - Reading Progress Tracker
```
Tạo tính năng theo dõi tiến độ đọc sách:
1. Component ReadingProgress.jsx trong BookDetail.jsx
2. Component ReadingHistory.jsx (page) - lịch sử đọc
3. Progress bar, bookmark position, last read timestamp
4. Tích hợp với Reading.jsx page hiện có
5. Lưu progress vào localStorage với structure phù hợp
```

### Prompt 1.4 - Dark Mode Implementation
```
Implement Dark Mode cho eShelf:
1. Tạo ThemeContext.jsx và ThemeProvider
2. Update tailwind.config.js với dark mode classes
3. Tạo ThemeToggle component trong Header
4. Apply dark classes cho tất cả components hiện có
5. Persist theme preference trong localStorage
```

### Prompt 1.5 - Admin Panel (Part 1 - Layout & Dashboard)
```
Tạo Admin Panel cho eShelf - Phần 1:
1. Layout AdminLayout.jsx với Sidebar navigation
2. Dashboard.jsx với statistics cards (tổng sách, users, downloads)
3. Route protection (giả lập role-based)
4. Cấu trúc thư mục src/admin/
5. Sử dụng Recharts hoặc Chart.js cho biểu đồ
```

### Prompt 1.6 - Admin Panel (Part 2 - Book Management)
```
Tạo Admin Panel - Phần 2 - Quản lý sách:
1. BookManagement.jsx - danh sách sách với DataTable
2. AddBookForm.jsx, EditBookModal.jsx
3. CRUD operations (mock với JSON data)
4. Upload cover image preview
5. Filter, search, pagination
```

### Prompt 1.7 - PWA Configuration
```
Cấu hình PWA cho eShelf:
1. Tạo manifest.json với icons và theme
2. Service Worker cho offline caching
3. Update vite.config.js với vite-plugin-pwa
4. Caching strategy cho static assets và book data
5. Install prompt component
```

---

## 🎯 PHASE 2: BACKEND SERVICES

### Prompt 2.1 - Project Setup & API Gateway
```
Setup Backend cho eShelf với Node.js:
1. Cấu trúc thư mục backend/services/api-gateway/
2. Express.js setup với middleware (cors, helmet, morgan)
3. Rate limiting configuration
4. Request validation với Joi/Zod
5. Error handling middleware
6. Dockerfile cho service
```

### Prompt 2.2 - Auth Service
```
Tạo Auth Service cho eShelf:
1. Cấu trúc backend/services/auth-service/
2. JWT authentication với access/refresh tokens
3. Routes: POST /register, POST /login, POST /refresh, POST /logout
4. Password hashing với bcrypt
5. Validation và error responses
6. Dockerfile và docker-compose integration
```

### Prompt 2.3 - User Service
```
Tạo User Service cho eShelf:
1. Cấu trúc backend/services/user-service/
2. Routes: GET/PUT /profile, GET /reading-history, GET/POST /favorites
3. User preferences management
4. Integration với Auth Service (verify token)
5. Database models (Prisma/Sequelize schema)
```

### Prompt 2.4 - Book Service
```
Tạo Book Service cho eShelf:
1. Cấu trúc backend/services/book-service/
2. Routes: CRUD /books, GET /books/search, GET /books/:id/similar
3. File upload to S3 (cover images, PDF files)
4. Pagination và filtering
5. Database models cho books, genres, reviews
```

### Prompt 2.5 - Search Service với Elasticsearch
```
Tạo Search Service cho eShelf:
1. Cấu trúc backend/services/search-service/
2. Elasticsearch client setup
3. Index mapping cho books
4. Full-text search với filters (genre, year, language)
5. Autocomplete suggestions
6. docker-compose với Elasticsearch container
```

### Prompt 2.6 - Notification Service
```
Tạo Notification Service cho eShelf:
1. Cấu trúc backend/services/notification-service/
2. Email notifications với AWS SES hoặc Nodemailer
3. In-app notifications với WebSocket
4. Notification templates
5. Queue system với Bull/Redis
```

---

## 🎯 PHASE 3: DATABASE

### Prompt 3.1 - Database Schema Design
```
Thiết kế Database Schema cho eShelf với PostgreSQL:
1. Tạo database/schemas/schema.sql với tất cả tables
2. ERD diagram description
3. Indexes cho performance
4. Foreign keys và constraints
5. Seed data scripts
Bao gồm: users, books, genres, reviews, collections, reading_history, notifications
```

### Prompt 3.2 - Prisma/Sequelize Setup
```
Setup ORM cho eShelf Backend:
1. Prisma schema file với tất cả models
2. Migration scripts
3. Seed data với Prisma
4. Connection pooling configuration
5. Shared database types package
```

### Prompt 3.3 - Database Migrations
```
Tạo Migration System cho eShelf:
1. Cấu trúc database/migrations/
2. Initial migration với all tables
3. Rollback scripts
4. CI/CD integration cho migrations
5. Environment-specific configurations
```

---

## 🎯 PHASE 4: ML/AI FEATURES

### Prompt 4.1 - ML Service Setup
```
Setup ML Service với Python FastAPI:
1. Cấu trúc backend/services/ml-service/
2. FastAPI application với Pydantic models
3. Endpoints: /recommendations, /similar-books, /health
4. MLflow integration setup
5. Dockerfile với Python dependencies
```

### Prompt 4.2 - Recommendation System
```
Implement Recommendation System cho eShelf:
1. Collaborative Filtering model với Surprise/LightFM
2. Training script với sample data
3. Model serialization và loading
4. API endpoint integration
5. A/B testing setup
```

### Prompt 4.3 - Content-Based Similarity
```
Implement Similar Books feature:
1. TF-IDF vectorization cho book descriptions
2. Cosine similarity calculation
3. Caching với Redis
4. API endpoint với pagination
5. Fallback strategy khi không đủ data
```

### Prompt 4.4 - Genre Classification (Optional)
```
Implement Auto Genre Classification:
1. BERT fine-tuning script cho genre classification
2. Model serving với FastAPI
3. Batch processing pipeline
4. Confidence threshold handling
5. Human review queue
```

---

## 🎯 PHASE 5: DEVOPS - LAB 1 (Infrastructure as Code)

### Prompt 5.1 - Terraform VPC Module
```
Tạo Terraform VPC Module cho eShelf (Lab 1 - 3 điểm):
1. infrastructure/terraform/modules/vpc/main.tf
2. VPC với CIDR 10.0.0.0/16
3. Public subnets (10.0.1.0/24, 10.0.2.0/24) trong 2 AZs
4. Private subnets (10.0.10.0/24, 10.0.11.0/24)
5. Internet Gateway
6. variables.tf và outputs.tf
```

### Prompt 5.2 - Terraform Route Tables & NAT
```
Tạo Terraform Route Tables và NAT Gateway (Lab 1 - 3 điểm):
1. infrastructure/terraform/modules/networking/
2. Public route table với route to IGW
3. Private route table với route to NAT Gateway
4. NAT Gateway trong public subnet
5. Elastic IP cho NAT Gateway
6. Subnet associations
```

### Prompt 5.3 - Terraform EC2 Module
```
Tạo Terraform EC2 Module (Lab 1 - 2 điểm):
1. infrastructure/terraform/modules/ec2/
2. Bastion Host (Public EC2) trong public subnet
3. App Server (Private EC2) trong private subnet
4. Key pair configuration
5. User data scripts
6. AMI data source (Amazon Linux 2)
```

### Prompt 5.4 - Terraform Security Groups
```
Tạo Terraform Security Groups (Lab 1 - 2 điểm):
1. infrastructure/terraform/modules/security-groups/
2. Bastion SG: SSH (22) from my IP only
3. App SG: SSH from Bastion SG, Port 3000 from Bastion
4. ALB SG: HTTP/HTTPS from anywhere
5. Proper egress rules
6. Best practices annotations
```

### Prompt 5.5 - Terraform Environment Configuration
```
Tạo Terraform Environment Setup:
1. infrastructure/terraform/environments/dev/main.tf
2. Module calls với variable values
3. Backend configuration (S3 + DynamoDB)
4. terraform.tfvars template
5. .gitignore cho sensitive files
```

### Prompt 5.6 - CloudFormation VPC Stack
```
Tạo CloudFormation VPC Template:
1. infrastructure/cloudformation/templates/vpc-stack.yaml
2. Tương đương với Terraform VPC module
3. Parameters cho customization
4. Outputs cho cross-stack references
5. Proper resource naming
```

### Prompt 5.7 - CloudFormation EC2 Stack
```
Tạo CloudFormation EC2 Template:
1. infrastructure/cloudformation/templates/ec2-stack.yaml
2. Bastion và App Server EC2
3. Reference VPC stack outputs
4. Security Groups inline hoặc separate stack
5. IAM Instance Profile
```

### Prompt 5.8 - Infrastructure Test Cases
```
Tạo Test Cases cho Infrastructure (Lab 1):
1. infrastructure/terraform/tests/test_infrastructure.sh
2. Test VPC exists và configured correctly
3. Test Public EC2 reachable via SSH
4. Test Private EC2 only via Bastion
5. Test NAT Gateway (private EC2 can curl google.com)
6. Test Security Groups rules
```

---

## 🎯 PHASE 6: DEVOPS - LAB 2 (CI/CD Automation)

### Prompt 6.1 - GitHub Actions Terraform Pipeline
```
Tạo GitHub Actions cho Terraform (Lab 2 - 3 điểm):
1. .github/workflows/terraform.yml
2. Checkov security scan
3. Terraform fmt, validate, plan
4. Terraform apply on main branch
5. PR comment với plan output
6. AWS credentials từ secrets
```

### Prompt 6.2 - CloudFormation CodePipeline
```
Tạo AWS CodePipeline cho CloudFormation (Lab 2 - 3 điểm):
1. infrastructure/cloudformation/pipeline-stack.yaml
2. CodeCommit hoặc GitHub source
3. CodeBuild với cfn-lint và taskcat
4. CloudFormation deploy stage
5. buildspec.yml configuration
```

### Prompt 6.3 - Jenkins Pipeline Setup
```
Tạo Jenkins Pipeline cho eShelf (Lab 2 - 4 điểm - Part 1):
1. jenkins/Jenkinsfile
2. Lint & Test stages (parallel)
3. SonarQube analysis stage
4. Docker build stage
5. Environment variables và credentials
```

### Prompt 6.4 - Jenkins Security Scanning
```
Jenkins Pipeline - Security Scanning (Lab 2 - Part 2):
1. Trivy container scan stage
2. Snyk dependency scan (optional)
3. OWASP dependency check
4. Fail pipeline on HIGH/CRITICAL
5. Report generation
```

### Prompt 6.5 - Jenkins Kubernetes Deployment
```
Jenkins Pipeline - K8s Deployment (Lab 2 - Part 3):
1. Push to ECR stage
2. Deploy to Staging với kubectl
3. Integration tests stage
4. Manual approval gate
5. Deploy to Production
6. Rollback on failure
```

### Prompt 6.6 - GitHub Actions Frontend CI
```
Tạo GitHub Actions cho Frontend CI:
1. .github/workflows/ci-frontend.yml
2. Install, lint, test, build
3. Upload build artifacts
4. Deploy to S3/CloudFront (staging)
5. Lighthouse performance check
```

### Prompt 6.7 - GitHub Actions Backend CI
```
Tạo GitHub Actions cho Backend CI:
1. .github/workflows/ci-backend.yml
2. Matrix build cho multiple services
3. Unit tests với coverage
4. Docker build và push to ECR
5. Integration tests với docker-compose
```

---

## 🎯 PHASE 7: KUBERNETES & ADVANCED DEVOPS

### Prompt 7.1 - Kubernetes Base Manifests
```
Tạo Kubernetes Base Manifests:
1. infrastructure/kubernetes/base/namespace.yaml
2. ConfigMaps và Secrets templates
3. PersistentVolumeClaims
4. NetworkPolicies
5. ResourceQuotas và LimitRanges
```

### Prompt 7.2 - Kubernetes Deployments
```
Tạo Kubernetes Deployments cho eShelf:
1. infrastructure/kubernetes/deployments/frontend.yaml
2. infrastructure/kubernetes/deployments/api-gateway.yaml
3. Liveness và Readiness probes
4. Resource requests/limits
5. Environment variables từ ConfigMap/Secret
```

### Prompt 7.3 - Kubernetes Services & Ingress
```
Tạo Kubernetes Services và Ingress:
1. infrastructure/kubernetes/services/ cho mỗi deployment
2. infrastructure/kubernetes/ingress/ingress.yaml
3. TLS configuration
4. Path-based routing
5. Annotations cho ALB/Nginx Ingress
```

### Prompt 7.4 - Kubernetes HPA & Kustomize
```
Tạo HPA và Kustomize overlays:
1. infrastructure/kubernetes/hpa/ cho frontend, api-gateway
2. infrastructure/kubernetes/kustomize/base/
3. infrastructure/kubernetes/kustomize/overlays/staging/
4. infrastructure/kubernetes/kustomize/overlays/production/
5. Environment-specific patches
```

### Prompt 7.5 - Helm Chart
```
Tạo Helm Chart cho eShelf:
1. infrastructure/helm/eshelf/Chart.yaml
2. values.yaml với default values
3. templates/ cho deployments, services, ingress
4. values-staging.yaml, values-production.yaml
5. _helpers.tpl cho common labels
```

### Prompt 7.6 - ArgoCD GitOps Setup
```
Cấu hình ArgoCD cho eShelf:
1. ArgoCD Application manifests
2. ApplicationSet cho multi-environment
3. Sync policies và auto-sync
4. Notifications configuration
5. RBAC cho team access
```

---

## 🎯 PHASE 8: MONITORING & OBSERVABILITY

### Prompt 8.1 - Prometheus Setup
```
Cấu hình Prometheus cho eShelf:
1. monitoring/prometheus/prometheus.yml
2. Service discovery cho Kubernetes
3. Scrape configs cho các services
4. Alert rules file
5. Docker-compose integration
```

### Prompt 8.2 - Grafana Dashboards
```
Tạo Grafana Dashboards:
1. monitoring/grafana/dashboards/application.json
2. monitoring/grafana/dashboards/infrastructure.json
3. monitoring/grafana/dashboards/kubernetes.json
4. Data source configuration
5. Dashboard provisioning
```

### Prompt 8.3 - Alertmanager Configuration
```
Cấu hình Alertmanager:
1. monitoring/alertmanager/alertmanager.yml
2. Alert routing rules
3. Notification channels (Slack, Email)
4. Inhibit rules
5. Templates cho notifications
```

### Prompt 8.4 - Loki Logging Stack
```
Cấu hình Loki cho centralized logging:
1. monitoring/loki/loki-config.yaml
2. Promtail configuration
3. Grafana Loki data source
4. Log queries và dashboards
5. Retention policies
```

---

## 🎯 PHASE 9: MLOPS

### Prompt 9.1 - MLflow Setup
```
Cấu hình MLflow cho eShelf:
1. mlops/mlflow/docker-compose.yml
2. MLflow tracking server configuration
3. Artifact storage với S3
4. PostgreSQL backend store
5. UI access và authentication
```

### Prompt 9.2 - ML Training Pipeline
```
Tạo ML Training Pipeline:
1. .github/workflows/ml-training.yml
2. Data preprocessing step
3. Model training với MLflow tracking
4. Model evaluation và comparison
5. Model registration nếu improved
```

### Prompt 9.3 - Model Serving
```
Cấu hình Model Serving:
1. ML service với model loading từ MLflow
2. Canary deployment configuration
3. A/B testing setup
4. Model versioning
5. Rollback strategy
```

### Prompt 9.4 - ML Monitoring
```
Cấu hình ML Monitoring:
1. Data drift detection
2. Model performance metrics
3. Prometheus metrics cho ML
4. Grafana dashboard cho ML
5. Automated retraining triggers
```

---

## 📝 Cách Sử Dụng

1. **Copy từng prompt** và paste vào conversation mới
2. **Đợi tôi hoàn thành** code/config cho phần đó
3. **Review và test** code được tạo
4. **Tiếp tục với prompt tiếp theo**

### Thứ tự ưu tiên đề xuất:
```
Frontend (1.1 → 1.7) 
    → Backend (2.1 → 2.6) 
    → Database (3.1 → 3.3)
    → DevOps Lab 1 (5.1 → 5.8) 
    → DevOps Lab 2 (6.1 → 6.7)
    → Kubernetes (7.1 → 7.6)
    → ML Features (4.1 → 4.4)
    → Monitoring (8.1 → 8.4)
    → MLOps (9.1 → 9.4)
```

