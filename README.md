# eShelf - Enterprise eBook Platform

[![CI/CD Pipeline](https://github.com/levanvux/eShelf/workflows/CI/badge.svg)](https://github.com/levanvux/eShelf/actions)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/K8s-Ready-326CE5)](https://kubernetes.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Đồ án môn học IE104 - UIT**  
> Website đọc sách eBooks với kiến trúc microservices, CI/CD pipeline và MLOps.

---

## Mục lục

- [Giới thiệu](#giới-thiệu)
- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Tech Stack](#tech-stack)
- [Hướng dẫn chạy dự án](#hướng-dẫn-chạy-dự-án)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Trạng thái dự án](#trạng-thái-dự-án)
- [API Documentation](#api-documentation)

---

## Giới thiệu

**eShelf** là nền tảng đọc sách điện tử được xây dựng với kiến trúc microservices, áp dụng đầy đủ quy trình DevOps và MLOps chuyên nghiệp.

### Tính năng chính

**Người dùng:**
- Đọc sách PDF trực tuyến
- Tìm kiếm và lọc sách theo thể loại
- Đánh giá và review sách
- Lưu bộ sưu tập và sách yêu thích
- Theo dõi tiến độ đọc
- Gợi ý sách thông minh (AI-powered)

**Admin:**
- Dashboard thống kê
- Quản lý sách (CRUD)
- Quản lý người dùng
- Quản lý thể loại

**DevOps:**
- Infrastructure as Code (Terraform, CloudFormation)
- CI/CD Pipeline (GitHub Actions, Jenkins)
- Kubernetes deployment với GitOps (ArgoCD)
- Monitoring (Prometheus, Grafana, Loki)
- Security scanning (Checkov, Trivy, SonarQube)

**MLOps:**
- Recommendation system
- Model tracking với MLflow
- Automated model deployment
- Model performance monitoring

---

## Kiến trúc hệ thống

### Microservices Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (React + Vite)                   │
│                      http://localhost:5173                   │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                   API Gateway (Express)                      │
│                      http://localhost:3000                   │
└────────────────────────────┬────────────────────────────────┘
                             │
       ┌─────────────────────┼─────────────────────┬──────────┐
       ▼                     ▼                     ▼          ▼
┌──────────┐         ┌──────────┐         ┌──────────┐  ┌──────────┐
│   Auth   │         │   Book   │         │   User   │  │    ML    │
│ Service  │         │ Service  │         │ Service  │  │ Service  │
│  :3001   │         │  :3002   │         │  :3003   │  │  :8000   │
└──────────┘         └──────────┘         └──────────┘  └──────────┘
      │                     │                     │          │
      └─────────────────────┼─────────────────────┴──────────┘
                            ▼
                  ┌──────────────────┐
                  │   PostgreSQL     │
                  │   Redis Cache    │
                  └──────────────────┘
```

### Services

| Service | Port | Technology | Description |
|---------|------|------------|-------------|
| Frontend | 5173 | React + Vite | Web UI |
| API Gateway | 3000 | Express.js | API routing, rate limiting |
| Auth Service | 3001 | Express.js | JWT authentication |
| Book Service | 3002 | Express.js | Book CRUD, search |
| User Service | 3003 | Express.js | Profile, favorites, collections |
| ML Service | 8000 | FastAPI | Recommendations, similarity |
| PostgreSQL | 5432 | PostgreSQL 16 | Primary database |
| Redis | 6379 | Redis 7 | Caching |

---

## Tech Stack

### Frontend
- **Framework:** React 18 + Vite
- **Styling:** TailwindCSS
- **Routing:** React Router
- **State:** React Context
- **Icons:** Lucide React
- **Charts:** Recharts

### Backend
- **Runtime:** Node.js 20
- **Framework:** Express.js
- **Authentication:** JWT + bcrypt
- **Validation:** express-validator
- **ORM:** Prisma

### ML/AI
- **Framework:** FastAPI (Python)
- **ML Libraries:** scikit-learn, numpy, pandas
- **Algorithms:** Collaborative Filtering, Content-based Filtering

### Database
- **Primary:** PostgreSQL 16
- **Cache:** Redis 7
- **ORM:** Prisma

### DevOps
- **IaC:** Terraform, CloudFormation
- **CI/CD:** GitHub Actions, Jenkins
- **Containers:** Docker, Docker Compose
- **Orchestration:** Kubernetes (EKS/K3s)
- **GitOps:** ArgoCD
- **Registry:** Harbor / AWS ECR

### Monitoring
- **Metrics:** Prometheus
- **Visualization:** Grafana
- **Logging:** Loki
- **Alerting:** Alertmanager

### Security
- **IaC Scan:** Checkov
- **Container Scan:** Trivy
- **Code Quality:** SonarQube
- **DAST:** OWASP ZAP

---

## Hướng dẫn chạy dự án

### Prerequisites

- Node.js >= 18
- Python >= 3.11
- Docker & Docker Compose
- Git

### 1. Clone Repository

```bash
git clone https://github.com/votrung654/eShelf.git
cd eShelf
```

### 2. Chạy Frontend

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

Frontend sẽ chạy tại: **http://localhost:5173**

### 3. Chạy Backend (Docker Compose - Recommended)

```bash
cd backend
docker-compose up -d
```

Tất cả services sẽ tự động start:
- API Gateway: http://localhost:3000
- Auth Service: http://localhost:3001
- Book Service: http://localhost:3002
- User Service: http://localhost:3003
- ML Service: http://localhost:8000
- PostgreSQL: localhost:5432
- Redis: localhost:6379

### 4. Verify Services

```bash
# Check all services
curl http://localhost:3000/health  # API Gateway
curl http://localhost:3001/health  # Auth Service
curl http://localhost:3002/health  # Book Service
curl http://localhost:3003/health  # User Service
curl http://localhost:8000/health  # ML Service
```

### 5. Access Application

- **Frontend:** http://localhost:5173
- **API Gateway:** http://localhost:3000
- **ML API Docs:** http://localhost:8000/docs

---

## Cấu trúc thư mục

```
eShelf/
├── .github/workflows/        # CI/CD pipelines
│   ├── ci.yml               # Frontend/Backend CI
│   └── terraform.yml        # Infrastructure pipeline
│
├── backend/
│   ├── services/
│   │   ├── api-gateway/     # Port 3000 - API routing
│   │   ├── auth-service/    # Port 3001 - Authentication
│   │   ├── book-service/    # Port 3002 - Book management
│   │   ├── user-service/    # Port 3003 - User management
│   │   └── ml-service/      # Port 8000 - ML recommendations
│   ├── database/
│   │   └── prisma/          # Database schema
│   └── docker-compose.yml  # All services orchestration
│
├── infrastructure/
│   └── terraform/
│       ├── modules/         # Reusable modules
│       │   ├── vpc/
│       │   ├── ec2/
│       │   └── security-groups/
│       └── environments/
│           └── dev/         # Dev environment config
│
├── src/                     # Frontend source
│   ├── admin/              # Admin panel
│   ├── components/         # Reusable components
│   ├── context/            # React contexts
│   ├── pages/              # Page components
│   ├── services/           # API client
│   └── styles/
│
├── public/                  # Static assets
│   ├── demo/               # Screenshots
│   ├── images/             # Images
│   └── pdfs/               # Sample books
│
└── scripts/                 # Utility scripts
```

---

## Trạng thái dự án

### Đã hoàn thành

**Frontend:**
- ✅ Giao diện người dùng với React + Vite
- ✅ Tìm kiếm và lọc sách
- ✅ Quản lý bộ sưu tập
- ✅ Lịch sử đọc
- ✅ Yêu thích sách
- ✅ Dark mode
- ✅ Kết nối với backend API

**Backend:**
- ✅ Kiến trúc microservices
- ✅ API Gateway với proxy routing
- ✅ Auth Service (JWT authentication)
- ✅ Book Service (CRUD, search)
- ✅ User Service (Profile, favorites, collections, history)
- ✅ ML Service (Recommendations, similarity)
- ✅ Database schema với Prisma
- ✅ Docker Compose setup

**DevOps:**
- ✅ GitHub Actions CI pipeline
- ✅ Jenkins pipeline
- ✅ Terraform modules (VPC, EC2, Security Groups)
- ✅ CloudFormation templates
- ✅ Docker containerization

**MLOps:**
- ✅ Recommendation API
- ✅ Similar books API
- ✅ Reading time estimation

### Đang phát triển

**Backend:**
- 🔄 Chuyển từ in-memory storage sang database persistence (Prisma)
- 🔄 Hoàn thiện error handling và validation
- 🔄 Thêm unit tests và integration tests

**DevOps:**
- 🔄 Smart Build (path-filter trong CI/CD)
- 🔄 GitOps với ArgoCD
- 🔄 Image tagging tự động
- 🔄 Multi-environment deployment (Dev, Staging, Prod)
- 🔄 Monitoring setup (Prometheus, Grafana, Loki)

**MLOps:**
- 🔄 MLflow integration
- 🔄 Model versioning
- 🔄 Model performance monitoring

### Dự kiến làm

**Infrastructure:**
- 📋 Deploy lên AWS (EKS hoặc K3s trên EC2)
- 📋 Setup Harbor/Artifactory cho artifact management
- 📋 Ansible scripts cho configuration management
- 📋 Complete monitoring stack

**CI/CD:**
- 📋 Smart Build với path-filter
- 📋 ArgoCD Image Updater
- 📋 Blue/Green deployment
- 📋 Automated rollback

**Security:**
- 📋 Complete security scanning pipeline
- 📋 Secrets management
- 📋 Network policies

**Testing:**
- 📋 E2E tests
- 📋 Load testing
- 📋 Security testing

---

## API Documentation

### Authentication

```bash
# Register
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!",
  "username": "johndoe",
  "name": "John Doe"
}

# Login
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!"
}

# Response
{
  "success": true,
  "data": {
    "user": { ... },
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG..."
  }
}
```

### Books

```bash
# Get all books
GET http://localhost:3000/api/books?page=1&limit=20

# Search books
GET http://localhost:3000/api/books/search?q=Harry&genre=Fantasy

# Get book by ID
GET http://localhost:3000/api/books/9780099908401

# Create book (Admin only)
POST http://localhost:3000/api/books
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "title": "New Book",
  "author": ["Author Name"],
  "genres": ["Fiction"],
  "year": 2024
}
```

### ML Recommendations

```bash
# Get personalized recommendations
POST http://localhost:3000/api/ml/recommendations
Content-Type: application/json

{
  "user_id": "user123",
  "n_items": 10
}

# Get similar books
POST http://localhost:3000/api/ml/similar
Content-Type: application/json

{
  "book_id": "9780099908401",
  "n_items": 6
}

# Estimate reading time
POST http://localhost:3000/api/ml/estimate-time
Content-Type: application/json

{
  "pages": 300,
  "genre": "Văn Học"
}
```

Xem full API docs: http://localhost:8000/docs (ML Service)

---

## Docker Commands

```bash
# Build all services
cd backend
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Rebuild specific service
docker-compose up -d --build auth-service
```

---

## Testing

```bash
# Frontend
npm test

# Backend services
cd backend/services/auth-service && npm test
cd backend/services/book-service && npm test

# Infrastructure
bash scripts/test-infrastructure.sh
```

---

## Monitoring

### Prometheus Metrics
- Service health and uptime
- Request rate and latency
- Error rates
- Resource usage

### Grafana Dashboards
- Application metrics
- Infrastructure metrics
- Kubernetes metrics
- ML model performance

### Loki Logs
- Centralized logging
- Log aggregation from all services
- Query and search logs

---

## Security

- **Authentication:** JWT with access/refresh tokens
- **Password:** Hashed with bcrypt (12 rounds)
- **Rate Limiting:** 100 requests per 15 minutes
- **CORS:** Configured for allowed origins
- **Headers:** Security headers with Helmet
- **Validation:** Input validation on all endpoints
- **Scanning:** Container and code security scanning

---

## Documentation

| Document | Description |
|----------|-------------|
| [yeucaumonhoc.md](yeucaumonhoc.md) | Course requirements |
| [gopygiangvien.md](gopygiangvien.md) | Instructor feedback |

---

## Team

| MSSV | Họ Tên |Phân công|
|------|--------|--------|
| 23521809 | Lê Văn Vũ | |
| 22521571 | Võ Đình Trung | |
| 22521587| Trương Phúc Trường | |

---

## License

MIT License - For educational purposes only.

---

## Acknowledgments

- Instructor: [Tên giảng viên]
- Course: IE104 - DevOps & MLOps
- University: UIT (Đại học Công nghệ Thông tin)

---

## Contact

**Lê Văn Vũ** - [GitHub](https://github.com/levanvux)

---

## Quick Start (TL;DR)

```bash
# 1. Clone
git clone https://github.com/levanvux/eShelf.git && cd eShelf

# 2. Start Backend
cd backend && docker-compose up -d && cd ..

# 3. Start Frontend
npm install && npm run dev

# 4. Open browser
# http://localhost:5173
```

**Default credentials for testing:**
- Email: `user@eshelf.com`
- Password: `User123!`

(Register new account if needed)
