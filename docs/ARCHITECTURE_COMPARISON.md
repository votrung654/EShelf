# So Sánh Kiến Trúc - Ảnh vs Project Thực Tế

## Tổng Quan

Ảnh kiến trúc có **một số điểm không khớp** với project thực tế. Dưới đây là phân tích chi tiết:

---

## ✅ ĐÚNG - Những điểm khớp

### 1. CI/CD Pipeline
- ✅ **GitHub Actions** - Đúng, project sử dụng GitHub Actions
- ✅ **Build/Push Image** - Đúng, có workflow build và push images
- ✅ **ArgoCD Image Updater** - Đúng, có ArgoCD Image Updater configured

### 2. K3s Cluster trên AWS EC2
- ✅ **K3s Cluster (AWS EC2)** - Đúng, cluster được deploy trên AWS EC2
- ✅ **3 nodes** - Đúng (1 master + 2 workers)

### 3. Microservices
- ✅ **API Gateway** - Đúng, có api-gateway service
- ✅ **Auth Service** - Đúng, có auth-service
- ✅ **Book Service** - Đúng, có book-service
- ✅ **User Service** - Đúng, có user-service
- ✅ **ML Service** - Đúng, có ml-service

### 4. GitOps
- ✅ **ArgoCD Controller** - Đúng, ArgoCD đã được deploy
- ✅ **Detect Digest** - Đúng, ArgoCD Image Updater detect image changes

### 5. Monitoring Stack
- ✅ **Prometheus** - Đúng, Prometheus đã được deploy
- ✅ **Loki** - Đúng, Loki đã được deploy
- ✅ **Grafana** - Đúng, Grafana đã được deploy
- ✅ **Alertmanager** - Đúng, Alertmanager đã được deploy

---

## ❌ SAI - Những điểm không khớp

### 1. Container Registry

**Ảnh hiển thị:** Docker Hub Registry

**Project thực tế:** **Harbor** (self-hosted container registry)

**Chi tiết:**
- Project sử dụng Harbor được deploy trên Kubernetes
- Workflows sử dụng `HARBOR_REGISTRY`, `HARBOR_USERNAME`, `HARBOR_PASSWORD`
- Harbor project: `eshelf`
- Internal service: `harbor-core.harbor.svc.cluster.local`
- File cấu hình: `infrastructure/kubernetes/harbor/`

**Cần sửa trong ảnh:** Docker Hub → **Harbor**

---

### 2. Database

**Ảnh hiển thị:** RDS Database (AWS RDS)

**Project thực tế:** **PostgreSQL trong cluster** (không phải RDS)

**Chi tiết:**
- Project sử dụng PostgreSQL container trong docker-compose
- Mỗi service có database riêng (database per service pattern)
- Prisma ORM với PostgreSQL
- Không có RDS được triển khai (chỉ có security group config cho RDS trong Terraform nhưng chưa dùng)

**Cần sửa trong ảnh:** RDS Database → **PostgreSQL (in-cluster)** hoặc **Database per Service**

---

### 3. Load Balancer & Route53

**Ảnh hiển thị:** Route53/DNS → Load Balancer → API Gateway

**Project thực tế:** **Chưa có** (hoặc chưa triển khai)

**Chi tiết:**
- Có security group config cho ALB trong Terraform nhưng chưa deploy
- Có Ingress resource trong Kubernetes nhưng chưa có Load Balancer thực tế
- Không có Route53 configuration
- Hiện tại access qua port-forward hoặc Ingress (nếu có)

**Cần sửa trong ảnh:** Có thể bỏ hoặc đánh dấu là "Planned" / "Future"

---

### 4. Service Interactions

**Ảnh hiển thị:** 
- API Gateway → Auth Service, Book Service
- Book Service → User Service
- User Service → ML Service

**Project thực tế:** Cần kiểm tra lại, nhưng có thể đúng

**Chi tiết:**
- API Gateway là entry point cho tất cả services
- Các services có thể giao tiếp với nhau
- Cần verify routing logic trong code

---

### 5. Database Sync

**Ảnh hiển thị:** "Sync" arrows từ Auth Service và User Service → RDS Database

**Project thực tế:** **Database per Service** (mỗi service có database riêng)

**Chi tiết:**
- Auth Service có database riêng
- User Service có database riêng
- Book Service có database riêng
- ML Service có database riêng
- Không có shared RDS database

**Cần sửa trong ảnh:** RDS Database → **Multiple PostgreSQL databases (one per service)**

---

## ⚠️ CHƯA RÕ - Cần xác nhận

### 1. Prometheus Write-back
**Ảnh hiển thị:** ArgoCD Controller → "Write-back" → Prometheus

**Project thực tế:** Cần kiểm tra xem ArgoCD có write metrics về Prometheus không

**Chi tiết:**
- ArgoCD thường scrape metrics từ Prometheus, không phải write-back
- Có thể là ArgoCD metrics được Prometheus scrape

---

### 2. Prometheus Hierarchy
**Ảnh hiển thị:** Prometheus → Prometheus (2 instances)

**Project thực tế:** Cần kiểm tra xem có 2 Prometheus instances không

**Chi tiết:**
- Thường chỉ có 1 Prometheus instance
- Có thể là federation hoặc high availability setup

---

## 📋 Tóm Tắt Sửa Đổi Cần Thiết

### Cần sửa ngay:

1. **Docker Hub** → **Harbor** (self-hosted registry)
2. **RDS Database** → **PostgreSQL (in-cluster)** hoặc **Database per Service**
3. **Route53/Load Balancer** → Bỏ hoặc đánh dấu "Planned"
4. **Database Sync** → Sửa thành multiple databases (one per service)

### Cần xác nhận:

1. Service interaction flow
2. Prometheus write-back mechanism
3. Prometheus instances count

---

## 🎯 Kiến Trúc Đúng Cho Project

### Container Registry Flow:
```
GitHub Actions → Build Image → Push to Harbor → ArgoCD Image Updater → ArgoCD Sync → K8s Cluster
```

### Database Architecture:
```
Auth Service → PostgreSQL (Auth DB)
User Service → PostgreSQL (User DB)
Book Service → PostgreSQL (Book DB)
ML Service → PostgreSQL (ML DB)
```

### Access Flow (Hiện tại):
```
User → Port-forward/Ingress → API Gateway → Microservices
```

### Access Flow (Tương lai - nếu có):
```
User → Route53 → Load Balancer → Ingress → API Gateway → Microservices
```

---

## 💡 Khuyến Nghị

1. **Cập nhật ảnh kiến trúc** để phản ánh đúng:
   - Harbor thay vì Docker Hub
   - PostgreSQL in-cluster thay vì RDS
   - Database per service pattern

2. **Thêm ghi chú** cho các components chưa triển khai:
   - Route53/Load Balancer: "Planned"
   - RDS: "Not used (using in-cluster PostgreSQL)"

3. **Làm rõ** service interactions và data flow

4. **Cập nhật** monitoring flow nếu cần






