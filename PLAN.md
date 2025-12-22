# 📋 KẾ HOẠCH THỰC HIỆN ĐỒ ÁN - NHÓM 3 NGƯỜI

> **Đồ án môn học:** IE104 - DevOps & MLOps  
> **Dự án:** eShelf - Enterprise eBook Platform  
> **Thời gian:** 15 tuần  

---

## 👥 PHÂN CÔNG CÔNG VIỆC

### Thành viên 1: DevOps Engineer (Lead)
**Vai trò chính:** Infrastructure, CI/CD, Kubernetes

**Trách nhiệm:**
- Lab 1: Terraform & CloudFormation
- Lab 2: GitHub Actions, Jenkins Pipeline
- Kubernetes deployment & GitOps (ArgoCD)
- Monitoring & Logging (Prometheus, Grafana, Loki)
- Smart Build & Image Tagging automation

### Thành viên 2: Backend Developer
**Vai trò chính:** Microservices, Database, API

**Trách nhiệm:**
- Backend microservices (Auth, Book, User services)
- Database schema design & migrations (Prisma)
- API documentation
- Integration testing
- Docker containerization cho services

### Thành viên 3: Full-stack & ML Engineer
**Vai trò chính:** Frontend, ML/AI, MLOps

**Trách nhiệm:**
- Frontend enhancements & bug fixes
- ML Service (FastAPI) với recommendation system
- MLOps pipeline (MLflow, model training)
- Frontend-Backend integration
- E2E testing

---

## 📅 TIMELINE CHI TIẾT (15 TUẦN)

### 🔹 TUẦN 1-2: FOUNDATION & LAB 1 PREPARATION

#### Thành viên 1 (DevOps)
- [ ] Setup AWS account, tạo IAM users
- [ ] Tạo Terraform modules: VPC, Security Groups, EC2
- [ ] Viết test cases cho infrastructure
- [ ] Tạo CloudFormation templates tương đương
- [ ] Document infrastructure architecture

**Deliverables:**
- `infrastructure/terraform/` hoàn chỉnh
- `infrastructure/cloudformation/` hoàn chỉnh
- `scripts/test-infrastructure.sh`

#### Thành viên 2 (Backend)
- [ ] Hoàn thiện Auth Service (JWT, bcrypt)
- [ ] Hoàn thiện Book Service (CRUD, search)
- [ ] Hoàn thiện User Service (profile, favorites, collections)
- [ ] Setup PostgreSQL với Prisma schema
- [ ] Viết unit tests cho services

**Deliverables:**
- 3 backend services chạy được
- Database schema & migrations
- API documentation

#### Thành viên 3 (Frontend & ML)
- [ ] Fix frontend bugs
- [ ] Tạo ML Service với FastAPI
- [ ] Implement recommendation algorithm (basic)
- [ ] Implement similar books feature
- [ ] Tích hợp ML API vào frontend

**Deliverables:**
- Frontend không còn bugs
- ML Service với 2-3 endpoints
- Frontend components: SimilarBooks, RecommendedBooks

---

### 🔹 TUẦN 3-4: LAB 1 COMPLETION & LAB 2 START

#### Thành viên 1 (DevOps)
- [ ] Deploy infrastructure lên AWS với Terraform
- [ ] Test SSH to Bastion, Private EC2
- [ ] Verify NAT Gateway hoạt động
- [ ] Deploy infrastructure với CloudFormation
- [ ] Chạy test cases và document results
- [ ] **Nộp Lab 1**
- [ ] Setup GitHub Actions cho Terraform (Checkov scan)

**Deliverables:**
- Lab 1 hoàn thành (10 điểm)
- Infrastructure running trên AWS
- Test results documented

#### Thành viên 2 (Backend)
- [ ] Tích hợp Prisma với các services
- [ ] Migrate từ in-memory storage sang PostgreSQL
- [ ] Setup Redis caching
- [ ] Viết integration tests
- [ ] API Gateway routing hoàn chỉnh

**Deliverables:**
- Backend services kết nối database
- Redis caching hoạt động
- Integration tests pass

