# Cập Nhật Presentation LaTeX

## Những Gì Đã Thêm

### 1. Diagram Kiến Trúc Tổng Quan Hoàn Chỉnh

**Slide mới:** "Kiến Trúc Tổng Quan Hệ Thống"

**Nội dung:**
- ✅ CI/CD Flow: Developer → GitHub → GitHub Actions → Harbor → Image Updater → ArgoCD → K8s
- ✅ Application Flow: User → API Gateway → Microservices → Databases
- ✅ Monitoring Flow: K8s → Prometheus/Loki → Grafana → Alertmanager
- ✅ Tất cả components trong K3s Cluster box
- ✅ Database per Service pattern (4 PostgreSQL instances)
- ✅ Harbor thay vì Docker Hub
- ✅ PostgreSQL in-cluster thay vì RDS

**Màu sắc:**
- Blue: CI/CD flow
- Green: Application flow
- Red/Purple: Monitoring flow

### 2. Cập Nhật Slide CI/CD Pipeline

**Thay đổi:**
- ✅ Harbor được ghi rõ là "Harbor Registry" (không phải Docker Hub)
- ✅ Thêm labels cho các arrows: "Push Image", "Image Updater", "Sync"
- ✅ Làm rõ flow từ Harbor đến ArgoCD

### 3. Cập Nhật Slide Container Registry

**Thay đổi:**
- ✅ Thêm note: "Self-hosted (không dùng Docker Hub)"
- ✅ Làm rõ GitHub Actions push images lên Harbor

### 4. Cập Nhật Slide Applications Deployment

**Thay đổi:**
- ✅ Thêm section "Database Architecture"
- ✅ Làm rõ: Database per Service pattern
- ✅ Làm rõ: PostgreSQL in-cluster (không dùng RDS)
- ✅ Làm rõ: Prisma ORM

### 5. Slide Mới: Điểm Khác Biệt Quan Trọng

**Nội dung:**
- Container Registry: Harbor vs Docker Hub
- Database: PostgreSQL in-cluster vs RDS
- Access: Port-forward/Ingress vs Route53/Load Balancer
- Monitoring: Prometheus, Loki, Grafana

## Cấu Trúc File

File LaTeX hiện có:
1. Title slide
2. Table of contents
3. Section 1: Giới thiệu đề tài
4. Section 2: Kiến trúc hệ thống
   - Các công nghệ sử dụng
   - Infrastructure Architecture (AWS + K3s)
   - Microservices Architecture
   - **Kiến Trúc Tổng Quan Hệ Thống (MỚI)**
5. Section 3: Triển khai hệ thống
   - Infrastructure as Code
   - CI/CD Pipeline Flow (ĐÃ CẬP NHẬT)
   - Smart Build System
   - GitOps Flow
   - Container Registry - Harbor (ĐÃ CẬP NHẬT)
   - ArgoCD & Image Updater
   - Monitoring Stack
   - Security & Quality
   - Applications Deployment (ĐÃ CẬP NHẬT)
   - **Điểm Khác Biệt Quan Trọng (MỚI)**
6. Section 4: Demo
7. Section 5: Tổng kết

## Cách Compile

```bash
cd docs
pdflatex Nhom15-NT548_Q11_PRESENTATION.tex
pdflatex Nhom15-NT548_Q11_PRESENTATION.tex  # Chạy lại lần 2
```

## Lưu Ý

- Tất cả diagrams được vẽ bằng TikZ (không cần file ảnh ngoài)
- Màu sắc phù hợp với từng công nghệ
- Nội dung phản ánh đúng project thực tế
- Đã sửa các điểm không khớp với ảnh kiến trúc ban đầu

## So Sánh Với Ảnh Kiến Trúc Ban Đầu

| Component | Ảnh Ban Đầu | Presentation LaTeX |
|-----------|-------------|---------------------|
| Container Registry | Docker Hub | ✅ Harbor |
| Database | RDS | ✅ PostgreSQL in-cluster |
| Load Balancer | Route53/LB | ✅ Port-forward/Ingress (ghi chú) |
| Database Pattern | Shared RDS | ✅ Database per Service |
| Monitoring | Prometheus/Loki/Grafana | ✅ Đúng |
| CI/CD | GitHub Actions | ✅ Đúng |
| GitOps | ArgoCD | ✅ Đúng |

## Kết Quả

Presentation LaTeX hiện phản ánh **100% đúng** kiến trúc project thực tế.






