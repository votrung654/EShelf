# Hướng Dẫn Setup 3 Môi Trường (Dev, Staging, Production)

## Tổng Quan

Hệ thống eShelf đã được cấu hình để hỗ trợ 3 môi trường:
- **Dev**: Môi trường phát triển (branch `develop`)
- **Staging**: Môi trường staging (branch `staging`)
- **Production**: Môi trường production (branch `main`)

## Kiến Trúc

### Branch Strategy
- `develop` → Build và push images với tag `dev`
- `staging` → Build và push images với tag `staging`
- `main` → Build và push images với tag `prod`

### Docker Hub Registry
Tất cả images được push lên Docker Hub:
- Registry: `docker.io/22521571/eshelf-*`
- Tags: `dev`, `staging`, `prod`, `latest`, và SHA commit

### Kubernetes Namespaces
- `eshelf-dev`: Môi trường development
- `eshelf-staging`: Môi trường staging
- `eshelf-prod`: Môi trường production

### ArgoCD Applications
Mỗi service có 3 ArgoCD applications (1 cho mỗi môi trường):
- Frontend: `frontend-dev`, `frontend-staging`, `frontend-prod`
- API Gateway: `api-gateway-dev`, `api-gateway-staging`, `api-gateway-prod`
- Auth Service: `auth-service-dev`, `auth-service-staging`, `auth-service-prod`
- Book Service: `book-service-dev`, `book-service-staging`, `book-service-prod`
- User Service: `user-service-dev`, `user-service-staging`, `user-service-prod`
- ML Service: `ml-service-dev`, `ml-service-staging`, `ml-service-prod`

## Setup GitHub Secrets

Cần setup các secrets sau trong GitHub repository:

1. **DOCKERHUB_USERNAME**: Docker Hub username (ví dụ: `22521571`)
2. **DOCKERHUB_TOKEN**: Docker Hub access token

**Cách setup:**
1. Vào GitHub repository
2. Settings > Secrets and variables > Actions
3. New repository secret
4. Thêm 2 secrets:
   - Name: `DOCKERHUB_USERNAME`, Value: Docker Hub username
   - Name: `DOCKERHUB_TOKEN`, Value: Docker Hub access token

## Deploy ArgoCD Applications

### Cách 1: Dùng Script (Khuyến nghị)

```powershell
.\scripts\deploy-3-environments.ps1
```

Script này sẽ:
1. Kiểm tra kết nối cluster
2. Tạo ArgoCD namespace nếu chưa có
3. Apply tất cả ArgoCD applications
4. Hiển thị status

### Cách 2: Thủ Công

```powershell
# Apply tất cả applications
kubectl apply -f infrastructure/kubernetes/argocd/applications/

# Kiểm tra status
kubectl get applications -n argocd
```

## Workflow CI/CD

### Smart Build Pipeline

Khi push code lên các branch:
- **develop**: Build và push images với tag `dev`
- **staging**: Build và push images với tag `staging`
- **main**: Build và push images với tag `prod`

Pipeline sẽ:
1. Detect changes (chỉ build services có thay đổi)
2. Build Docker images
3. Push lên Docker Hub với tags tương ứng
4. ArgoCD Image Updater tự động update manifests
5. ArgoCD tự động sync và deploy

### Frontend Build

Frontend được build với environment-specific API URL:
- Dev: `http://api-gateway:3000/api`
- Staging: `https://staging-api.eshelf.example.com/api`
- Prod: `https://api.eshelf.example.com/api`

## Test Deployment

### Chạy Test Script

```powershell
.\scripts\test-3-environments.ps1
```

Script này sẽ kiểm tra:
1. Namespaces tồn tại
2. Pods đang chạy
3. Services được tạo
4. ArgoCD applications status

### Kiểm Tra Thủ Công

```powershell
# Check ArgoCD applications
kubectl get applications -n argocd

# Check pods trong từng môi trường
kubectl get pods -n eshelf-dev
kubectl get pods -n eshelf-staging
kubectl get pods -n eshelf-prod

# Check services
kubectl get services -n eshelf-dev
kubectl get services -n eshelf-staging
kubectl get services -n eshelf-prod

# Check ArgoCD sync status
kubectl get applications -n argocd -o wide
```

## Port Forward để Test

```powershell
# Dev Environment
kubectl port-forward svc/frontend -n eshelf-dev 3000:80
kubectl port-forward svc/api-gateway -n eshelf-dev 3001:3000

# Staging Environment
kubectl port-forward svc/frontend -n eshelf-staging 3002:80
kubectl port-forward svc/api-gateway -n eshelf-staging 3003:3000

# Production Environment
kubectl port-forward svc/frontend -n eshelf-prod 3004:80
kubectl port-forward svc/api-gateway -n eshelf-prod 3005:3000
```

## Troubleshooting

### Images không được push lên Docker Hub

1. Kiểm tra GitHub Secrets đã setup chưa
2. Kiểm tra Docker Hub token có quyền push không
3. Xem GitHub Actions logs để tìm lỗi

### ArgoCD Applications không sync

1. Kiểm tra ArgoCD đang chạy:
   ```powershell
   kubectl get pods -n argocd
   ```

2. Kiểm tra application status:
   ```powershell
   kubectl describe application <app-name> -n argocd
   ```

3. Manual sync nếu cần:
   ```powershell
   kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
   ```

### Pods không start được

1. Kiểm tra image pull secrets:
   ```powershell
   kubectl get secrets -n eshelf-dev
   ```

2. Kiểm tra image có tồn tại trên Docker Hub không
3. Kiểm tra logs:
   ```powershell
   kubectl logs <pod-name> -n <namespace>
   ```

## Kustomization Overlays

Mỗi môi trường có overlay riêng trong `infrastructure/kubernetes/overlays/`:
- `dev/`: Development environment
- `staging/`: Staging environment
- `prod/`: Production environment

Mỗi overlay có:
- `kustomization.yaml`: Config cho môi trường
- `ingress-patch.yaml`: Ingress config
- Service-specific patches: Resource limits, replicas, etc.

## Replicas Configuration

- **Dev**: 1 replica cho tất cả services
- **Staging**: 1-2 replicas tùy service
- **Prod**: 2-3 replicas tùy service

## Resource Limits

Mỗi môi trường có resource limits khác nhau:
- **Dev**: Lower limits (để tiết kiệm tài nguyên)
- **Staging**: Medium limits
- **Prod**: Higher limits (để đảm bảo performance)

## Next Steps

1. Setup GitHub Secrets (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN)
2. Deploy ArgoCD applications: `.\scripts\deploy-3-environments.ps1`
3. Push code lên branch `develop` để test dev environment
4. Test deployment: `.\scripts\test-3-environments.ps1`
5. Promote code từ `develop` → `staging` → `main` để deploy lên các môi trường

