# Thiết lập ArgoCD cho eShelf

## Cài đặt

```bash
# Tạo namespace
kubectl create namespace argocd

# Cài đặt ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Đợi ArgoCD sẵn sàng
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Lấy mật khẩu admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward để truy cập UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Truy cập ArgoCD UI: https://localhost:8080
- Username: admin
- Password: (từ lệnh trên)

## Thiết lập Applications

```bash
# Apply các applications
kubectl apply -f applications/

# Hoặc dùng ArgoCD CLI
argocd app create api-gateway -f applications/api-gateway-app.yaml
```

## ArgoCD Image Updater

ArgoCD Image Updater tự động cập nhật image tags khi có image mới được push lên registry.

Thiết lập:
1. Cài đặt ArgoCD Image Updater
2. Cấu hình registry credentials
3. Thêm annotations cho applications với update policies

Ví dụ annotation:
```yaml
argocd-image-updater.argoproj.io/image-list: api-gateway=harbor.yourdomain.com/eshelf/api-gateway
argocd-image-updater.argoproj.io/write-back-method: git
argocd-image-updater.argoproj.io/git-branch: main
```
