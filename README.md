# eShelf - Enterprise eBook Platform

[![CI/CD Pipeline](https://github.com/levanvux/eShelf/workflows/CI/badge.svg)](https://github.com/levanvux/eShelf/actions)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/K8s-Ready-326CE5)](https://kubernetes.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Đồ án môn học NT548 - DevOps & MLOps**  
> **Trường Đại học Công nghệ Thông tin (UIT)**  
> Nền tảng đọc sách điện tử với kiến trúc microservices, CI/CD pipeline và MLOps.

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

**eShelf** là nền tảng đọc sách điện tử được xây dựng với kiến trúc microservices, áp dụng quy trình DevOps và MLOps.

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
git clone https://github.com/your-org/eShelf.git
cd eShelf

# 2. Start Backend
cd backend
docker-compose up -d

# 3. Start Frontend
cd ..
npm install
npm run dev
```

### Access

- **Frontend:** http://localhost:5173
- **API Gateway:** http://localhost:3000
- **ML API Docs:** http://localhost:8000/docs

### Default Accounts

- **Admin:** `admin@eshelf.com` / `Admin123!`
- **User:** `user@eshelf.com` / `User123!`

---

## DevOps & MLOps

### Infrastructure as Code

- **Terraform:** 3-node K3s cluster (1 master + 2 workers) trên AWS
- **CloudFormation:** VPC, EC2, CodePipeline
- **Ansible:** K3s cluster setup và configuration management

### CI/CD Pipeline

- **GitHub Actions:**
  - Smart Build (chỉ build service thay đổi)
  - Frontend/Backend CI (lint, test, build)
  - Security scanning (Trivy, Checkov)
  - Terraform plan/apply
  - MLOps workflows (model training, deployment)
  - Deploy với rollback

- **AWS CodePipeline:** Automated deployment pipeline

### Kubernetes Deployment

- **K3s Cluster:** 3 nodes (1 master + 2 workers)
- **Kustomize:** Staging/Prod overlays
- **ArgoCD:** GitOps deployment
- **Harbor:** Container registry

### Monitoring Stack

- **Prometheus:** Metrics collection
- **Grafana:** Visualization dashboards
- **Loki:** Log aggregation
- **Alertmanager:** Alerting

### MLOps

- **MLflow:** Model tracking và registry
- **Model Training:** Automated training pipeline
- **Model Deployment:** Canary deployment với rollback

### Security

- **IaC Scanning:** Checkov
- **Container Scanning:** Trivy
- **Code Quality:** SonarQube

---

## Tài liệu

- [Setup Guide](docs/SETUP_GUIDE.md) - Hướng dẫn setup chi tiết
- [Architecture](docs/ARCHITECTURE.md) - Kiến trúc hệ thống
- [Ansible README](infrastructure/ansible/README.md) - K3s setup với Ansible
- [ArgoCD README](infrastructure/kubernetes/argocd/README.md) - GitOps deployment
- [Harbor README](infrastructure/kubernetes/harbor/README.md) - Container registry
- [MLOps README](infrastructure/kubernetes/mlops/README.md) - MLOps workflows
- [CodePipeline README](infrastructure/cloudformation/pipeline/README.md) - AWS CodePipeline
- [Yêu cầu môn học](yeucaumonhoc.md) - Lab 1, Lab 2, Đồ án
- [Góp ý giảng viên](gopygiangvien.md) - Feedback và yêu cầu

---

## Team

| MSSV | Họ Tên | Phân công |
|------|--------|-----------|
| 23521809 | Lê Văn Vũ | Frontend, Backend, DevOps |
| 22521571 | Võ Đình Trung | Backend, ML Service, Database |
| 22521587 | Trương Phúc Trường | Infrastructure, CI/CD, Testing |

---

## License

MIT License - For educational purposes only.

---

## Contact

**Lê Văn Vũ** - [GitHub](https://github.com/levanvux)
