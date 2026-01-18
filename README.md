# eShelf - Enterprise eBook Platform

<div align="center">

[![CI/CD Pipeline](https://github.com/votrung654/EShelf/actions/workflows/ci.yml/badge.svg)](https://github.com/votrung654/EShelf/actions)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/K8s-Ready-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-20-339933?logo=node.js)](https://nodejs.org/)
[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react)](https://react.dev/)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python)](https://www.python.org/)

**A modern microservices-based eBook platform with DevOps & MLOps practices**

[Features](#-features) • [Quick Start](#-quick-start) • [Architecture](#-architecture) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 📖 About

**eShelf** is an enterprise-grade eBook reading platform built with microservices architecture, implementing modern DevOps and MLOps practices. This project demonstrates a production-ready application with CI/CD pipelines, container orchestration, infrastructure as code, and machine learning integration.

> **Academic Project** - NT548 DevOps & MLOps Course  
> **University of Information Technology (UIT)**

---

## ✨ Features

### Core Functionality
- 📚 **Online PDF Reader** - Read books directly in your browser
- 🔍 **Advanced Search** - Search and filter books by genre, author, title
- 📖 **Reading Progress** - Track your reading progress automatically
- ❤️ **Collections & Favorites** - Organize your personal library
- 🤖 **AI Recommendations** - ML-powered book suggestions
- 👨‍💼 **Admin Panel** - Manage books, users, and categories

### Technical Highlights
- 🏗️ **Microservices Architecture** - Scalable and maintainable
- 🚀 **CI/CD Pipelines** - Automated testing, building, and deployment
- ☸️ **Kubernetes Ready** - Container orchestration with K3s
- 🔒 **Security First** - Automated security scanning and code quality checks
- 📊 **Monitoring & Observability** - Prometheus, Grafana, and Loki integration
- 🤖 **MLOps Integration** - Automated model training and deployment

---

## 🏗️ Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (React + Vite)                   │
│                      Port: 5173                              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  API Gateway (Express.js)                    │
│                      Port: 3000                              │
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
        ┌───────────┴───────────┐
        ▼                       ▼
┌──────────────┐        ┌──────────────┐
│  PostgreSQL   │        │    Redis     │
│   Port: 5432  │        │   Port: 6379 │
└──────────────┘        └──────────────┘
```

### Services

| Service | Port | Technology | Description |
|---------|------|------------|-------------|
| **Frontend** | 5173 | React 18 + Vite | Modern web UI with TailwindCSS |
| **API Gateway** | 3000 | Express.js | API routing, rate limiting, load balancing |
| **Auth Service** | 3001 | Express.js + Prisma | JWT authentication & authorization |
| **Book Service** | 3002 | Express.js + Prisma | Book CRUD operations, search, filtering |
| **User Service** | 3003 | Express.js | User profiles, favorites, collections |
| **ML Service** | 8000 | FastAPI + scikit-learn | Book recommendations, similarity search |
| **PostgreSQL** | 5432 | PostgreSQL 16 | Primary database |
| **Redis** | 6379 | Redis 7 | Caching layer |

---

## 🛠️ Tech Stack

### Frontend
- **React 18** - UI library
- **Vite** - Build tool
- **TailwindCSS** - Styling
- **React Router** - Routing
- **React PDF** - PDF viewer

### Backend
- **Node.js 20** - Runtime
- **Express.js** - Web framework
- **Prisma ORM** - Database toolkit
- **PostgreSQL 16** - Primary database
- **Redis 7** - Caching

### ML/AI
- **Python 3.11** - ML runtime
- **FastAPI** - API framework
- **scikit-learn** - Machine learning library

### DevOps & Infrastructure
- **IaC:** Terraform, AWS CloudFormation, Ansible
- **CI/CD:** GitHub Actions, Jenkins, AWS CodePipeline
- **Containers:** Docker, Docker Compose
- **Orchestration:** Kubernetes (K3s)
- **GitOps:** ArgoCD
- **Registry:** Harbor
- **Monitoring:** Prometheus, Grafana, Loki, Alertmanager
- **Security:** Checkov, Trivy, SonarQube

---

## 🚀 Quick Start

### Prerequisites

- **Node.js** >= 20
- **Python** >= 3.11
- **Docker** & **Docker Compose**
- **Git**

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/votrung654/EShelf.git
   cd EShelf
   ```

2. **Start Backend Services**
   ```bash
   cd backend
   docker-compose up -d
   ```
   
   This will automatically:
   - Start PostgreSQL database
   - Run database migrations
   - Start all microservices
   - Seed initial data

3. **Start Frontend**
   ```bash
   cd ..
   npm install
   npm run dev
   ```

### Access Points

- **Frontend:** http://localhost:5173
- **API Gateway:** http://localhost:3000
- **ML API Docs:** http://localhost:8000/docs

### Default Accounts

- **Admin:** `admin@EShelf.com` / `Admin123!`
- **User:** `user@EShelf.com` / `User123!`

### Troubleshooting

If you encounter "table does not exist" errors:
- Wait a few seconds for migrations to complete
- Check migration logs: `docker-compose logs db-migration`
- See [Troubleshooting Guide](backend/TROUBLESHOOTING.md) for more details

---

## 🔄 DevOps & MLOps

### Infrastructure as Code

- **Terraform** - K3s cluster (1 master + 2 workers) on AWS
- **CloudFormation** - VPC, EC2, CodePipeline stacks
- **Ansible** - K3s cluster setup and configuration management
- **Status:** Dev environment successfully deployed

### CI/CD Pipeline

#### GitHub Actions

- **Smart Build System** - Only builds when actual code changes are detected
  - Path-based filtering for service changes
  - Code change analysis (ignores comments/whitespace)
  - Resource-efficient CI/CD

- **Pull Request Pipeline**
  - Lint, test, and security scanning
  - No deployment (validation only)

- **Main Branch Pipeline**
  - Build Docker images
  - Push to Harbor registry
  - Deploy to Kubernetes
  - Update manifests with image tags

- **Security & Quality**
  - Trivy container scanning
  - Checkov IaC scanning
  - SonarQube code quality analysis

- **MLOps Workflows**
  - Automated model training
  - Model deployment with canary strategy
  - Automated rollback on failure

#### Other CI/CD Tools

- **Jenkins** - Pipeline on Kubernetes with SonarQube integration
- **AWS CodePipeline** - Automated deployment pipeline

### Kubernetes Deployment

- **K3s Cluster** - 3 nodes (1 master + 2 workers) on AWS ✅
- **Kustomize** - Environment-specific overlays (dev, staging, prod)
- **ArgoCD** - GitOps deployment ✅
- **Harbor** - Container registry ✅
- **Monitoring Stack** - Prometheus, Grafana, Loki, Alertmanager ✅

### Monitoring & Observability

- **Prometheus** - Metrics collection
- **Grafana** - Visualization dashboards
- **Loki** - Log aggregation
- **Alertmanager** - Alerting

### MLOps

- **MLflow** - Model tracking and registry
- **Automated Training** - GitHub Actions pipeline
- **Canary Deployment** - Gradual rollout with rollback capability

### Security

- **IaC Scanning** - Checkov for Terraform/CloudFormation
- **Container Scanning** - Trivy for Docker images
- **Code Quality** - SonarQube integration
- **Pre-deployment Gates** - Security checks before deployment

---

## 📚 Documentation

### Setup & Deployment
- [Setup Guide](docs/SETUP_GUIDE.md) - Detailed setup instructions
- [Quick Start AWS](docs/QUICK_START_AWS.md) - AWS deployment guide
- [Setup Without AWS](docs/SETUP_WITHOUT_AWS.md) - Local development setup
- [Architecture](docs/ARCHITECTURE.md) - System architecture overview
- [Architecture Deep Dive](docs/ARCHITECTURE_DEEP_DIVE.md) - Detailed architecture
- [Demo Guide](docs/DEMO_GUIDE.md) - Project demonstration guide

### Infrastructure Components
- [Ansible README](infrastructure/ansible/README.md) - K3s setup with Ansible
- [ArgoCD README](infrastructure/kubernetes/argocd/README.md) - GitOps deployment
- [Harbor README](infrastructure/kubernetes/harbor/README.md) - Container registry
- [MLOps README](infrastructure/kubernetes/mlops/README.md) - MLOps workflows
- [CodePipeline README](infrastructure/cloudformation/pipeline/README.md) - AWS CodePipeline

### Scripts & Utilities
- [Smart Build Documentation](scripts/README-SMART-BUILD.md) - CI/CD optimization
- [Tools and Configuration Guide](docs/TOOLS_AND_CONFIGURATION.md) - Chi tiết các công cụ, cấu hình và quy trình tích hợp
- Various utility scripts in `scripts/` directory

---

## 👥 Team

| MSSV | Name | Responsibilities |
|------|------|------------------|
| 22521571 | Võ Đình Trung | Frontend, Backend, ML Service, Database, CI/CD, Testing, Report |
| 23521809 | Lê Văn Vũ | Frontend, Backend, DevOps, Database, Testing, Video demo |
| 22521587 | Trương Phúc Trường | Backend, Infrastructure, CI/CD, Testing, Slide |

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Code of conduct
- Development setup
- Pull request process
- Coding standards

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Note:** This project is for educational purposes only.

---

## 🔗 Links

- [GitHub Repository](https://github.com/votrung654/EShelf)
- [CI/CD Pipeline](https://github.com/votrung654/EShelf/actions)
- [Issues](https://github.com/votrung654/EShelf/issues)
- [Pull Requests](https://github.com/votrung654/EShelf/pulls)

---

<div align="center">

**Made with ❤️ by UIT Students**

⭐ Star this repo if you find it helpful!

</div>
