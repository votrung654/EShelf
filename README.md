# eShelf - Enterprise eBook Platform

[![CI/CD Pipeline](https://github.com/levanvux/eShelf/workflows/CI/badge.svg)](https://github.com/levanvux/eShelf/actions)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/K8s-Ready-326CE5)](https://kubernetes.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Đồ án môn học IE104 - UIT**  
> Website đọc sách eBooks với kiến trúc microservices, CI/CD pipeline và MLOps.

---

## 📋 Mục lục

- [Giới thiệu](#-giới-thiệu)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Tech Stack](#-tech-stack)
- [Hướng dẫn chạy dự án](#-hướng-dẫn-chạy-dự-án)
- [Cấu trúc thư mục](#-cấu-trúc-thư-mục)
- [Lab 1 & Lab 2](#-lab-1--lab-2)
- [API Documentation](#-api-documentation)

---

## 🎯 Giới thiệu

**eShelf** là nền tảng đọc sách điện tử được xây dựng với kiến trúc microservices, áp dụng đầy đủ quy trình DevOps và MLOps chuyên nghiệp.

### Tính năng chính

**Người dùng:**
- 📚 Đọc sách PDF trực tuyến
- 🔍 Tìm kiếm và lọc sách theo thể loại
- ⭐ Đánh giá và review sách
- 📖 Lưu bộ sưu tập và sách yêu thích
- 📊 Theo dõi tiến độ đọc
- 🤖 Gợi ý sách thông minh (AI-powered)

**Admin:**
- 📊 Dashboard thống kê
- ➕ Quản lý sách (CRUD)
- 👥 Quản lý người dùng
- 🏷️ Quản lý thể loại

**DevOps:**
- 🏗️ Infrastructure as Code (Terraform, CloudFormation)
- 🔄 CI/CD Pipeline (GitHub Actions, Jenkins)
- ☸️ Kubernetes deployment với GitOps (ArgoCD)
- 📊 Monitoring (Prometheus, Grafana, Loki)
- 🔒 Security scanning (Checkov, Trivy, SonarQube)

**MLOps:**
- 🤖 Recommendation system
- 📈 Model tracking với MLflow
- 🔄 Automated model deployment
- 📊 Model performance monitoring

---

## 🏗️ Kiến trúc hệ thống

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

## 🛠️ Tech Stack

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

## 🚀 Hướng dẫn chạy dự án

### Prerequisites

- Node.js >= 18
- Python >= 3.11
- Docker & Docker Compose
- Git

### 1. Clone Repository

```bash
git clone https://github.com/levanvux/eShelf.git
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

### 3. Chạy Backend (Option A: Docker Compose - Recommended)

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

### 4. Chạy Backend (Option B: Manual)

**Terminal 1 - Auth Service:**
```bash
cd backend/services/auth-service
npm install
cp .env.example .env
npm run dev
```

**Terminal 2 - Book Service:**
```bash
cd backend/services/book-service
npm install
cp .env.example .env
npm run dev
```

**Terminal 3 - User Service:**
```bash
cd backend/services/user-service
npm install
cp .env.example .env
npm run dev
```

**Terminal 4 - ML Service:**
```bash
cd backend/services/ml-service
pip install -r requirements.txt
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

### 5. Setup Database (Optional - cho production)

```bash
cd backend/database
npm install
cp .env.example .env

# Generate Prisma Client
npm run db:generate

# Run migrations
npm run db:migrate

# Seed data
npm run db:seed
```

### 6. Verify Services

```bash
# Check all services
curl http://localhost:3000/health  # API Gateway
curl http://localhost:3001/health  # Auth Service
curl http://localhost:3002/health  # Book Service
curl http://localhost:3003/health  # User Service
curl http://localhost:8000/health  # ML Service
```

### 7. Access Application

- **Frontend:** http://localhost:5173
- **API Gateway:** http://localhost:3000
- **ML API Docs:** http://localhost:8000/docs

---

## 📁 Cấu trúc thư mục

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
│   └── docker-compose.yml   # All services orchestration
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
├── scripts/                 # Utility scripts
├── PLAN.md                 # Project plan (3-person team)
└── README.md               # This file
```

---

## 🧪 Lab 1 & Lab 2

### Lab 1: Infrastructure as Code (10 điểm)

**Terraform:**
```bash
cd infrastructure/terraform/environments/dev

# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply
```

**CloudFormation:**
```bash
cd infrastructure/cloudformation

# Validate template
aws cloudformation validate-template --template-body file://templates/vpc-stack.yaml

# Deploy
aws cloudformation create-stack \
  --stack-name eshelf-vpc \
  --template-body file://templates/vpc-stack.yaml
```

**Test Cases:**
```bash
# Run infrastructure tests
bash scripts/test-infrastructure.sh
```

### Lab 2: CI/CD Automation (10 điểm)

**GitHub Actions:**
- Push code → Automatic CI/CD triggered
- Checkov scan cho Terraform
- Docker build & security scan
- Automated deployment

**Jenkins:**
- Jenkinsfile với multi-stage pipeline
- SonarQube code quality
- Trivy container scanning
- Kubernetes deployment

---

## 📖 API Documentation

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

## 🐳 Docker Commands

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

## 🧪 Testing

### Test All Components (FE, BE, Database, ML-AI)

Trước khi chuyển sang phần Ops, test tất cả components:

**Option 1: Test tự động (Script)**
```bash
# Linux/Mac
npm run test:all

# Windows (PowerShell)
npm run test:all:win
```

**Option 2: Test thủ công (Manual) - Khuyến nghị**
- [docs/TEST_THU_CONG.md](docs/TEST_THU_CONG.md) - Hướng dẫn nhanh (Tiếng Việt)
- [docs/MANUAL_TESTING_GUIDE.md](docs/MANUAL_TESTING_GUIDE.md) - Hướng dẫn chi tiết

Xem chi tiết: [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md)

### Individual Tests

```bash
# Frontend
npm test

# Backend services
cd backend/services/auth-service && npm test
cd backend/services/book-service && npm test

# Infrastructure
bash scripts/test-infrastructure.sh

# E2E tests (if implemented)
npm run test:e2e
```

---

## 📊 Monitoring

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

## 🔒 Security

- **Authentication:** JWT with access/refresh tokens
- **Password:** Hashed with bcrypt (12 rounds)
- **Rate Limiting:** 100 requests per 15 minutes
- **CORS:** Configured for allowed origins
- **Headers:** Security headers with Helmet
- **Validation:** Input validation on all endpoints
- **Scanning:** Container and code security scanning

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [PLAN.md](PLAN.md) | Project plan for 3-person team |
| [docs/master_prompts.md](docs/master_prompts.md) | Detailed prompt plan |
| [yeucaumonhoc.md](yeucaumonhoc.md) | Course requirements |
| [gopygiangvien.md](gopygiangvien.md) | Instructor feedback |

---

## 👥 Team

| MSSV | Họ Tên | Vai trò |
|------|--------|---------|
| 23521809 | Lê Văn Vũ | DevOps Engineer (Lead) |
| TBD | Thành viên 2 | Backend Developer |
| TBD | Thành viên 3 | Full-stack & ML Engineer |

---

## 📄 License

MIT License - For educational purposes only.

---

## 🙏 Acknowledgments

- Instructor: [Tên giảng viên]
- Course: IE104 - DevOps & MLOps
- University: UIT (Đại học Công nghệ Thông tin)

---

## 📧 Contact

**Lê Văn Vũ** - [GitHub](https://github.com/levanvux)

---

## 🚀 Quick Start (TL;DR)

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

## 🔐 Default Login Credentials

### Admin Account
- **Email:** `admin@eshelf.com`
- **Password:** `Admin123!`
- **Quyền hạn:** Quản lý sách, users, dashboard

### Test User Account
- **Email:** `user@eshelf.com`
- **Password:** `User123!`
- **Quyền hạn:** Đọc sách, favorites, recommendations

> **Lưu ý:** Chạy `cd backend/database && npm run db:seed` để tạo tài khoản mặc định
