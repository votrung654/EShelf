# NT548.Q11 - CÔNG NGHỆ DEVOPS VÀ ỨNG DỤNG

*[Mô tả hình ảnh: Hình nền trang bìa với họa tiết vòng cung màu xanh dương đậm ở phía trên]*

## DEPLOY AN EBOOK PLATFORM ON KUBERNETES USING GITHUB ACTIONS AND ARGOCD

**THỰC HIỆN BỞI NHÓM 15:**
* 22521571 - Võ Đình Trung
* 22521587 – Trương Phúc Trường
* 23521809 - Lê Văn Vũ

**GVHD:** ThS. Lê Anh Tuấn

---

# Overview

1.  **Giới thiệu đề tài**: 01
2.  **Kiến trúc hệ thống**: 02
3.  **Triển khai hệ thống**: 03
4.  **Tổng kết**: 04
5.  **Demo**: 05

---

# 1. Giới thiệu đề tài

**Giới thiệu**
* **EShelf** là nền tảng đọc sách điện tử được xây dựng theo kiến trúc microservices, áp dụng các mô hình DevOps hiện đại như container hóa, Kubernetes và CI/CD.
* Đề tài hướng tới việc mô phỏng quy trình triển khai và vận hành hệ thống phần mềm trên môi trường cloud.

**Mục tiêu**
* Hệ thống nhằm triển khai tự động các microservices trên Kubernetes bằng Infrastructure as Code và GitOps.

**Phạm vi**
* Phạm vi đồ án tập trung vào kiến trúc triển khai, CI/CD và bảo mật, được xây dựng ở mức phục vụ cho demo và đánh giá kỹ thuật.

---

# 1.1. Các công nghệ sử dụng (Trang 1)

*[Mô tả hình ảnh: Logo của Docker (hình cá voi xanh chở các container), Logo của Harbor (hình ngọn hải đăng xanh lá cây), Logo của Terraform (hình khối tím), Logo của AWS (mũi tên vàng), Logo K3s]*

**Infrastructure**
* HashiCorp Terraform
* AWS
* Registry

**Container management**
* Docker
* K3s

**CI/CD**
* Jenkins
* GitHub Actions
* CodePipeline
* Harbor

---

# 1.2. Các công nghệ sử dụng (Trang 2)

*[Mô tả hình ảnh: Logo của Prometheus (hình ngọn lửa cam), Logo của Grafana (hình bánh răng cam xoắn ốc), Logo của ArgoCD]*

**GitOps**
* ArgoCD

**Monitoring & Logging**
* Prometheus
* Grafana
* Grafana Loki

**Security**
* Checkov
* SonarQube
* Trivy

---

# 2. KIẾN TRÚC HỆ THỐNG

*[Mô tả hình ảnh: Hình nền trừu tượng trang chuyển tiếp với các họa tiết đồ họa]*

---

# 2. Kiến trúc hệ thống (Sơ đồ chi tiết)

*[Mô tả hình ảnh: Sơ đồ quy trình CI/CD hoàn chỉnh.
Phần bên trái (Continuous Integration): Developer push code/PR lên GitHub -> Trigger GitHub Actions -> Thực hiện Build Docker Image. Quá trình này tích hợp Webhook với Jenkins (biểu tượng quản gia), Scan code bằng SonarQube, Scan Image bằng Trivy -> Đẩy Image vào Harbor Registry. Checkov dùng để scan IaC Terraform.
Phần bên phải (Continuous Delivery): ArgoCD (biểu tượng con bạch tuộc) tự động đồng bộ (Pull) cấu hình từ Git về K3s Cluster.
Phần hạ tầng (Bottom): Terraform provisioning EC2 Nodes trên AWS, sử dụng Ansible để cấu hình.
Phần giám sát (Monitoring): Grafana và Prometheus kết nối với K3s Cluster.]*

---

# 3. TRIỂN KHAI HỆ THỐNG

*[Mô tả hình ảnh: Hình nền trừu tượng trang chuyển tiếp với các họa tiết đồ họa]*

---

# 3. Triển khai hệ thống: Hạ tầng triển khai

**Các thành phần:**
* **IaC:** Terraform (Module-based architecture)
* **Network:** AWS VPC riêng, Public / Private Subnets, NAT Gateway
* **Compute:** EC2 m7i-flex.large / t3.micro
* **Provisioning:** Ansible cài môi trường & K3s
* **Cluster:** 1 Master + 2 Worker Nodes + 1 Bastion

**Lợi ích:**
* Terraform đảm bảo Idempotency, quản lý trạng thái hạ tầng rõ ràng.
* Terraform tạo hạ tầng, Ansible cài phần mềm -> đúng chuẩn thực tế.