#### Thành viên 3 (Frontend & ML)
- [ ] Hoàn thiện frontend-backend integration
- [ ] Test authentication flow
- [ ] Test book CRUD từ admin panel
- [ ] Improve ML recommendation algorithm
- [ ] Add reading time estimation feature

**Deliverables:**
- Frontend hoàn toàn kết nối backend
- ML features hoạt động tốt

---

### 🔹 TUẦN 5-6: LAB 2 COMPLETION

#### Thành viên 1 (DevOps)
- [ ] Hoàn thiện GitHub Actions Terraform pipeline
- [ ] Setup AWS CodePipeline + CodeBuild
- [ ] Tích hợp cfn-lint và Taskcat
- [ ] Setup Jenkins server (trên EC2 hoặc K8s)
- [ ] Viết Jenkinsfile với stages: Lint, Test, Build, Scan, Deploy
- [ ] Tích hợp Trivy container scanning
- [ ] Tích hợp SonarQube code quality
- [ ] **Nộp Lab 2**

**Deliverables:**
- Lab 2 hoàn thành (10 điểm)
- 3 CI/CD pipelines hoạt động
- Security scanning reports

#### Thành viên 2 (Backend)
- [ ] Optimize database queries
- [ ] Add database indexes
- [ ] Setup connection pooling
- [ ] Implement rate limiting per service
- [ ] Add audit logging
- [ ] Document API với Swagger/OpenAPI

**Deliverables:**
- Backend performance optimized
- API documentation complete

#### Thành viên 3 (Frontend & ML)
- [ ] Add loading states và error handling
- [ ] Implement toast notifications
- [ ] Add form validations
- [ ] Setup E2E tests với Playwright
- [ ] Test ML service performance

**Deliverables:**
- Frontend UX improved
- E2E tests suite

---

### 🔹 TUẦN 7-8: KUBERNETES & GITOPS

#### Thành viên 1 (DevOps) - **TRỌNG TÂM**
- [ ] Setup K3s cluster với Ansible (hoặc EKS)
- [ ] Viết Kubernetes manifests (Deployments, Services, Ingress)
- [ ] Tạo Kustomize overlays (dev, staging, prod)
- [ ] Tạo Helm charts cho eShelf
- [ ] Setup ArgoCD cho GitOps
- [ ] Implement Smart Build (path-filter trong GitHub Actions)
- [ ] Implement Image Auto-Update (yq hoặc ArgoCD Image Updater)

**Deliverables:**
- K8s cluster running
- ArgoCD GitOps working
- Smart Build pipeline

#### Thành viên 2 (Backend)
- [ ] Containerize tất cả services
- [ ] Setup Harbor registry (hoặc ECR)
- [ ] Implement health checks cho K8s probes
- [ ] Add metrics endpoints (Prometheus format)
- [ ] Setup service mesh (optional: Istio/Linkerd)

**Deliverables:**
- All services K8s-ready
- Harbor registry running

#### Thành viên 3 (Frontend & ML)
- [ ] Containerize frontend
- [ ] Setup Nginx cho production
- [ ] Optimize bundle size
- [ ] Add service worker cho PWA
- [ ] ML model containerization

**Deliverables:**
- Frontend production-ready
- ML service K8s-ready

---

### 🔹 TUẦN 9-10: MONITORING & MLOPS

#### Thành viên 1 (DevOps)
- [ ] Setup Prometheus + Grafana stack
- [ ] Tạo dashboards (Application, Infrastructure, K8s)
- [ ] Setup Loki cho centralized logging
- [ ] Setup Alertmanager với Slack integration
- [ ] Configure alert rules
- [ ] Setup ELK stack (optional)

**Deliverables:**
- Monitoring stack hoàn chỉnh
- Dashboards & alerts

#### Thành viên 2 (Backend)
- [ ] Add Prometheus metrics to services
- [ ] Implement structured logging
- [ ] Add distributed tracing (Jaeger)
- [ ] Performance optimization
- [ ] Load testing với K6

**Deliverables:**
- Services instrumented
- Performance reports

#### Thành viên 3 (Frontend & ML) - **TRỌNG TÂM**
- [ ] Setup MLflow tracking server
- [ ] Implement ML training pipeline
- [ ] Model registry setup
- [ ] Automated model deployment
- [ ] ML monitoring (data drift, model performance)
- [ ] A/B testing cho ML models

