# Thiết lập Harbor cho eShelf

## Yêu cầu

- Kubernetes cluster
- Helm 3.x
- Ingress controller (khuyến nghị nginx-ingress)
- cert-manager (tùy chọn, cho TLS)

## Cài đặt

### 1. Thêm Harbor Helm Repository

```bash
helm repo add harbor https://helm.goharbor.io
helm repo update
```

### 2. Tạo Namespace

```bash
kubectl create namespace harbor
```

### 3. Cài đặt Harbor

```bash
# Cài đặt với custom values
helm install harbor harbor/harbor -f harbor-values.yaml -n harbor

# Hoặc cài đặt với giá trị mặc định
helm install harbor harbor/harbor -n harbor
```

### 4. Đợi Harbor sẵn sàng

```bash
kubectl wait --for=condition=available --timeout=600s deployment/harbor-core -n harbor
```

### 5. Lấy mật khẩu Admin

```bash
kubectl get secret harbor-core -n harbor -o jsonpath="{.data.HARBOR_ADMIN_PASSWORD}" | base64 -d
```

User admin mặc định: `admin`
Mật khẩu mặc định: (từ lệnh trên hoặc `Harbor12345` nếu dùng harbor-values.yaml)

## Cấu hình

### Cập nhật harbor-values.yaml

1. Thay đổi `harbor.yourdomain.com` thành domain của bạn
2. Cập nhật `harborAdminPassword` (dùng mật khẩu mạnh)
3. Cấu hình storage classes cho cluster của bạn
4. Cập nhật cài đặt TLS nếu dùng cert-manager

### Truy cập Harbor

- URL: https://harbor.yourdomain.com (hoặc port-forward)
- Username: admin
- Password: (từ secret hoặc harbor-values.yaml)

### Port Forward (để test)

```bash
kubectl port-forward svc/harbor-core -n harbor 8080:80
```

Truy cập: http://localhost:8080

## Tạo Project

1. Đăng nhập vào Harbor UI
2. Vào Projects → New Project
3. Tạo project: `eshelf`
4. Đặt là public hoặc private

## Cấu hình Docker Login

```bash
# Đăng nhập vào Harbor
docker login harbor.yourdomain.com -u admin -p <password>

# Tag image
docker tag eshelf/api-gateway:latest harbor.yourdomain.com/eshelf/api-gateway:latest

# Push image
docker push harbor.yourdomain.com/eshelf/api-gateway:latest
```

## Cập nhật CI/CD

Cập nhật Jenkinsfile và GitHub Actions workflows để sử dụng Harbor registry:

```yaml
DOCKER_REGISTRY: 'harbor.yourdomain.com'
```
