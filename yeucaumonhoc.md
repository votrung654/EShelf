# Yêu cầu môn học IE104 - DevOps & MLOps

## Lab 1: Infrastructure as Code

### Yêu cầu thực hành

Dùng Terraform và CloudFormation để quản lý và triển khai tự động hạ tầng AWS.

#### 1. Các dịch vụ cần triển khai

**VPC (3 điểm):**
- Subnets: Bao gồm cả Public Subnet (kết nối với Internet Gateway) và Private Subnet (sử dụng NAT Gateway để kết nối ra ngoài)
- Internet Gateway: Kết nối với Public Subnet để cho phép các tài nguyên bên trong có thể truy cập Internet
- Default Security Group: Tạo Security Group mặc định cho VPC

**Route Tables (2 điểm):**
- Public Route Table: Định tuyến lưu lượng Internet thông qua Internet Gateway
- Private Route Table: Định tuyến lưu lượng Internet thông qua NAT Gateway

**NAT Gateway (1 điểm):**
- Cho phép các tài nguyên trong Private Subnet có thể kết nối Internet mà vẫn bảo đảm tính bảo mật

**EC2 (2 điểm):**
- Tạo các instance trong Public và Private Subnet
- Đảm bảo Public instance có thể truy cập từ Internet
- Private instance chỉ có thể truy cập từ Public instance thông qua SSH hoặc các phương thức bảo mật khác

**Security Groups (2 điểm):**
- Public EC2 Security Group: Chỉ cho phép kết nối SSH (port 22) từ một IP cụ thể (hoặc IP của người dùng)
- Private EC2 Security Group: Cho phép kết nối từ Public EC2 instance thông qua port cần thiết (SSH hoặc các port khác nếu có nhu cầu)

#### 2. Yêu cầu

- Các dịch vụ phải được viết dưới dạng module
- Phải đảm bảo an toàn bảo mật cho EC2 (thiết lập Security Groups)

#### 3. Kết quả

- Báo cáo Word (theo mẫu đi kèm)
- Link GitHub (source code và file README hướng dẫn cách chạy mã nguồn)

#### 4. Lưu ý

- Sinh viên cần thường xuyên cập nhật mã nguồn lên GitHub
- Phải có các test cases để kiểm tra từng dịch vụ được triển khai thành công

---

## Lab 2: CI/CD Automation

### Yêu cầu thực hành

Quản lý và triển khai hạ tầng AWS và ứng dụng microservices với Terraform, CloudFormation, GitHub Actions, AWS CodePipeline và Jenkins.

#### 1. Triển khai hạ tầng AWS sử dụng Terraform và tự động hóa quy trình với GitHub Actions (3 điểm)

- Dùng Terraform để triển khai các dịch vụ AWS bao gồm: VPC, Route Tables, NAT Gateway, EC2, Security Groups (đã thực hiện ở bài tập 1)
- Tự động hóa quá trình triển khai với GitHub Actions
- Tích hợp Checkov để kiểm tra tính tuân thủ và bảo mật của mã nguồn Terraform

#### 2. Triển khai hạ tầng AWS với CloudFormation và tự động hóa quy trình build và deploy với AWS CodePipeline (3 điểm)

- Dùng CloudFormation để triển khai các dịch vụ AWS bao gồm: VPC, Route Tables, NAT Gateway, EC2, Security Groups (đã thực hiện trong bài tập 1)
- Sử dụng AWS CodeBuild, tích hợp cfn-lint và Taskcat để kiểm tra tính đúng đắn của mã CloudFormation
- Sử dụng AWS CodePipeline để tự động hóa quy trình build và deploy từ mã nguồn trên CodeCommit

#### 3. Sử dụng Jenkins để quản lý quy trình CI/CD cho ứng dụng microservices (4 điểm)

- Sử dụng Jenkins để tự động hóa quá trình build, test và deploy ứng dụng microservices lên Docker, Kubernetes (hoặc một dịch vụ tương ứng)
- Tích hợp SonarQube để kiểm tra chất lượng mã nguồn
- Có thể tích hợp thêm các công cụ kiểm tra bảo mật như Snyk hoặc Trivy để tăng cường tính an toàn của mã nguồn (tùy chọn)

#### Yêu cầu nộp bài

- Sinh viên cập nhật mã nguồn lên GitHub
- Kết quả nộp bao gồm:
  - Báo cáo Word (theo mẫu đi kèm)
  - Link GitHub chứa mã nguồn, file README.md hướng dẫn chi tiết cách cài đặt môi trường, cách chạy mã nguồn, và cách kiểm tra kết quả triển khai

---

## Đồ án

Ngoài những gì đã làm ở thực hành, đồ án cần thêm các yêu cầu sau:

### CI/CD Pipeline

**Source → Pull Request**

**CI (PR checks):**
- lint → unit test → typecheck → static analysis → build artefact

**Image Build & Scan:**
- multi-stage Docker build → container scan (Trivy/Clair) → push to registry

**Infrastructure as Code:**
- terraform plan/apply (staging) + cloud resources (RDS, ECR, EKS/EC2, S3, IAM)

**Config Management:**
- Ansible (server provisioning) hoặc Helm charts / kustomize để package k8s manifests

**Deploy Staging:**
- deploy image to staging (K8s/ECS/Swarm) → run integration / e2e tests

**Promote to Prod:**
- manual approval → deploy to prod (blue/green or canary) → smoke tests

**Observability & Alerts:**
- Prometheus + Grafana + Loki + Alertmanager

**GitOps (optional / preferred):**
- push deployment manifests to infra repo → ArgoCD/Flux sync to cluster

**Rollback / Post-deploy:**
- automatic rollback on failing healthchecks + retention & audit logs

**MLOps (if any ML service):**
- model training CI → model registry (MLflow) → CI for model packaging → Canary deploy model service → monitoring model metrics & data drift

### Yêu cầu chức năng

- Frontend, Backend phong phú, sáng tạo và đầy đủ như project chuyên nghiệp của các tập đoàn, công ty lớn
- Database cũng không thể thiếu