**Deliverables:**
- MLOps pipeline hoàn chỉnh
- ML monitoring dashboards

---

### 🔹 TUẦN 11-12: ADVANCED DEVOPS

#### Thành viên 1 (DevOps) - **TRỌNG TÂM**
- [ ] Implement Blue/Green deployment
- [ ] Implement Canary deployment với Flagger
- [ ] Setup Ansible cho configuration management
- [ ] Setup AWS Secrets Manager
- [ ] Implement backup & disaster recovery
- [ ] Document rollback procedures

**Deliverables:**
- Advanced deployment strategies
- DR plan documented

#### Thành viên 2 (Backend)
- [ ] Implement circuit breaker pattern
- [ ] Add retry logic
- [ ] Implement graceful shutdown
- [ ] Database backup automation
- [ ] Security hardening

**Deliverables:**
- Production-ready backend
- Security audit passed

#### Thành viên 3 (Frontend & ML)
- [ ] Performance optimization
- [ ] Accessibility improvements
- [ ] SEO optimization
- [ ] ML model versioning
- [ ] Model performance comparison

**Deliverables:**
- Frontend optimized
- ML models versioned

---

### 🔹 TUẦN 13-14: INTEGRATION & TESTING

#### Cả nhóm cùng làm:
- [ ] End-to-end testing toàn hệ thống
- [ ] Security testing (OWASP ZAP)
- [ ] Load testing
- [ ] Fix bugs phát hiện
- [ ] Performance tuning
- [ ] Documentation hoàn thiện

**Deliverables:**
- Hệ thống stable
- All tests passing
- Documentation complete

---

### 🔹 TUẦN 15: DEMO PREPARATION

#### Thành viên 1 (DevOps)
- [ ] Prepare architecture diagrams
- [ ] Prepare CI/CD flow diagrams
- [ ] Demo script cho infrastructure
- [ ] Demo script cho GitOps
- [ ] Record backup video

#### Thành viên 2 (Backend)
- [ ] Prepare API demo
- [ ] Prepare database schema presentation
- [ ] Demo script cho microservices
- [ ] Performance metrics slides

#### Thành viên 3 (Frontend & ML)
- [ ] Prepare frontend demo
- [ ] Prepare ML features demo
- [ ] Demo script cho MLOps pipeline
- [ ] User flow demonstration

#### Cả nhóm:
- [ ] Rehearse demo (2-3 lần)
- [ ] Prepare Q&A answers
- [ ] Finalize slides
- [ ] Submit final report

---

## 🎯 YÊU CẦU MÔN HỌC

### Lab 1: Infrastructure as Code (10 điểm)

| Yêu cầu | Điểm | Người phụ trách |
|---------|------|-----------------|
| VPC, Subnets, IGW | 3 | Thành viên 1 |
| Route Tables, NAT Gateway | 2 | Thành viên 1 |
| EC2 Public + Private | 2 | Thành viên 1 |
| Security Groups | 2 | Thành viên 1 |
| Test Cases | 1 | Thành viên 1 |

**Deadline:** Tuần 4

### Lab 2: CI/CD Automation (10 điểm)

| Yêu cầu | Điểm | Người phụ trách |
|---------|------|-----------------|
| Terraform + GitHub Actions + Checkov | 3 | Thành viên 1 |
| CloudFormation + CodePipeline + cfn-lint | 3 | Thành viên 1 |
| Jenkins + Docker/K8s + Trivy/SonarQube | 4 | Thành viên 1 (lead), Thành viên 2 (support) |

**Deadline:** Tuần 6

---

## 🔥 ĐIỂM NHẤN THEO GÓP Ý GIẢNG VIÊN

### 1. Smart Build (Quan trọng!)

**Vấn đề:** Khi sửa 1 service, không build lại toàn bộ

**Giải pháp:**
```yaml
# .github/workflows/smart-build.yml
- uses: dorny/paths-filter@v2
  id: changes
  with:
    filters: |
      auth-service:
        - 'backend/services/auth-service/**'
      book-service:
        - 'backend/services/book-service/**'

- if: steps.changes.outputs.auth-service == 'true'
  run: docker build backend/services/auth-service
```

