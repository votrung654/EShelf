# Kế hoạch do ChatGPT đề nghị
# 📚 eShelf – Ứng dụng đọc sách trực tuyến


---

## 🎯 Mục tiêu dự án

- Phát triển hệ thống web đọc sách trực tuyến (PDF, EPUB).
- Hỗ trợ người dùng tìm kiếm, đánh giá, lưu sách yêu thích, tương tác xã hội.
- Ứng dụng quy trình DevOps/MLOps chuyên nghiệp (CI/CD, giám sát, triển khai mô hình AI).

---

## ✅ Chức năng hiện có

- **Trang chủ:** Hiển thị sách nổi bật, mới cập nhật, tìm kiếm nhanh.
- **Tìm kiếm:** Theo tên sách, tác giả, thể loại.
- **Chi tiết sách:** Thông tin, đánh giá, tải/xem sách.
- **Đăng nhập/Đăng ký:** Xác thực người dùng.
- **Thể loại (Genres):** Lọc sách theo thể loại.
- **Ủng hộ:** Trang đóng góp phát triển dự án.
- **Phản hồi:** Gửi ý kiến hoặc báo lỗi.

---

## 🚧 Tính năng sẽ phát triển

### 👤 Người dùng
- Hồ sơ cá nhân, đổi mật khẩu, xác thực 2FA.
- Kệ sách cá nhân, yêu thích, đánh dấu trang.

### 📖 Đọc sách nâng cao
- Viewer EPUB, Text-to-speech, dark mode, đồng bộ đa thiết bị.

### 🔍 Tìm kiếm & gợi ý
- Tìm kiếm nâng cao (ngôn ngữ, năm), gợi ý dựa theo hành vi đọc.

### 💬 Tương tác xã hội
- Book clubs, theo dõi người dùng, diễn đàn thảo luận, thử thách đọc.

### ⚙️ Admin panel
- Dashboard thống kê, quản lý sách, thể loại, người dùng, báo cáo.

---

## 🧱 Kiến trúc & Công nghệ

### Frontend
- ReactJS + Vite + TailwindCSS
- Zustand/Redux Toolkit, React Query, Axios, Formik/Yup

### Backend (dự kiến)
- Node.js + Express (hoặc NestJS)
- RESTful API, JWT, OAuth2, phân quyền
- Redis cache, Elasticsearch, Multer, Socket.io

### Cơ sở dữ liệu
- MySQL/PostgreSQL (có thể kết hợp MongoDB)
- Thiết kế schema chuẩn hóa (Users, Books, Genres, Reviews,...)

---

## 🛠️ DevOps & Hạ tầng

### Lab 1 – IaC với Terraform & CloudFormation
- Tạo module triển khai VPC, Subnet, NAT Gateway, EC2, RDS, Security Groups.
- Thiết lập mạng private/public subnet và bảo mật EC2.

### Lab 2 – Tự động hóa hạ tầng & CI/CD
- Terraform + GitHub Actions → plan/apply hạ tầng.
- CloudFormation + CodePipeline + CodeBuild + CodeCommit
- Tích hợp Checkov, cfn-lint, Taskcat kiểm tra bảo mật và tính đúng đắn.

### CI/CD Pipeline
- CI: Lint, unit test, build Docker, scan image (Trivy).
- CD: Push Docker image → Deploy staging → e2e test → Manual approve → Prod deploy (Blue/Green/Canary).
- Rollback nếu thất bại + lưu trữ log.

### Giám sát hệ thống
- Prometheus + Grafana + Loki + Alertmanager.
- Giám sát CI/CD, ứng dụng, container, tài nguyên hệ thống.

### GitOps
- ArgoCD tự động sync YAML từ Git vào Kubernetes cluster.

---

## 🤖 MLOps Pipeline (nếu có ML/AI)

- Huấn luyện mô hình đề xuất sách (Collaborative Filtering, Content-Based).
- Theo dõi & lưu ML experiment (MLflow).
- Đăng ký mô hình trong MLflow Registry.
- Đóng gói mô hình thành Docker image.
- Canary deploy mô hình mới → theo dõi hiệu suất.
- Giám sát drift dữ liệu, accuracy, recall... → rollback nếu suy giảm.

---

Roadmap phát triển theo giai đoạn
Giai đoạn (Phase)	Mục tiêu & Công việc chính
Phase 1 – MVP (Hiện tại)	Hoàn thiện giao diện Frontend và các chức năng cơ bản đã mô tả ở trên (Trang chủ, Tìm kiếm, Chi tiết sách, Đăng ký/Đăng nhập, Donate, Feedback). Công nghệ: React, TailwindCSS.
Phase 2 – Backend/API & Hạ tầng	Xây dựng API Backend (Node.js/Express), thiết kế Database (MySQL/PostgreSQL) với schema phù hợp. Thiết lập hạ tầng AWS: tạo VPC, EC2, NAT Gateway, RDS, S3, IAM thông qua Terraform/CloudFormation modules để đảm bảo quản lý nguồn lực có thể tái sử dụng và mở rộng
medium.com
developer.hashicorp.com
.
Phase 3 – DevOps & CI/CD	Thiết lập CI/CD đầy đủ: sử dụng GitHub Actions cho CI (lint, test, build Docker, scan container Trivy
medium.com
) và CodePipeline/CodeBuild cho CD (deploy bằng CloudFormation). Cấu hình test tự động, kiểm tra bảo mật mã và container. Tích hợp GitOps với ArgoCD để triển khai ứng dụng vào Kubernetes (hoặc ECS/EKS), có rollback khi gặp lỗi. Thêm hệ thống giám sát (Prometheus + Grafana + Alertmanager) cho phép theo dõi hiệu suất hệ thống và pipeline
medium.com
medium.com
.
Phase 4 – MLOps & Quan sát	Xây dựng pipeline MLOps: thu thập data, training model, dùng MLflow tracking và Model Registry để quản lý vòng đời mô hình
mlflow.org
peeushagarwal.medium.com
. Tự động hóa đóng gói và triển khai mô hình (container hóa, triaging deployment). Áp dụng Canary Deployment cho mô hình mới để thử nghiệm trên một phần nhỏ người dùng trước khi rollout rộng
wallarooai.medium.com
. Giám sát mô hình: theo dõi drift dữ liệu và hiệu suất mô hình (accuracy, loss, v.v.), cảnh báo khi model bị suy giảm.
Phase 5 – Mở rộng & Tối ưu	Tích hợp thêm tính năng nâng cao (Recommendation engine, social features, mobile app, PWA, quản lý cache nâng cao). Tối ưu hiệu năng hệ thống, bảo mật, mở rộng quy mô (Autoscaling, K8s cluster).
