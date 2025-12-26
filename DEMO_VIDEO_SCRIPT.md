# Kịch Bản Quay Video Demo eShelf Project

## Tổng Quan

Kịch bản chi tiết để quay video demo từ A-Z cho project eShelf, tập trung vào kiến trúc microservices và DevOps practices.

**Thời lượng dự kiến:** 20-25 phút
**Đối tượng:** Giảng viên và sinh viên môn DevOps & MLOps

---

## Phần 1: Giới Thiệu Project (2 phút)

### Slide 1: Title
- **Nói:** "Xin chào, tôi là [Tên]. Hôm nay tôi sẽ trình bày về project eShelf - một nền tảng đọc sách điện tử được xây dựng với kiến trúc microservices và áp dụng quy trình DevOps."

### Slide 2: Tổng Quan
- **Nói:** "eShelf là nền tảng cho phép người dùng đọc sách PDF trực tuyến, tìm kiếm sách, quản lý bộ sưu tập, và nhận gợi ý sách dựa trên AI/ML."
- **Show:** Screenshot của frontend

### Slide 3: Tech Stack
- **Nói:** "Project sử dụng React cho frontend, Node.js cho backend services, PostgreSQL cho database, và FastAPI cho ML service. Infrastructure được quản lý bằng Terraform, Kubernetes cho orchestration, và ArgoCD cho GitOps."

---

## Phần 2: Kiến Trúc Microservices (5 phút)

### Slide 4: System Architecture Diagram
- **Nói:** "Kiến trúc của eShelf được thiết kế theo mô hình microservices. Frontend React giao tiếp với các services thông qua API Gateway. API Gateway đóng vai trò entry point, xử lý routing, rate limiting, và authentication."

### Demo: Service Communication
- **Mở terminal:** `kubectl get services -A`
- **Nói:** "Chúng ta có 4 microservices chính: Auth Service xử lý authentication, Book Service quản lý sách, User Service quản lý profile và favorites, và ML Service cung cấp recommendations."

### Slide 5: Service Details
- **Nói:** "Mỗi service có trách nhiệm riêng biệt. Auth Service xử lý JWT tokens, Book Service cung cấp CRUD operations và search, User Service quản lý user data, và ML Service chạy recommendation algorithms."

### Demo: Service Logs
- **Mở terminal:** `kubectl logs -n eshelf-dev deployment/dev-api-gateway --tail=20`
- **Nói:** "Các services giao tiếp với nhau qua HTTP/REST. API Gateway validate JWT token trước khi forward requests đến các services."

### Slide 6: Database Architecture
- **Nói:** "Hiện tại các services dùng chung một PostgreSQL database, nhưng schema được tách biệt theo service. Trong tương lai có thể tách thành database per service để đạt được độc lập hoàn toàn."

---

## Phần 3: Infrastructure as Code (3 phút)

### Slide 7: Terraform Infrastructure
- **Nói:** "Infrastructure được quản lý bằng Terraform. Chúng ta có VPC với public và private subnets, security groups, và EC2 instances cho K3s cluster."

### Demo: Terraform State
- **Mở terminal:** `cd infrastructure/terraform/environments/dev && terraform show`
- **Nói:** "Terraform quản lý 3-node K3s cluster: 1 master node và 2 worker nodes. Bastion host được đặt trong public subnet để truy cập cluster."

### Slide 8: Ansible Configuration
- **Nói:** "K3s cluster được setup bằng Ansible playbooks. Ansible tự động install K3s trên master node, join worker nodes, và configure kubeconfig."

---

## Phần 4: Kubernetes Deployment (4 phút)

### Slide 9: K3s Cluster
- **Nói:** "Chúng ta sử dụng K3s - một lightweight Kubernetes distribution phù hợp cho edge computing và development environments."

### Demo: Cluster Status
- **Mở terminal:** `kubectl get nodes`
- **Nói:** "Cluster có 3 nodes đều ở trạng thái Ready. Master node chạy control plane components, worker nodes chạy application pods."

### Demo: Namespaces
- **Mở terminal:** `kubectl get namespaces`
- **Nói:** "Chúng ta có các namespaces riêng biệt: eshelf-dev cho applications, monitoring cho monitoring stack, argocd cho GitOps, và harbor cho container registry."

