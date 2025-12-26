# Góp ý của giảng viên

## Tổng quan

Giảng viên yêu cầu các nhóm không chỉ "làm cho chạy" mà phải hướng tới sự chuyên nghiệp, bảo mật và tối ưu hóa (Smart Build, GitOps).

---

## 1. Kiến trúc Hạ tầng (Infrastructure & Cloud)

### Quy mô Cluster

- Tối thiểu 3 Node (1 Master, 2 Worker)

### Công cụ triển khai

**AWS:**
- Phải làm sớm để tận dụng credit/tài nguyên

**Terraform:**
- Dùng để dựng hạ tầng (IaC)
- Yêu cầu: Chia module rõ ràng (Network, Compute, Security...), không code "cứng" (hardcode), phải có bảo mật

**Ansible:**
- Dùng để cấu hình bên trong server sau khi Terraform dựng xong (Configuration Management)
- Yêu cầu: Deploy k3s hoặc các tool lên 3 môi trường (Dev, Staging, Prod)

### Lựa chọn nền tảng Kubernetes

- Có thể chọn EKS (Amazon Elastic Kubernetes Service) cho chuyên nghiệp
- Hoặc tự dựng cụm K8s trên EC2 bằng K3s (dùng Ansible script k3s-ansible) để hiểu sâu về setup

---

## 2. Quy trình CI/CD & Pipeline (Trọng tâm)

### Flow cơ bản

Code (GitHub) → CI (Build/Test/Scan) → Push Artifact → Update Manifest → CD (ArgoCD) → Deploy

### Yêu cầu nâng cao (Để đạt điểm tối đa)

#### Smart Build (Build thông minh)

**Vấn đề:**
- Trong cấu trúc Microservices (hoặc Monorepo), khi sửa code 1 service, không được build lại toàn bộ hệ thống

**Giải pháp:**
- Pipeline phải có bước path-filter
- Chỉ khi folder chứa code của Service A thay đổi → chỉ chạy Pipeline build Service A

#### Cơ chế GitOps & Image Tagging

**Vấn đề:**
- Khi có Image mới, làm sao Cluster biết để update?

**Giải pháp:**
- Không dùng lệnh kubectl apply thủ công
- Dùng GitHub Actions/Jenkins build Docker Image → Push lên Registry
- Dùng tool (như yq, kustomize hoặc ArgoCD Image Updater) để tự động sửa file YAML (Deployment manifest) trong Git repo chứa config (ví dụ: sửa tag từ v1.0 thành v1.1 hoặc commit hash)
- ArgoCD sẽ phát hiện sự thay đổi trên Git repo config và đồng bộ (sync) về cụm Kubernetes

#### Artifact Management (Quản lý kho chứa)

- Thay vì dùng DockerHub public, nên dựng Harbor, JFrog Artifactory hoặc Sonatype Nexus (tự host) để quản lý Docker Images chuyên nghiệp hơn

#### Phân loại môi trường (Environments)

- Cần ít nhất 2 môi trường (Dev, Prod), tốt nhất là 3 (thêm Staging)

#### Cơ chế Pull Request (PR) vs. Push

- Khi tạo PR: Chỉ chạy test, scan code, lint (kiểm tra lỗi), build thử (chưa deploy)
- Khi Merge vào Main: Mới thực sự build image, push artifact và deploy lên Production

---

## 3. Giải thích các Tools & Links

### Deploy Kubernetes

- **k3s-ansible:** Script mẫu để cài K3s bằng Ansible (dành cho ai muốn tự dựng cluster trên EC2 thay vì mua EKS)
- **eks:** Tài liệu AWS EKS (dành cho nhóm giàu tài nguyên/muốn chuẩn Cloud native)

### Cập nhật Image tự động

- **fluxcd image-update / argocd-image-updater:** Các tool tự động theo dõi Image Registry, nếu có tag mới nó sẽ tự update vào Cluster
- **yq:** Tool dòng lệnh xử lý file YAML. Dùng trong bước CI để sửa file manifest
- **kustomize:** Một cách khác để quản lý cấu hình đè (overlay) cho các môi trường khác nhau (Dev/Prod) và update image tag sạch sẽ hơn

### CI/CD Tools

- **Jenkins on Kubernetes:** Cách cài Jenkins chạy như một Pod trong K8s (scalable hơn)

### Artifact Repo

- **Harbor, JFrog, Nexus:** Các lựa chọn để thay thế DockerHub. Harbor là lựa chọn mã nguồn mở rất tốt và phổ biến hiện nay

---

## 4. Yêu cầu về Báo cáo & Demo

### Kiến trúc hệ thống (Architecture Diagram)

- Phải vẽ rất rõ ràng, chi tiết luồng đi của dữ liệu và luồng CI/CD
- Đây là phần giảng viên sẽ soi kỹ nhất để hỏi thi

### Nội dung Slide

- Cần có phần kết luận, hướng phát triển tương lai
- Giải thích rõ cơ chế hoạt động (Tại sao chọn tool này? ArgoCD sync thế nào?)
- Kịch bản Rollback (Khi deploy lỗi, hệ thống quay lại bản cũ thế nào?)

### Demo

- Quay video demo gửi giảng viên (đề phòng lúc demo trực tiếp bị lỗi)
- Show code trực tiếp, show log chạy pipeline
- Chứng minh được tính năng "chỉ build service thay đổi" và "tự động update tag"

---

## 5. Tóm tắt "To-Do List"

### Hạ tầng

- Viết Terraform dựng 3 EC2 trên AWS
- Viết Ansible cài K3s lên đó

### Tools

- Cài Jenkins (hoặc setup GitHub Actions runner)
- Cài ArgoCD
- Cài Harbor

### Code

- Viết Dockerfile cho các service (Backend/Frontend)

### Pipeline (Khó nhất)

- Viết script logic: "Nếu folder /backend đổi → Build Docker Backend → Push Harbor → Dùng yq update file backend-deploy.yaml trong Git → Commit code"
- Cấu hình ArgoCD trỏ vào repo chứa file yaml đó

### Monitoring/Log

- Setup đơn giản (như ELK stack hoặc Prometheus/Grafana) để show log