---

# 3. Triển khai hệ thống: Container hóa hệ thống

**Chi tiết:**
* **Công nghệ:** Docker
* **Tối ưu:** Multi-stage builds
* **Bảo mật:** Container chạy bằng Non-root user
* **Dev Env:** Docker Compose (tự khởi tạo DB, đồng bộ môi trường)

**Lợi ích:**
* Multi-stage giúp image nhẹ, an toàn hơn.
* Non-root giảm rủi ro chiếm quyền máy chủ.

---

# 3. Triển khai hệ thống: Điều phối Container (Kubernetes)

**Chi tiết:**
* **Orchestrator:** K3s (Lightweight Kubernetes)
* **Ưu điểm:** Nhẹ, tương thích 100% K8s API
* **Quản lý config:** Kustomize (Base + Overlays)
* **Tối ưu tài nguyên:** Swap Memory, Overcommit

**Lợi ích:**
* K3s phù hợp máy cấu hình thấp (AWS gói rẻ).
* Kustomize dễ quản lý nhiều môi trường hơn Helm.

---

# 3. Triển khai hệ thống: Quản lý Image & Registry

**Giải pháp:** Harbor (Private Registry)

**Tính năng:**
* Lưu trữ image nội bộ
* Quét lỗ hổng bằng Trivy
* Proxy Cache tăng tốc pull image
* Phân quyền & dọn image rác

**Lợi ích:**
* Chủ động bảo mật, không phụ thuộc Docker Hub.
* Chặn image lỗi trước khi deploy.

---

# 3. Triển khai hệ thống: Tự động hóa CI/CD

**Nền tảng:** GitHub Actions

**Pipeline:**
* **PR:** Test, Lint
* **Main:** Build & Deploy
* **Smart Build:** Chỉ build service có thay đổi

**Lợi ích:**
* Monorepo nhưng build thông minh -> tiết kiệm ~60% thời gian.
* Tách PR & Main để đảm bảo an toàn code.

---

# 3. Triển khai hệ thống: GitOps với ArgoCD

**Chi tiết:**
* **Mô hình:** GitOps (Git là nguồn chân lý)
* **Cơ chế:** Pull-based, Auto-sync, Self-healing
* **Rollback:** Revert Git -> hệ thống tự quay về

**Lợi ích:**
* Không cần đưa quyền server cho CI/CD.
* Rollback nhanh, an toàn.

---

# 3. Triển khai hệ thống: Giám sát hệ thống (Observability)

**Stack:** Prometheus – Loki – Grafana

**Chức năng:**
* **Metrics:** Prometheus
* **Logs:** Loki
* **Visualization:** Grafana
* **Cảnh báo:** Alertmanager (Slack / Email)

**Lợi ích:**
* Metrics = triệu chứng, Logs = nguyên nhân.
* Log tập trung cần thiết cho Microservices.

---

# 3. Triển khai hệ thống: Bảo mật (DevSecOps)

**Chiến lược:** Defense in Depth, Shift-Left

**Công cụ:**
* **IaC Scan:** Checkov
* **Code Scan:** SonarQube
* **Image Scan:** Trivy
* **Runtime Security:** Network Policies, Kubernetes Secrets

**Lợi ích:**
* Phát hiện lỗi bảo mật sớm -> nhanh chóng & hiệu quả.
* Áp dụng nguyên tắc Least Privilege triệt để.

---

# 4. Tổng kết: Kết quả đạt được

**Kết quả:**
* Xây dựng thành công hệ thống EShelf theo kiến trúc microservices, triển khai trên Kubernetes (K3s) bằng Infrastructure as Code (Terraform kết hợp Ansible).
* Quy trình CI/CD áp dụng GitOps với GitHub Actions và ArgoCD, hỗ trợ smart build, push image lên Dockerhub, monitoring và logging.

**Hạn chế & Hướng phát triển:**
* Một số thành phần như Jenkins, SonarQube và MLOps mới dừng ở mức nghiên cứu kiến trúc, ArgoCD và Harbor chưa triển khai hoàn toàn đầy đủ.
* Chỉ mới triển khai môi trường dev.
* Trong tương lai, nhóm sẽ hoàn thiện production, tăng cường bảo mật, tối ưu CI/CD và mở rộng hệ thống theo hướng doanh nghiệp.

---

# 5. DEMO

*[Mô tả hình ảnh: Hình nền trừu tượng trang chuyển tiếp với các họa tiết đồ họa]*

---

# THANK YOU!

**NT548.Q11 - CÔNG NGHỆ DEVOPS VÀ ỨNG DỤNG**

**NHÓM 15**