### Slide 10: Kustomize Overlays
- **Nói:** "Kubernetes manifests được quản lý bằng Kustomize. Base configurations chứa common settings, overlays cho từng environment (dev, staging, prod) override các giá trị cụ thể."

### Demo: Kustomize Structure
- **Mở file explorer:** `infrastructure/kubernetes/overlays/dev/kustomization.yaml`
- **Nói:** "Dev overlay override image tags, replica counts, và resource limits phù hợp với development environment."

---

## Phần 5: GitOps với ArgoCD (3 phút)

### Slide 11: ArgoCD Architecture
- **Nói:** "ArgoCD implement GitOps pattern - Git repository là source of truth cho tất cả Kubernetes resources."

### Demo: ArgoCD UI
- **Mở browser:** Port-forward ArgoCD và truy cập UI
- **Nói:** "ArgoCD monitor Git repository và tự động sync khi có changes. Applications được định nghĩa trong Git, ArgoCD apply chúng vào cluster."

### Demo: Application Sync
- **Click vào một application trong ArgoCD UI**
- **Nói:** "Khi có code changes, GitHub Actions build và push images lên Harbor. ArgoCD Image Updater detect images mới và update manifests. ArgoCD sync changes vào cluster."

---

## Phần 6: CI/CD Pipeline (4 phút)

### Slide 12: GitHub Actions Workflow
- **Nói:** "CI/CD pipeline được implement bằng GitHub Actions. Chúng ta có 2 pipelines riêng biệt: PR pipeline chỉ test và scan, Push pipeline build và deploy."

### Demo: GitHub Actions
- **Mở browser:** GitHub repository > Actions tab
- **Nói:** "PR pipeline chạy lint, test, security scan, và code quality checks. Push pipeline thêm Docker build, push images, và trigger ArgoCD sync."

### Slide 13: Smart Build System
- **Nói:** "Smart Build System chỉ build services có code changes thực sự. Path-based filtering identify changed services, code analysis loại bỏ comment-only changes."

### Demo: Smart Build Logs
- **Mở một workflow run trong GitHub Actions**
- **Nói:** "Workflow detect chỉ api-gateway và book-service có changes, nên chỉ build 2 services này thay vì tất cả 5 services."

### Slide 14: Harbor Registry
- **Nói:** "Container images được lưu trong Harbor registry thay vì DockerHub. Harbor cung cấp image scanning, access control, và replication."

### Demo: Harbor UI
- **Mở browser:** Port-forward Harbor và truy cập UI
- **Nói:** "Harbor UI cho phép quản lý projects, repositories, và xem scan results. Images được tag với commit SHA và environment."

---

## Phần 7: Monitoring và Observability (3 phút)

### Slide 15: Monitoring Stack
- **Nói:** "Monitoring stack bao gồm Prometheus cho metrics, Grafana cho visualization, Loki cho logs, và Alertmanager cho alerting."

### Demo: Grafana Dashboard
- **Mở browser:** Port-forward Grafana và truy cập dashboard
- **Nói:** "Grafana dashboards hiển thị metrics từ Prometheus: CPU usage, memory usage, request rates, và error rates của các services."

### Demo: Prometheus
- **Mở browser:** Port-forward Prometheus và query metrics
- **Nói:** "Prometheus collect metrics từ services qua HTTP endpoints. Metrics được query bằng PromQL."

### Slide 16: Log Aggregation
- **Nói:** "Promtail collect logs từ pods và send đến Loki. Logs được query qua LogQL trong Grafana."

---

## Phần 8: Security và Best Practices (2 phút)

### Slide 17: Security Layers
- **Nói:** "Security được implement ở nhiều layers: network security với VPC và security groups, container security với scanning, và application security với JWT authentication."

### Demo: Security Scanning
- **Mở GitHub Actions:** Show Trivy scan results
- **Nói:** "Trivy scan Docker images để detect vulnerabilities. Checkov scan Terraform code để detect misconfigurations."

