# Quick Deploy Guide - eShelf

## 🚀 Deploy Nhanh 3 Môi Trường

### 📍 Local Environment

```powershell
# Cách 1: Dùng script (Khuyến nghị)
.\scripts\deploy-local.ps1

# Cách 2: Docker Compose thủ công
cd backend
docker-compose up --build

# Chạy Frontend riêng (từ thư mục root)
npm run dev
```

**URLs:**
- Frontend: http://localhost:5173
- API Gateway: http://localhost:3000
- Auth Service: http://localhost:3001
- Book Service: http://localhost:3002
- User Service: http://localhost:3003
- ML Service: http://localhost:8000

---

### 🧪 Staging Environment

```powershell
# Bước 1: Deploy ArgoCD applications
.\scripts\deploy-staging.ps1

# Bước 2: Push code lên branch staging
git checkout staging
git push origin staging

# GitHub Actions tự động build và deploy
```

**Kiểm tra:**
```powershell
kubectl get pods -n eshelf-staging
kubectl port-forward svc/api-gateway -n eshelf-staging 3003:3000
```

---

### 🏭 Production Environment

```powershell
# Bước 1: Deploy ArgoCD applications (cần xác nhận)
.\scripts\deploy-production.ps1

# Bước 2: Push code lên branch main
git checkout main
git merge staging
git push origin main

# GitHub Actions tự động build và deploy
```

**Kiểm tra:**
```powershell
kubectl get pods -n eshelf-prod
kubectl port-forward svc/api-gateway -n eshelf-prod 3005:3000
```

---

## 📋 Yêu Cầu Trước Khi Deploy

### Local
- ✅ Docker Desktop đã cài và chạy
- ✅ Ports: 3000, 3001, 3002, 3003, 5432, 6379, 8000, 5173

### Staging/Production
- ✅ Kubernetes cluster đã setup
- ✅ kubectl đã cấu hình
- ✅ ArgoCD đã deploy
- ✅ GitHub Secrets:
  - `DOCKERHUB_USERNAME`
  - `DOCKERHUB_TOKEN`

---

## 🔍 Kiểm Tra Status

### Local
```powershell
docker-compose -f backend/docker-compose.yml ps
docker-compose -f backend/docker-compose.yml logs -f
```

### Staging/Production
```powershell
# Check applications
kubectl get applications -n argocd

# Check pods
kubectl get pods -n eshelf-staging
kubectl get pods -n eshelf-prod

# Check services
kubectl get services -n eshelf-staging
kubectl get services -n eshelf-prod
```

---

## 🛠️ Troubleshooting

### Local - Containers không start
```powershell
# Check logs
docker-compose -f backend/docker-compose.yml logs

# Restart
docker-compose -f backend/docker-compose.yml restart

# Recreate
docker-compose -f backend/docker-compose.yml down -v
docker-compose -f backend/docker-compose.yml up --build
```

### Staging/Production - Pods không start
```powershell
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check ArgoCD sync
kubectl get applications -n argocd
```

---

## 📚 Tài Liệu Chi Tiết

- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Hướng dẫn chi tiết đầy đủ
- [COMPLETE_GUIDE.md](./COMPLETE_GUIDE.md) - Hướng dẫn tổng quan project
- [3_ENVIRONMENTS_README.md](./3_ENVIRONMENTS_README.md) - Setup 3 môi trường

---

## ⚡ Quick Commands

```powershell
# Deploy tất cả 3 môi trường (Kubernetes)
.\scripts\deploy-3-environments.ps1

# Test environments
.\scripts\test-3-environments.ps1

# Stop local
docker-compose -f backend/docker-compose.yml down

# View logs
docker-compose -f backend/docker-compose.yml logs -f <service-name>
```

---

**💡 Tip:** Đọc [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) để biết chi tiết và troubleshooting!


