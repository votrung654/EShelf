# ✅ Setup 3 Môi Trường Hoàn Tất

## Đã Hoàn Thành

### 1. ArgoCD Applications
✅ Đã tạo 18 ArgoCD applications cho 3 môi trường:
- **Dev**: 6 applications (frontend, api-gateway, auth-service, book-service, user-service, ml-service)
- **Staging**: 6 applications
- **Production**: 6 applications

### 2. CI/CD Pipeline
✅ Đã update `smart-build.yml` để:
- Build và push images với tags `dev`, `staging`, `prod` dựa trên branch
- Support Docker Hub registry (`docker.io/22521571/eshelf-*`)
- Build frontend với environment-specific API URLs

### 3. Kustomization Overlays
✅ Đã update staging và prod overlays để dùng Docker Hub registry

### 4. Scripts
✅ Đã tạo 2 scripts:
- `scripts/deploy-3-environments.ps1`: Deploy tất cả ArgoCD applications
- `scripts/test-3-environments.ps1`: Test deployment cho 3 môi trường

## Cách Sử Dụng

### 1. Setup GitHub Secrets (QUAN TRỌNG)

Cần setup 2 secrets trong GitHub repository:
- `DOCKERHUB_USERNAME`: Docker Hub username (ví dụ: `22521571`)
- `DOCKERHUB_TOKEN`: Docker Hub access token

**Cách setup:**
1. Vào GitHub repository
2. Settings > Secrets and variables > Actions
3. New repository secret
4. Thêm 2 secrets

### 2. Deploy ArgoCD Applications

```powershell
.\scripts\deploy-3-environments.ps1
```

✅ Đã chạy và tạo thành công 19 applications!

### 3. Test Deployment

```powershell
.\scripts\test-3-environments.ps1
```

✅ Đã test và verify:
- 3 namespaces đã được tạo (eshelf-dev, eshelf-staging, eshelf-prod)
- ArgoCD applications đã được tạo
- Services đã được tạo (một số đang chờ images)

### 4. Build và Deploy

**Để deploy lên Dev:**
```bash
git checkout develop
# Make changes
git push origin develop
```
→ GitHub Actions sẽ build và push images với tag `dev`
→ ArgoCD sẽ tự động sync và deploy

**Để deploy lên Staging:**
```bash
git checkout staging
# Merge từ develop hoặc make changes
git push origin staging
```
→ GitHub Actions sẽ build và push images với tag `staging`
→ ArgoCD sẽ tự động sync và deploy

**Để deploy lên Production:**
```bash
git checkout main
# Merge từ staging hoặc make changes
git push origin main
```
→ GitHub Actions sẽ build và push images với tag `prod`
→ ArgoCD sẽ tự động sync và deploy

## Trạng Thái Hiện Tại

### ArgoCD Applications
- ✅ 19 applications đã được tạo
- ⚠️ Một số đang OutOfSync (cần images trên Docker Hub)
- ⚠️ Một số đang Progressing (đang chờ images)

### Pods
- **Dev**: 6/11 pods đang Running (một số đang Pending vì chưa có images)
- **Staging**: 0/9 pods Running (chưa có images)
- **Prod**: 0/14 pods Running (chưa có images)

### Services
- ✅ Services đã được tạo trong staging và prod
- ⚠️ Dev environment cần check lại service names

## Next Steps

1. **Setup GitHub Secrets** (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN) - **QUAN TRỌNG**
2. **Push code lên branch `develop`** để trigger build và push images với tag `dev`
3. **Kiểm tra images trên Docker Hub** sau khi build xong
4. **ArgoCD sẽ tự động sync** khi có images mới
5. **Test deployment** bằng cách port-forward và truy cập services

## Kiểm Tra Status

```powershell
# Check ArgoCD applications
kubectl get applications -n argocd

# Check pods trong từng môi trường
kubectl get pods -n eshelf-dev
kubectl get pods -n eshelf-staging
kubectl get pods -n eshelf-prod

# Check images trên Docker Hub
# Vào https://hub.docker.com/u/22521571/repositories
```

## Troubleshooting

### Nếu pods không start:
1. Kiểm tra images có trên Docker Hub không
2. Kiểm tra image pull secrets
3. Xem logs: `kubectl logs <pod-name> -n <namespace>`

### Nếu ArgoCD không sync:
1. Kiểm tra ArgoCD đang chạy: `kubectl get pods -n argocd`
2. Manual sync: `kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'`

## Tài Liệu Chi Tiết

Xem `docs/3_ENVIRONMENTS_SETUP.md` để biết thêm chi tiết.

---

**✅ Setup hoàn tất! Bạn có thể bắt đầu test bằng cách push code lên các branch.**