### Slide 18: Secrets Management
- **Nói:** "Sensitive data được quản lý bằng Kubernetes Secrets. Harbor credentials được store trong secrets và mount vào pods."

---

## Phần 9: MLOps (2 phút)

### Slide 19: ML Service
- **Nói:** "ML Service sử dụng FastAPI và scikit-learn để cung cấp book recommendations và similarity search."

### Demo: ML API
- **Mở browser:** `http://localhost:8000/docs`
- **Nói:** "ML Service expose REST API với endpoints cho recommendations và similarity. Model được train offline và load vào service khi start."

### Slide 20: Model Deployment
- **Nói:** "Model deployment được quản lý qua Kubernetes. ML Service pod load model từ persistent volume. Future improvements có thể include MLflow cho model tracking."

---

## Phần 10: Demo Application (3 phút)

### Demo: Frontend
- **Mở browser:** `http://localhost:5173`
- **Nói:** "Frontend cho phép user đăng nhập, tìm kiếm sách, xem chi tiết, đọc PDF, và quản lý favorites."

### Demo: Admin Panel
- **Login với admin account**
- **Nói:** "Admin panel cho phép quản lý sách, users, và genres. CRUD operations được thực hiện qua API Gateway."

### Demo: Search và Recommendations
- **Search một cuốn sách**
- **Nói:** "Search được implement ở Book Service. Recommendations từ ML Service có thể được integrate vào search results."

---

## Phần 11: Q&A và Kết Luận (2 phút)

### Slide 21: Key Takeaways
- **Nói:** "Project eShelf demonstrate kiến trúc microservices với DevOps best practices: Infrastructure as Code, GitOps, CI/CD automation, và comprehensive monitoring."

### Slide 22: Future Improvements
- **Nói:** "Future improvements có thể include: service mesh cho advanced traffic management, event-driven architecture với message queues, và complete database per service pattern."

### Slide 23: Thank You
- **Nói:** "Cảm ơn các bạn đã lắng nghe. Tôi sẵn sàng trả lời câu hỏi."

---

## Checklist Trước Khi Quay

### Prerequisites
- [ ] Tất cả services đang chạy
- [ ] Kubernetes cluster accessible
- [ ] ArgoCD UI accessible
- [ ] Grafana dashboard có data
- [ ] Harbor UI accessible
- [ ] Frontend application chạy được

### Tools Cần Mở
- [ ] Terminal với kubectl
- [ ] Browser với các tabs: ArgoCD, Grafana, Harbor, GitHub Actions
- [ ] VS Code hoặc editor để show code
- [ ] Frontend application

### Scripts Cần Chuẩn Bị
- [ ] Commands để show cluster status
- [ ] Commands để show service logs
- [ ] URLs để truy cập các UIs
- [ ] Test accounts (admin, user)

---

## Lưu Ý Khi Quay

1. **Pace:** Nói chậm và rõ ràng, đặc biệt khi giải thích technical concepts
2. **Transitions:** Dùng transitions mượt mà giữa các phần
3. **Screen Recording:** Đảm bảo screen resolution đủ cao để đọc được text
4. **Audio:** Kiểm tra microphone và background noise
5. **Backup:** Có backup plan nếu demo bị lỗi (screenshots, pre-recorded clips)

---

## Thời Gian Chi Tiết

| Phần | Thời Gian | Nội Dung |
|------|-----------|----------|
| 1. Giới thiệu | 2 phút | Project overview |
| 2. Microservices | 5 phút | Architecture, services, communication |
| 3. Infrastructure | 3 phút | Terraform, Ansible |
| 4. Kubernetes | 4 phút | K3s, Kustomize, deployments |
| 5. GitOps | 3 phút | ArgoCD, GitOps flow |
| 6. CI/CD | 4 phút | GitHub Actions, Smart Build, Harbor |
| 7. Monitoring | 3 phút | Prometheus, Grafana, Loki |
| 8. Security | 2 phút | Security layers, scanning |
| 9. MLOps | 2 phút | ML Service, model deployment |
| 10. Demo App | 3 phút | Frontend, features |
| 11. Q&A | 2 phút | Summary, questions |
| **Tổng** | **33 phút** | (Có thể cắt xuống 20-25 phút) |