**Người thực hiện:** Thành viên 1 (Tuần 7-8)

### 2. GitOps & Image Auto-Update (Quan trọng!)

**Flow:**
```
Code change → Build image → Push to Harbor → 
Update YAML với yq → Commit to config repo → 
ArgoCD sync → Deploy to K8s
```

**Tools:**
- `yq` để update image tag trong YAML
- ArgoCD Image Updater (hoặc Flux)
- Harbor registry thay vì DockerHub

**Người thực hiện:** Thành viên 1 (Tuần 7-8)

### 3. Môi trường Dev/Staging/Prod

**Yêu cầu:** Tối thiểu 2, tốt nhất 3 môi trường

**Cấu trúc:**
```
infrastructure/kubernetes/overlays/
├── dev/
├── staging/
└── prod/
```

**Người thực hiện:** Thành viên 1 + 2 (Tuần 7-8)

### 4. Kubernetes Cluster (3 nodes minimum)

**Lựa chọn:**
- **Option A:** EKS (dễ, tốn tiền) - Recommended nếu có AWS credit
- **Option B:** K3s trên EC2 với Ansible (khó hơn, hiểu sâu hơn)

**Quyết định:** Chọn Option A (EKS) để tiết kiệm thời gian

**Người thực hiện:** Thành viên 1 (Tuần 7)

### 5. Artifact Management

**Yêu cầu:** Không dùng DockerHub public

**Giải pháp:** Setup Harbor registry

**Người thực hiện:** Thành viên 1 + 2 (Tuần 7)

---

## 📊 CHECKLIST THEO TUẦN

### Tuần 1-2: Foundation
- [ ] **T1:** Backend services hoàn chỉnh (Auth, Book, User)
- [ ] **T1:** Terraform VPC module
- [ ] **T1:** Terraform Security Groups module
- [ ] **T2:** Database schema & Prisma setup
- [ ] **T2:** Terraform EC2 module
- [ ] **T3:** ML Service basic setup
- [ ] **T3:** Frontend bug fixes

### Tuần 3-4: Lab 1
- [ ] **T1:** Deploy Terraform lên AWS
- [ ] **T1:** Test infrastructure (SSH, NAT)
- [ ] **T1:** CloudFormation templates
- [ ] **T1:** Document Lab 1
- [ ] **T2:** Database migrations
- [ ] **T2:** Backend integration tests
- [ ] **T3:** Frontend-Backend integration
- [ ] **Cả nhóm:** Review Lab 1, nộp bài

### Tuần 5-6: Lab 2
- [ ] **T1:** GitHub Actions Terraform pipeline
- [ ] **T1:** AWS CodePipeline setup
- [ ] **T1:** Jenkins setup & Jenkinsfile
- [ ] **T1:** Trivy & SonarQube integration
- [ ] **T2:** Dockerfiles cho tất cả services
- [ ] **T2:** Docker Compose production config
- [ ] **T3:** E2E tests với Playwright
- [ ] **Cả nhóm:** Review Lab 2, nộp bài

### Tuần 7-8: Kubernetes & GitOps
- [ ] **T1:** Setup EKS cluster (hoặc K3s)
- [ ] **T1:** Kubernetes manifests
- [ ] **T1:** ArgoCD setup
- [ ] **T1:** Smart Build implementation
- [ ] **T1:** Image auto-update mechanism
- [ ] **T2:** Harbor registry setup
- [ ] **T2:** Services health checks
- [ ] **T3:** Frontend containerization
- [ ] **T3:** ML service K8s deployment

### Tuần 9-10: Monitoring & MLOps
- [ ] **T1:** Prometheus + Grafana setup
- [ ] **T1:** Loki logging stack
- [ ] **T1:** Alertmanager configuration
- [ ] **T2:** Add metrics to services
- [ ] **T2:** Structured logging
- [ ] **T3:** MLflow setup
- [ ] **T3:** ML training pipeline
- [ ] **T3:** Model monitoring

