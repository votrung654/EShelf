# EShelf - Enterprise eBook Platform

[![CI/CD Pipeline](https://github.com/votrung654/EShelf/actions/workflows/ci.yml/badge.svg)](https://github.com/votrung654/EShelf/actions)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/K8s-Ready-326CE5)](https://kubernetes.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Đồ án môn học NT548 - DevOps & MLOps**  
> **Trường Đại học Công nghệ Thông tin (UIT)**  
> Nền tảng đọc sách điện tử với kiến trúc microservices, CI/CD pipeline và MLOps.

<!-- Test PR Pipeline: This is a test change for Phase 1 validation -->

---

## Mục lục

- [Giới thiệu](#giới-thiệu)
- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [DevOps & MLOps](#devops--mlops)
- [Tài liệu](#tài-liệu)
- [Team](#team)

---

## Giới thiệu

**EShelf** là nền tảng đọc sách điện tử được xây dựng với kiến trúc microservices, áp dụng quy trình DevOps và MLOps.

### Tính năng chính

- Đọc sách PDF trực tuyến
- Tìm kiếm và lọc sách theo thể loại, tác giả
- Quản lý bộ sưu tập và sách yêu thích
- Theo dõi tiến độ đọc sách
- Gợi ý sách dựa trên AI/ML
- Admin panel (quản lý sách, người dùng, thể loại)

---

## Kiến trúc hệ thống

```
Frontend (React) → API Gateway → Microservices → Database
                                    │
                                    ├─ Auth Service
                                    ├─ Book Service
                                    ├─ User Service
                                    └─ ML Service
```

### Services

| Service | Port | Technology | Description |
|---------|------|------------|-------------|
| Frontend | 5173 | React 18 + Vite | Web UI |
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
- React 18, Vite, TailwindCSS, React Router

### Backend
- Node.js 20, Express.js, Prisma ORM, PostgreSQL, Redis

### ML/AI
- Python 3.11, FastAPI, scikit-learn

### DevOps
- **IaC:** Terraform, CloudFormation
- **CI/CD:** GitHub Actions, Jenkins, AWS CodePipeline
- **Containers:** Docker, Docker Compose
- **Orchestration:** Kubernetes (K3s/EKS)
- **GitOps:** ArgoCD
- **Registry:** Harbor
- **Monitoring:** Prometheus, Grafana, Loki, Alertmanager
- **Security:** Checkov, Trivy, SonarQube

---

## Quick Start

### Prerequisites

- Node.js >= 20
- Python >= 3.11
- Docker & Docker Compose

### Installation

```bash
# 1. Clone repository
git clone https://github.com/votrung654/EShelf.git
cd EShelf

# 2. (Tùy chọn) Tạo file .env nếu muốn custom database settings
cd backend
# Nếu có file .env.example, copy nó:
# cp .env.example .env
# Sau đó chỉnh sửa .env nếu cần

# 3. Start Backend (bao gồm database và migrations tự động)
docker-compose up -d

# Database migrations sẽ tự động chạy khi container khởi động
# Nếu gặp lỗi "relation does not exist", đợi vài giây để migrations hoàn tất
# Hoặc kiểm tra logs: docker-compose logs db-migration

# 4. Start Frontend
cd ..
npm install
npm run dev
```

**Lưu ý:** 
- Database migrations sẽ tự động chạy khi bạn start docker-compose
- Nếu services báo lỗi "table does not exist", đợi vài giây để migration service hoàn tất
- Kiểm tra logs: `docker-compose logs db-migration` để xem trạng thái migrations
- **Quan trọng về .env file:**
  - Nếu bạn có file `.env` trong `backend/`, docker-compose sẽ đọc các biến từ đó
  - Đảm bảo `DATABASE_URL` hoặc `POSTGRES_*` variables khớp với postgres service
  - Nếu `DATABASE_URL` trong `.env` khác với default, đảm bảo host là `postgres` (tên service)
  - Xem thêm: `backend/TROUBLESHOOTING.md` nếu gặp lỗi connection

### Access

- **Frontend:** http://localhost:5173
- **API Gateway:** http://localhost:3000
- **ML API Docs:** http://localhost:8000/docs

### Default Accounts

- **Admin:** `admin@EShelf.com` / `Admin123!`
- **User:** `user@EShelf.com` / `User123!`

---

## DevOps & MLOps

### Infrastructure as Code

- **Terraform:** K3s cluster (1 master + 2 workers) trên AWS
- **CloudFormation:** VPC, EC2, CodePipeline
- **Ansible:** K3s cluster setup và configuration management
- **Status:** Dev environment đã deploy thành công

### CI/CD Pipeline

- **GitHub Actions:**
  - **Smart Build System:** Chỉ build khi có code changes thực sự (tự động bỏ qua comment/whitespace changes)
    - Path-based filtering để detect service changes
    - Code change analysis để phân biệt comment vs code
    - Tiết kiệm thời gian và tài nguyên CI/CD
  - **Pull Request Pipeline:** Chỉ test, scan, lint (không deploy) khi tạo PR
  - **Push to Main Pipeline:** Build image, push to Harbor, deploy khi merge vào main
  - Frontend/Backend CI (lint, test, build)
  - Security scanning (Trivy, Checkov, SonarQube)
  - Code quality scanning với SonarQube
  - Terraform plan/apply cho 3 environments (dev, staging, prod)
  - MLOps workflows (model training, deployment)
  - Automated rollback
  - Update Kubernetes manifests với image tags từ Harbor registry

- **Jenkins:** Pipeline trên Kubernetes với SonarQube integration

- **AWS CodePipeline:** Automated deployment pipeline

### Kubernetes Deployment

- **K3s Cluster:** 3 nodes (1 master + 2 workers) trên AWS - Đã deploy
- **Kustomize:** Environment-specific overlays (dev, staging, prod)
- **ArgoCD:** GitOps deployment - Đã deploy và sẵn sàng
- **Harbor:** Container registry - Đã deploy và sẵn sàng
- **Monitoring Stack:** Prometheus, Grafana, Loki, Alertmanager - Đã deploy
- **Jenkins:** CI/CD pipeline trên Kubernetes (manifests sẵn sàng, chưa deploy)
- **SonarQube:** Code quality analysis (manifests sẵn sàng, chưa deploy)

### Monitoring Stack

- **Prometheus:** Metrics collection
- **Grafana:** Visualization dashboards
- **Loki:** Log aggregation
- **Alertmanager:** Alerting

### MLOps

- **MLflow:** Model tracking và registry (deployment ready)
- **Model Training:** Automated training pipeline (GitHub Actions)
- **Model Deployment:** Canary deployment với rollback

### Security

- **IaC Scanning:** Checkov cho Terraform/CloudFormation
- **Container Scanning:** Trivy cho Docker images
- **Code Quality:** SonarQube integration trong PR và Jenkins pipeline
- **Pre-deployment gates:** Security checks trước khi deploy

---

## Tài liệu

### Setup & Deployment
- [Setup Guide](docs/SETUP_GUIDE.md) - Hướng dẫn setup chi tiết
- [Next Steps](NEXT_STEPS.md) - Các bước sau khi đăng nhập AWS Console
- [Architecture](docs/ARCHITECTURE.md) - Kiến trúc hệ thống
- [Architecture Deep Dive](docs/ARCHITECTURE_DEEP_DIVE.md) - Chi tiết cơ chế hoạt động
- [Demo Guide](DEMO_GUIDE.md) - Hướng dẫn demo project

### Infrastructure Components
- [Ansible README](infrastructure/ansible/README.md) - K3s setup với Ansible
- [ArgoCD README](infrastructure/kubernetes/argocd/README.md) - GitOps deployment
- [Harbor README](infrastructure/kubernetes/harbor/README.md) - Container registry
- [MLOps README](infrastructure/kubernetes/mlops/README.md) - MLOps workflows
- [CodePipeline README](infrastructure/cloudformation/pipeline/README.md) - AWS CodePipeline

### Requirements & Analysis
- [Yêu cầu môn học](yeucaumonhoc.md) - Lab 1, Lab 2, Đồ án
- [Góp ý giảng viên](gopygiangvien.md) - Feedback và yêu cầu
- [Yêu cầu giảng viên analysis](YEU_CAU_GIANG_VIEN_ANALYSIS.md) - Phân tích yêu cầu chi tiết
- [Requirements Compliance](REQUIREMENTS_COMPLIANCE.md) - Đối chiếu yêu cầu

### Presentation & Study Materials
- [Presentation Slides Content](PRESENTATION_SLIDES_CONTENT.md) - Nội dung slide thuyết trình

### Scripts tiện ích

- `scripts/get-github-logs.ps1` - Lấy logs từ GitHub Actions (PowerShell)
- `scripts/get-github-logs.sh` - Lấy logs từ GitHub Actions (Bash)
- `scripts/check-service-changes.sh` - Smart build: Kiểm tra service có code changes thực sự
- `scripts/check-code-changes.sh` - Smart build: Kiểm tra file có code changes thực sự
- `scripts/test-changes.ps1` - Test script để validate tất cả thay đổi
- `scripts/test-smart-build.ps1` - Test smart build logic
- `scripts/test-fresh-clone.ps1` / `test-fresh-clone.sh` - **Test fresh clone**: Kiểm tra docker-compose setup đúng cho người mới clone repo

**Sử dụng:**
```bash
# PowerShell
.\scripts\get-github-logs.ps1

# Bash
chmod +x scripts/get-github-logs.sh
./scripts/get-github-logs.sh

# Test smart build locally
./scripts/check-service-changes.sh backend/services/api-gateway HEAD~1

# Test fresh clone (kiểm tra docker-compose setup cho người mới clone)
.\scripts\test-fresh-clone.ps1  # Windows
./scripts/test-fresh-clone.sh    # Linux/Mac

# Với GitHub CLI trực tiếp
gh run list --status failure
gh run view <RUN_ID> --log
gh run view <RUN_ID> --log --job <JOB_ID>
```

**Xem thêm:** 
- [Smart Build Documentation](scripts/README-SMART-BUILD.md)

---

## Team

| MSSV | Họ Tên | Phân công |
|------|--------|-----------|
| 22521571 | Võ Đình Trung | Frontend, Backend, ML Service, Database, CI/CD, Testing, Report|
| 23521809 | Lê Văn Vũ | Frontend, Backend, DevOps, Database, Testing, Video demo |
| 22521587 | Trương Phúc Trường | Backend, Infrastructure, CI/CD, Testing, Slide |

---

## License

MIT License - For educational purposes only.

