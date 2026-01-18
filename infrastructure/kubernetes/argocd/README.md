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

### Thiết lập Git Credentials (QUAN TRỌNG - Cần cho Write-back)

ArgoCD Image Updater cần quyền write vào Git repository để commit ngược lại. Cấu hình như sau:

#### Cách 1: Sử dụng ArgoCD CLI (Khuyến nghị)

```bash
# Đăng nhập ArgoCD
argocd login <argocd-server-url>

# Thêm repository với credentials có quyền write
argocd repo add https://github.com/votrung654/EShelf.git \
  --username <github-username> \
  --password <github-token> \
  --type git
```

**Lưu ý:** Cần sử dụng GitHub Personal Access Token (PAT) với quyền `repo` để có quyền write.

#### Cách 2: Sử dụng Kubernetes Secret

```bash
# Tạo secret cho Git credentials
kubectl create secret generic git-creds \
  --from-literal=username=<github-username> \
  --from-literal=password=<github-token> \
  -n argocd

# Thêm repository vào ArgoCD
argocd repo add https://github.com/votrung654/EShelf.git \
  --username <github-username> \
  --password <github-token>
```

### Cấu hình Registry Credentials

```bash
# Tạo secret cho Docker Hub credentials
kubectl create secret generic dockerhub-creds \
  --from-literal=username=<dockerhub-username> \
  --from-literal=password=<dockerhub-token> \
  -n argocd
```

### Annotations trong Applications

Tất cả 5 backend services đã được cấu hình với các annotations sau:

```yaml
annotations:
  # Image list với Docker Hub
  argocd-image-updater.argoproj.io/image-list: api-gateway=docker.io/22521571/eshelf-api-gateway
  
  # Update strategy: digest (theo dõi mã băm, tránh lỗi semantic version)
  argocd-image-updater.argoproj.io/api-gateway.update-strategy: digest
  
  # Chỉ định tag cụ thể để theo dõi
  argocd-image-updater.argoproj.io/api-gateway.allow-tags-regex: '^dev$'
  
  # Git write-back configuration
  argocd-image-updater.argoproj.io/write-back-method: git
  argocd-image-updater.argoproj.io/git-branch: main
  argocd-image-updater.argoproj.io/write-back-target: kustomization
  argocd-image-updater.argoproj.io/kustomize-image-name: eshelf/api-gateway
  argocd-image-updater.argoproj.io/git-commit-user: github-actions[bot]
  argocd-image-updater.argoproj.io/git-commit-email: github-actions[bot]@users.noreply.github.com
```

### Kiểm tra Write-back hoạt động

```bash
# Xem logs của ArgoCD Image Updater
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater --tail=100

# Kiểm tra applications
kubectl get applications -n argocd

# Xem chi tiết một application
kubectl describe application api-gateway -n argocd
```

### Troubleshooting

1. **Bot không commit**: Kiểm tra Git credentials có quyền write không
2. **Lỗi "Invalid Semantic Version"**: Đã sử dụng `digest` strategy thay vì `latest`
3. **Image không được cập nhật**: Kiểm tra `allow-tags-regex` có khớp với tag trên Docker Hub không