### Tuần 11-12: Advanced Features
- [ ] **T1:** Blue/Green deployment
- [ ] **T1:** Canary deployment (Flagger)
- [ ] **T1:** Ansible playbooks
- [ ] **T2:** Circuit breaker pattern
- [ ] **T2:** Database backup automation
- [ ] **T3:** ML A/B testing
- [ ] **T3:** Model versioning

### Tuần 13-14: Testing & Polish
- [ ] **Cả nhóm:** End-to-end testing
- [ ] **Cả nhóm:** Security testing (OWASP ZAP)
- [ ] **Cả nhóm:** Load testing
- [ ] **Cả nhóm:** Bug fixes
- [ ] **Cả nhóm:** Documentation
- [ ] **Cả nhóm:** Code cleanup

### Tuần 15: Demo Preparation
- [ ] **T1:** Architecture diagrams
- [ ] **T1:** CI/CD flow diagrams
- [ ] **T2:** API demo preparation
- [ ] **T3:** Frontend & ML demo
- [ ] **Cả nhóm:** Slides preparation
- [ ] **Cả nhóm:** Demo rehearsal (3 lần)
- [ ] **Cả nhóm:** Record backup video
- [ ] **Cả nhóm:** Q&A preparation

---

## 🎬 NỘI DUNG DEMO (15-20 phút)

### Part 1: Giới thiệu (2 phút) - Thành viên 3
- Problem statement
- Solution overview
- Tech stack highlights

### Part 2: Application Demo (5 phút) - Thành viên 3
- User flow: Browse → Search → Read
- ML recommendations demo
- Admin panel features

### Part 3: Infrastructure & IaC (3 phút) - Thành viên 1
- AWS infrastructure overview
- Terraform modules explanation
- CloudFormation comparison

### Part 4: CI/CD Pipeline (5 phút) - Thành viên 1
- GitHub Actions demo
- Jenkins pipeline demo
- Smart Build demonstration
- GitOps with ArgoCD

### Part 5: Kubernetes & Monitoring (3 phút) - Thành viên 1
- K8s cluster overview
- Deployment strategies (Blue/Green, Canary)
- Grafana dashboards

### Part 6: Backend & Database (2 phút) - Thành viên 2
- Microservices architecture
- Database schema
- API endpoints

### Part 7: MLOps (2 phút) - Thành viên 3
- ML pipeline
- MLflow tracking
- Model deployment

### Part 8: Q&A (3 phút) - Cả nhóm

---

## 📝 DELIVERABLES

### Lab 1 (Tuần 4)
- [ ] Báo cáo Word theo mẫu
- [ ] Source code trên GitHub
- [ ] README.md hướng dẫn chạy
- [ ] Test results screenshots
- [ ] Architecture diagram

### Lab 2 (Tuần 6)
- [ ] Báo cáo Word theo mẫu
- [ ] Source code với CI/CD configs
- [ ] Pipeline execution screenshots
- [ ] Security scan reports
- [ ] README.md updated

### Đồ án cuối kỳ (Tuần 15)
- [ ] Báo cáo đầy đủ (Word/PDF)
- [ ] Source code hoàn chỉnh
- [ ] Demo video (backup)
- [ ] Slides presentation
- [ ] Architecture diagrams
- [ ] API documentation
- [ ] Deployment guide
- [ ] Troubleshooting guide

---

## 🚨 RỦI RO & GIẢI PHÁP

| Rủi ro | Giải pháp | Người xử lý |
|---------|-----------|-------------|
| AWS credit hết sớm | Dùng Free Tier, tắt resources khi không dùng | Thành viên 1 |
| Service không kết nối được | Docker networking, check firewall rules | Thành viên 2 |
| ML model không chính xác | Dùng simple algorithm trước, improve sau | Thành viên 3 |
| Demo bị lỗi | Có video backup, test trước 3 lần | Cả nhóm |
| Không đủ thời gian | Ưu tiên Lab 1, 2 trước, features sau | Cả nhóm |

---

## 💡 TIPS QUAN TRỌNG

### Cho Thành viên 1 (DevOps)
1. **Làm Lab 1, 2 sớm** - Đây là điểm bắt buộc
2. **Document mọi thứ** - Giảng viên sẽ hỏi chi tiết
3. **Test infrastructure thường xuyên** - Tránh bất ngờ
4. **Backup configs** - Git commit thường xuyên
5. **Smart Build là điểm cộng lớn** - Ưu tiên làm

