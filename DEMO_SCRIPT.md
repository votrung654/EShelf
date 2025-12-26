# Kịch Bản Demo eShelf Project

## Tổng Quan

Kịch bản demo toàn diện cho project eShelf, bao gồm kiến trúc microservices, CI/CD pipeline, và MLOps.

## Phần 1: Giới Thiệu Project (5 phút)

### 1.1. Tổng quan eShelf
- Nền tảng đọc sách điện tử với kiến trúc microservices
- Tech stack: React, Node.js, PostgreSQL, FastAPI, Kubernetes
- Tính năng: Đọc PDF, tìm kiếm, gợi ý AI, quản lý bộ sưu tập

### 1.2. Kiến Trúc Hệ Thống
- Frontend: React 18 + Vite
- API Gateway: Express.js (routing, rate limiting)
- Microservices:
  - Auth Service: JWT authentication
  - Book Service: CRUD, search
  - User Service: Profile, favorites, collections
  - ML Service: Recommendations, similarity
- Database: PostgreSQL với Prisma ORM
- Cache: Redis

### 1.3. DevOps & MLOps Stack
- IaC: Terraform, CloudFormation
- CI/CD: GitHub Actions, Jenkins, AWS CodePipeline
- Container: Docker, Docker Compose
- Orchestration: Kubernetes (K3s)
- GitOps: ArgoCD
- Registry: Harbor
- Monitoring: Prometheus, Grafana, Loki
- Security: Trivy, Checkov, SonarQube

## Phần 2: Demo Local Development (10 phút)

### 2.1. Setup và Chạy Local
```powershell
# Clone repository
git clone https://github.com/votrung654/EShelf.git
cd EShelf

# Start backend services
cd backend
docker-compose up -d

# Kiểm tra database migrations tự động
docker-compose logs db-migration

# Start frontend
cd ..
npm install
npm run dev
```

**Điểm nhấn:**
- Database tự động build và migrate khi start docker-compose
- Không cần setup thủ công database
- Tất cả services start tự động với dependencies đúng thứ tự

### 2.2. Kiểm Tra Services
- Frontend: http://localhost:5173
- API Gateway: http://localhost:3000
- ML Service Docs: http://localhost:8000/docs
- Database: PostgreSQL trên port 5432

### 2.3. Test Tính Năng Cơ Bản
1. Đăng ký/Đăng nhập
2. Tìm kiếm sách
3. Xem chi tiết sách
4. Đọc PDF
5. Thêm vào favorites

## Phần 3: Kiến Trúc Microservices (15 phút)

### 3.1. Service Communication
- API Gateway làm entry point
- Service-to-service communication qua HTTP
- Database per service pattern
- Shared database cho auth, book, user services (có thể tách riêng)

### 3.2. Data Flow
```
User Request → API Gateway → Service → Database
                ↓
            Response ← Service ← Database
```

### 3.3. Authentication Flow
1. User login → Auth Service
2. Auth Service verify credentials
3. Generate JWT token
4. API Gateway validate token cho các requests tiếp theo

### 3.4. Service Dependencies
- Auth Service: Standalone
- Book Service: Depends on database
- User Service: Depends on database
- ML Service: Standalone, có thể call từ Book Service

## Phần 4: CI/CD Pipeline (15 phút)

### 4.1. GitHub Actions Workflows
- **PR Pipeline**: Lint, test, security scan (không deploy)
- **Push to Main**: Build images, push to Harbor, deploy
- **Smart Build**: Chỉ build services có code changes thực sự

### 4.2. Demo CI/CD Flow
1. Tạo PR với code changes
2. GitHub Actions chạy:
   - Frontend CI: Lint, build
   - Backend CI: Lint, test cho từng service
   - Security Scan: Trivy, Checkov
   - SonarQube: Code quality
3. Merge vào main
4. Smart Build detect changes
5. Build và push Docker images
6. Update Kubernetes manifests
7. ArgoCD sync và deploy

### 4.3. Security Scanning
- Trivy: Container vulnerability scanning
- Checkov: IaC security scanning
- SonarQube: Code quality và security

## Phần 5: Infrastructure as Code (10 phút)

### 5.1. Terraform
- VPC, Subnets, Security Groups
- EC2 instances cho K3s cluster
- 3-node cluster: 1 master + 2 workers

### 5.2. CloudFormation
- CodePipeline setup
- EC2 stack templates

### 5.3. Ansible
- K3s cluster setup
- Configuration management

## Phần 6: Kubernetes Deployment (15 phút)

### 6.1. K3s Cluster
- Lightweight Kubernetes distribution
- Deploy trên AWS EC2
- 3 environments: dev, staging, prod

### 6.2. Kustomize
- Base configurations
- Environment-specific overlays
- Image tag management

### 6.3. ArgoCD GitOps
- Application manifests
- Automatic sync
- Image updater

### 6.4. Demo Deployment
```bash
# Apply base configurations
kubectl apply -k infrastructure/kubernetes/base

# Apply environment-specific
kubectl apply -k infrastructure/kubernetes/overlays/prod

# Check ArgoCD applications
kubectl get applications -n argocd
```

## Phần 7: Monitoring và Observability (10 phút)

### 7.1. Prometheus
- Metrics collection
- Service discovery
- Alert rules

### 7.2. Grafana
- Dashboards
- Data visualization
- Alert notifications

### 7.3. Loki
- Log aggregation
- Log querying

### 7.4. Demo Monitoring
1. Truy cập Grafana
2. Xem dashboards
3. Kiểm tra alerts
4. Query logs từ Loki

## Phần 8: MLOps (10 phút)

### 8.1. ML Service
- FastAPI service
- Recommendation algorithms
- Similarity search

### 8.2. Model Training
- GitHub Actions workflow
- Model versioning

### 8.3. Model Deployment
- Canary deployment
- Rollback mechanism

## Phần 9: Security Best Practices (5 phút)

### 9.1. Container Security
- Non-root users
- Minimal base images
- Security scanning

### 9.2. Secrets Management
- Environment variables
- Kubernetes Secrets
- .gitignore cho sensitive files

### 9.3. Network Security
- Security groups
- Private subnets
- VPC isolation

## Phần 10: Q&A và Kết Luận (10 phút)

### Câu Hỏi Thường Gặp

1. **Tại sao chọn microservices architecture?**
   - Scalability
   - Independent deployment
   - Technology diversity
   - Team autonomy

2. **Làm thế nào đảm bảo data consistency?**
   - Database per service (có thể)
   - Event-driven architecture (có thể mở rộng)
   - Transaction management

3. **Xử lý service failures như thế nào?**
   - Health checks
   - Retry mechanisms
   - Circuit breakers (có thể mở rộng)
   - Monitoring và alerting

4. **CI/CD pipeline có gì đặc biệt?**
   - Smart build: chỉ build services thay đổi
   - Security scanning tự động
   - Automated rollback

5. **Monitoring strategy?**
   - Prometheus cho metrics
   - Grafana cho visualization
   - Loki cho logs
   - Alertmanager cho notifications

## Tổng Kết

- Kiến trúc microservices hoàn chỉnh
- CI/CD pipeline tự động
- Infrastructure as Code
- Monitoring và observability
- Security best practices
- MLOps integration

## Thời Gian Tổng: ~100 phút

