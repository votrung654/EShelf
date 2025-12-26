# Dàn Bài Thuyết Trình eShelf Project

## Slide 1: Title Slide
- **Tiêu đề:** eShelf - Enterprise eBook Platform
- **Phụ đề:** Microservices Architecture với DevOps & MLOps
- **Thông tin:** NT548 - DevOps & MLOps, UIT
- **Team members**

## Slide 2: Tổng Quan Project
- **Vấn đề:** Nền tảng đọc sách điện tử cần scalability và maintainability
- **Giải pháp:** Microservices architecture với DevOps practices
- **Mục tiêu:** 
  - High availability
  - Scalability
  - Fast deployment
  - Continuous integration

## Slide 3: Kiến Trúc Hệ Thống
- **Diagram:** System architecture
- **Components:**
  - Frontend (React)
  - API Gateway
  - Microservices (Auth, Book, User, ML)
  - Database (PostgreSQL)
  - Cache (Redis)

## Slide 4: Microservices Chi Tiết
- **Auth Service:** Authentication, authorization
- **Book Service:** Book CRUD, search
- **User Service:** User profile, favorites, collections
- **ML Service:** Recommendations, similarity
- **Communication:** HTTP/REST

## Slide 5: Technology Stack
- **Frontend:** React 18, Vite, TailwindCSS
- **Backend:** Node.js, Express.js, Prisma
- **ML:** Python, FastAPI, scikit-learn
- **Database:** PostgreSQL, Redis
- **DevOps:** Docker, Kubernetes, Terraform
- **CI/CD:** GitHub Actions, Jenkins

## Slide 6: Infrastructure as Code
- **Terraform:** 
  - VPC, Subnets
  - EC2 instances
  - Security groups
- **CloudFormation:**
  - CodePipeline
  - Stack templates
- **Ansible:**
  - K3s setup
  - Configuration

## Slide 7: CI/CD Pipeline
- **GitHub Actions:**
  - PR: Test, lint, scan
  - Push: Build, push, deploy
  - Smart build system
- **Jenkins:** Pipeline trên Kubernetes
- **AWS CodePipeline:** Automated deployment

## Slide 8: Containerization
- **Docker:** 
  - Multi-stage builds
  - Non-root users
  - Health checks
- **Docker Compose:** Local development
- **Kubernetes:** Production deployment

## Slide 9: Kubernetes Deployment
- **K3s Cluster:** Lightweight K8s
- **Kustomize:** Environment management
- **ArgoCD:** GitOps deployment
- **Harbor:** Container registry

## Slide 10: Monitoring Stack
- **Prometheus:** Metrics collection
- **Grafana:** Visualization
- **Loki:** Log aggregation
- **Alertmanager:** Alerting

## Slide 11: Security
- **Container Security:** Scanning, non-root
- **Secrets Management:** Environment variables, K8s secrets
- **Network Security:** VPC, security groups
- **Code Quality:** SonarQube

## Slide 12: MLOps
- **ML Service:** FastAPI
- **Model Training:** Automated pipeline
- **Model Deployment:** Canary, rollback
- **MLflow:** Model tracking

## Slide 13: Demo
- **Local Development:** Docker Compose
- **CI/CD Flow:** GitHub Actions
- **Kubernetes Deployment:** ArgoCD
- **Monitoring:** Grafana dashboards

## Slide 14: Challenges & Solutions
- **Challenge 1:** Service communication
  - Solution: API Gateway, HTTP/REST
- **Challenge 2:** Database management
  - Solution: Prisma migrations, auto-build
- **Challenge 3:** Deployment complexity
  - Solution: GitOps với ArgoCD

## Slide 15: Best Practices
- **Microservices:**
  - Single responsibility
  - Independent deployment
  - API-first design
- **DevOps:**
  - Infrastructure as Code
  - Automated testing
  - Continuous deployment
- **Security:**
  - Least privilege
  - Secrets management
  - Regular scanning

## Slide 16: Future Improvements
- **Service Mesh:** Istio hoặc Linkerd
- **Event-Driven:** Message queues
- **Database per Service:** Complete separation
- **Advanced Monitoring:** Distributed tracing

## Slide 17: Lessons Learned
- **Microservices:** Cần planning tốt
- **CI/CD:** Automation là key
- **Monitoring:** Critical cho production
- **Documentation:** Quan trọng cho team

## Slide 18: Q&A
- **Questions?**
- **Contact:** GitHub repository
- **Thank you!**

## Slide 19: References
- **Documentation:** README, guides
- **Code:** GitHub repository
- **Architecture:** Diagrams trong docs
- **Best Practices:** Industry standards

## Slide 20: Appendix - Architecture Diagrams
- **System Architecture:** High-level
- **Microservices:** Service details
- **CI/CD Flow:** Pipeline diagram
- **Kubernetes:** Deployment diagram

