# Hướng Dẫn Deploy eShelf - 3 Môi Trường

## Mục Lục

1. [Tổng Quan](#1-tổng-quan)
2. [Deploy Local Environment](#2-deploy-local-environment)
3. [Deploy Staging Environment](#3-deploy-staging-environment)
4. [Deploy Production Environment](#4-deploy-production-environment)
5. [Kiểm Tra Deployment](#5-kiểm-tra-deployment)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Tổng Quan

Hệ thống eShelf hỗ trợ 3 môi trường deployment:

| Môi Trường | Phương Thức | Registry | Namespace |
|------------|-------------|----------|-----------|
| **Local** | Docker Compose / Native | Local | N/A |
| **Staging** | Kubernetes + ArgoCD | Docker Hub | `eshelf-staging` |
| **Production** | Kubernetes + ArgoCD | Docker Hub | `eshelf-prod` |

### Branch Strategy

- `develop` → Build images với tag `dev` → Deploy lên Dev
- `staging` → Build images với tag `staging` → Deploy lên Staging
- `main` → Build images với tag `prod` → Deploy lên Production

---

## 2. Deploy Local Environment

### Cách 1: Docker Compose (Khuyến nghị)

**Yêu cầu:**
- Docker và Docker Compose đã cài đặt
- Ports: 3000, 3001, 3002, 3003, 5432, 6379, 8000, 5173 (frontend)

**Bước 1: Di chuyển vào thư mục backend**
```powershell
cd backend
```

**Bước 2: Tạo file `.env` (nếu chưa có)**
```powershell
# Copy từ example nếu có
# Hoặc tạo file .env với nội dung:
POSTGRES_USER=eshelf
POSTGRES_PASSWORD=eshelf123
POSTGRES_DB=eshelf
DATABASE_URL=postgresql://eshelf:eshelf123@postgres:5432/eshelf?schema=public
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret
NODE_ENV=development
```

**Bước 3: Build và chạy services**
```powershell
docker-compose up --build
```

**Hoặc chạy ở background:**
```powershell
docker-compose up -d --build
```

**Bước 4: Kiểm tra services**
```powershell
# Xem logs
docker-compose logs -f

# Kiểm tra containers đang chạy
docker-compose ps

# Kiểm tra health
curl http://localhost:3000/health
```

**Bước 5: Truy cập services**
- Frontend: http://localhost:5173 (cần chạy riêng, xem bên dưới)
- API Gateway: http://localhost:3000
- Auth Service: http://localhost:3001
- Book Service: http://localhost:3002
- User Service: http://localhost:3003
- ML Service: http://localhost:8000
- PostgreSQL: localhost:5432
- Redis: localhost:6379

**Bước 6: Chạy Frontend (riêng)**
```powershell
# Từ thư mục root
npm install
npm run dev
```

**Dừng services:**
```powershell
cd backend
docker-compose down

# Xóa volumes (xóa dữ liệu database)
docker-compose down -v
```

### Cách 2: Chạy Native (Không dùng Docker)

**Yêu cầu:**
- Node.js 18+
- Python 3.9+
- PostgreSQL 16+
- Redis 7+

**Bước 1: Setup Database**
```powershell
# Chạy PostgreSQL và Redis (qua Docker hoặc cài đặt local)
docker run -d --name postgres -p 5432:5432 -e POSTGRES_USER=eshelf -e POSTGRES_PASSWORD=eshelf123 -e POSTGRES_DB=eshelf postgres:16-alpine
docker run -d --name redis -p 6379:6379 redis:7-alpine
```

**Bước 2: Setup Environment Variables**
```powershell
# Tạo file .env trong backend/
$env:DATABASE_URL="postgresql://eshelf:eshelf123@localhost:5432/eshelf?schema=public"
$env:JWT_SECRET="your-secret-key"
$env:NODE_ENV="development"
```

**Bước 3: Chạy Database Migrations**
```powershell
cd backend/database
npm install
npm run migrate
npm run seed
```

**Bước 4: Chạy Services**

**Option A: Dùng script (Linux/Mac)**
```bash
./scripts/start-dev.sh
```

**Option B: Chạy thủ công từng service**

Terminal 1 - API Gateway:
```powershell
cd backend/services/api-gateway
npm install
npm run dev
```

Terminal 2 - Auth Service:
```powershell
cd backend/services/auth-service
npm install
npm run dev
```

Terminal 3 - Book Service:
```powershell
cd backend/services/book-service
npm install
npm run dev
```

Terminal 4 - User Service:
```powershell
cd backend/services/user-service
npm install
npm run dev
```

Terminal 5 - ML Service:
```powershell
cd backend/services/ml-service
pip install -r requirements.txt
uvicorn src.main:app --host 0.0.0.0 --port 8000
```

Terminal 6 - Frontend:
```powershell
npm install
npm run dev
```

---

## 3. Deploy Staging Environment

### Yêu Cầu

- Kubernetes cluster đã setup (K3s)
- kubectl đã cấu hình và kết nối cluster
- ArgoCD đã được deploy
- GitHub Secrets đã setup:
  - `DOCKERHUB_USERNAME`
  - `DOCKERHUB_TOKEN`

### Bước 1: Setup GitHub Secrets

1. Vào GitHub repository
2. Settings > Secrets and variables > Actions
3. Thêm 2 secrets:
   - `DOCKERHUB_USERNAME`: Docker Hub username (ví dụ: `22521571`)
   - `DOCKERHUB_TOKEN`: Docker Hub access token

### Bước 2: Deploy ArgoCD Applications

**Cách 1: Dùng Script (Khuyến nghị)**
```powershell
.\scripts\deploy-3-environments.ps1
```

**Cách 2: Thủ Công**
```powershell
# Apply tất cả ArgoCD applications
kubectl apply -f infrastructure/kubernetes/argocd/applications/

# Kiểm tra status
kubectl get applications -n argocd
```

### Bước 3: Push Code Lên Branch Staging

```powershell
# Checkout branch staging
git checkout staging

# Merge từ develop hoặc tạo changes
git merge develop

# Push lên remote
git push origin staging
```

**GitHub Actions sẽ tự động:**
1. Detect changes
2. Build Docker images (chỉ services có thay đổi)
3. Push images lên Docker Hub với tag `staging`
4. ArgoCD Image Updater tự động update manifests
5. ArgoCD tự động sync và deploy

### Bước 4: Kiểm Tra Deployment

```powershell
# Check ArgoCD applications
kubectl get applications -n argocd | Select-String -Pattern "staging"

# Check pods trong staging
kubectl get pods -n eshelf-staging

# Check services
kubectl get services -n eshelf-staging

# Check logs
kubectl logs -n eshelf-staging -l app=api-gateway --tail=50
```

### Bước 5: Port Forward để Test

```powershell
# Frontend
kubectl port-forward svc/frontend -n eshelf-staging 3002:80

# API Gateway
kubectl port-forward svc/api-gateway -n eshelf-staging 3003:3000
```

**Truy cập:**
- Frontend: http://localhost:3002
- API Gateway: http://localhost:3003

### Bước 6: Manual Sync (Nếu Cần)

```powershell
# Sync tất cả staging applications
kubectl patch application frontend-staging -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
kubectl patch application api-gateway-staging -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
# ... (lặp lại cho các services khác)

# Hoặc sync qua ArgoCD UI
# Vào ArgoCD UI > Chọn application > Click "Sync"
```

---

## 4. Deploy Production Environment

### Yêu Cầu

- Tất cả yêu cầu giống Staging
- Code đã được test kỹ trên Staging
- Approval từ team lead/manager (nếu có quy trình)

### Bước 1: Verify Staging

Đảm bảo Staging environment đang chạy ổn định:

```powershell
# Check pods status
kubectl get pods -n eshelf-staging

# Check logs cho errors
kubectl logs -n eshelf-staging -l app=api-gateway --tail=100

# Test API endpoints
kubectl port-forward svc/api-gateway -n eshelf-staging 3003:3000
curl http://localhost:3003/health
```

### Bước 2: Merge Code Lên Main

```powershell
# Checkout main
git checkout main

# Merge từ staging
git merge staging

# Review changes
git log --oneline -10

# Push lên remote
git push origin main
```

**GitHub Actions sẽ tự động:**
1. Build Docker images với tag `prod`
2. Push images lên Docker Hub
3. ArgoCD Image Updater update manifests
4. ArgoCD sync và deploy lên Production

### Bước 3: Kiểm Tra Deployment

```powershell
# Check ArgoCD applications
kubectl get applications -n argocd | Select-String -Pattern "prod"

# Check pods trong production
kubectl get pods -n eshelf-prod

# Check services
kubectl get services -n eshelf-prod

# Check deployment status
kubectl get deployments -n eshelf-prod
```

### Bước 4: Verify Production

```powershell
# Port forward để test
kubectl port-forward svc/frontend -n eshelf-prod 3004:80
kubectl port-forward svc/api-gateway -n eshelf-prod 3005:3000

# Test health endpoint
curl http://localhost:3005/health

# Check logs
kubectl logs -n eshelf-prod -l app=api-gateway --tail=50
```

### Bước 5: Monitor Production

```powershell
# Watch pods
kubectl get pods -n eshelf-prod -w

# Check resource usage
kubectl top pods -n eshelf-prod

# Check events
kubectl get events -n eshelf-prod --sort-by='.lastTimestamp'
```

---

## 5. Kiểm Tra Deployment

### Script Kiểm Tra Tự Động

```powershell
# Test tất cả 3 môi trường
.\scripts\test-3-environments.ps1

# Test từng môi trường
.\scripts\test-environments.ps1 -Environment dev
.\scripts\test-environments.ps1 -Environment staging
.\scripts\test-environments.ps1 -Environment prod
```

### Kiểm Tra Thủ Công

#### Local Environment

```powershell
# Check Docker containers
docker-compose ps

# Check logs
docker-compose logs api-gateway

# Test API
curl http://localhost:3000/health
```

#### Staging/Production Environments

```powershell
# Check namespaces
kubectl get namespaces | Select-String -Pattern "eshelf"

# Check pods
kubectl get pods -n eshelf-staging
kubectl get pods -n eshelf-prod

# Check services
kubectl get services -n eshelf-staging
kubectl get services -n eshelf-prod

# Check ArgoCD applications
kubectl get applications -n argocd

# Check ingress
kubectl get ingress -n eshelf-staging
kubectl get ingress -n eshelf-prod
```

### Health Checks

```powershell
# Local
curl http://localhost:3000/health

# Staging (qua port-forward)
kubectl port-forward svc/api-gateway -n eshelf-staging 3003:3000
curl http://localhost:3003/health

# Production (qua port-forward)
kubectl port-forward svc/api-gateway -n eshelf-prod 3005:3000
curl http://localhost:3005/health
```

---

## 6. Troubleshooting

### Local Environment

#### Docker Compose không start

```powershell
# Check logs
docker-compose logs

# Check ports đang được sử dụng
netstat -ano | findstr "3000 5432 6379"

# Restart Docker
# Windows: Restart Docker Desktop
```

#### Database connection errors

```powershell
# Check PostgreSQL đang chạy
docker-compose ps postgres

# Check database logs
docker-compose logs postgres

# Recreate database
docker-compose down -v
docker-compose up -d postgres
# Chờ postgres ready, sau đó chạy migrations
```

### Staging/Production Environments

#### Pods không start (ImagePullBackOff)

```powershell
# Check image có tồn tại trên Docker Hub không
# Vào https://hub.docker.com/u/22521571/repositories

# Check image pull secrets
kubectl get secrets -n eshelf-staging

# Check pod events
kubectl describe pod <pod-name> -n eshelf-staging
```

#### ArgoCD Applications không sync

```powershell
# Check ArgoCD đang chạy
kubectl get pods -n argocd

# Check application status
kubectl describe application <app-name> -n argocd

# Manual sync
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

#### Services không accessible

```powershell
# Check services
kubectl get services -n eshelf-staging

# Check endpoints
kubectl get endpoints -n eshelf-staging

# Check pods đang chạy
kubectl get pods -n eshelf-staging

# Check logs
kubectl logs -n eshelf-staging -l app=api-gateway
```

#### GitHub Actions không build images

1. Check GitHub Secrets đã setup chưa
2. Check Docker Hub token có quyền push không
3. Xem GitHub Actions logs để tìm lỗi
4. Verify branch name đúng (`develop`, `staging`, `main`)

### Common Commands

```powershell
# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n <namespace>

# Scale deployment
kubectl scale deployment/<deployment-name> -n <namespace> --replicas=2

# Delete và recreate pod
kubectl delete pod <pod-name> -n <namespace>

# Get all resources trong namespace
kubectl get all -n <namespace>

# Describe resource để xem chi tiết
kubectl describe pod <pod-name> -n <namespace>
```

---

## Quick Reference

### Local Deployment

```powershell
cd backend
docker-compose up --build
```

### Staging Deployment

```powershell
git checkout staging
git push origin staging
# GitHub Actions tự động build và deploy
```

### Production Deployment

```powershell
git checkout main
git merge staging
git push origin main
# GitHub Actions tự động build và deploy
```

### Check Status

```powershell
# Local
docker-compose ps

# Staging
kubectl get pods -n eshelf-staging

# Production
kubectl get pods -n eshelf-prod
```

---

## Tài Liệu Liên Quan

- [COMPLETE_GUIDE.md](./COMPLETE_GUIDE.md) - Hướng dẫn tổng quan
- [3_ENVIRONMENTS_README.md](./3_ENVIRONMENTS_README.md) - Setup 3 môi trường
- [docs/3_ENVIRONMENTS_SETUP.md](./docs/3_ENVIRONMENTS_SETUP.md) - Chi tiết setup

---

**Lưu ý:** Đảm bảo đã đọc và hiểu các yêu cầu trước khi deploy lên Production!