### Cho Thành viên 2 (Backend)
1. **API phải hoạt động tốt** - Frontend phụ thuộc vào backend
2. **Database schema phải chuẩn** - Khó sửa sau này
3. **Write tests** - Tránh regression bugs
4. **Document API** - Giúp frontend dev dễ dàng
5. **Health checks quan trọng** - K8s cần để check service

### Cho Thành viên 3 (Frontend & ML)
1. **Frontend phải đẹp và mượt** - Ấn tượng đầu tiên
2. **ML không cần quá phức tạp** - Simple algorithm nhưng hoạt động tốt
3. **MLOps pipeline quan trọng hơn model accuracy** - Focus vào automation
4. **Demo ML features rõ ràng** - Show được value của ML
5. **E2E tests giúp tìm bugs sớm** - Đầu tư vào testing

---

## 📞 COMMUNICATION

### Daily Standup (10 phút mỗi ngày)
- Hôm qua làm gì?
- Hôm nay làm gì?
- Có vướng mắc gì không?

### Weekly Review (30 phút cuối tuần)
- Review progress
- Demo features mới
- Plan tuần tới
- Update timeline nếu cần

### Tools
- **GitHub:** Code repository & Issues
- **Discord/Slack:** Daily communication
- **Google Docs:** Shared documentation
- **Notion/Trello:** Task management

---

## ✅ DEFINITION OF DONE

### Cho mỗi feature:
- [ ] Code hoàn thành và tested
- [ ] Documentation updated
- [ ] Merged vào main branch
- [ ] Deployed và verified
- [ ] Demo-ready

### Cho mỗi Lab:
- [ ] Tất cả requirements đáp ứng
- [ ] Tests pass
- [ ] Documentation complete
- [ ] Báo cáo hoàn thành
- [ ] Reviewed bởi cả nhóm

---

## 🎓 HỌC TỪ GÓP Ý GIẢNG VIÊN

### Điều giảng viên muốn thấy:
1. ✅ **Chuyên nghiệp** - Không chỉ "chạy được"
2. ✅ **Bảo mật** - Security best practices
3. ✅ **Tối ưu** - Performance & efficiency
4. ✅ **Smart Build** - Chỉ build service thay đổi
5. ✅ **GitOps** - Automated deployment
6. ✅ **Monitoring** - Observability stack
7. ✅ **Rollback** - Disaster recovery plan

### Điều giảng viên KHÔNG muốn thấy:
1. ❌ Hardcode values
2. ❌ Chạy local đơn giản
3. ❌ Không có tests
4. ❌ Không có monitoring
5. ❌ Manual deployment
6. ❌ Không có rollback plan

---

## 📚 TÀI LIỆU THAM KHẢO

### Infrastructure
- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [k3s-ansible](https://github.com/k3s-io/k3s-ansible)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

### CI/CD
- [GitHub Actions Examples](https://github.com/actions/starter-workflows)
- [Jenkins on Kubernetes](https://www.jenkins.io/doc/book/installing/kubernetes/)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)

### Monitoring
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Loki Setup Guide](https://grafana.com/docs/loki/latest/setup/)

### MLOps
- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [Kubeflow Pipelines](https://www.kubeflow.org/docs/components/pipelines/)

---

## 🎯 SUCCESS METRICS

### Technical Metrics
- [ ] All services running stable
- [ ] 95%+ uptime
- [ ] API response time < 200ms
- [ ] Zero critical security issues
- [ ] Test coverage > 70%

### Project Metrics
- [ ] Lab 1: 10/10 điểm
- [ ] Lab 2: 10/10 điểm
- [ ] Đồ án: Điểm cao (9-10)
- [ ] Demo thành công
- [ ] Giảng viên hài lòng

---

**Lưu ý:** Kế hoạch này có thể điều chỉnh dựa trên tiến độ thực tế và feedback từ giảng viên.

**Liên hệ:** Họp nhóm mỗi tuần để sync progress và adjust plan.

---

*Cập nhật lần cuối: Tháng 12/2024*

