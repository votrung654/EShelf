# Hướng Dẫn Push Images Lên Harbor

## Vấn Đề Hiện Tại

Các deployments đang bị lỗi `ImagePullBackOff` vì:
1. Images chưa được push lên Harbor
2. Image references đã được sửa để dùng Harbor service thật

## Giải Pháp

### Bước 1: Tạo Project trong Harbor

1. Port-forward Harbor:
   ```powershell
   kubectl port-forward svc/harbor-core -n harbor 8080:80
   ```

2. Truy cập: http://localhost:8080
   - Username: `admin`
   - Password: `Harbor12345`

3. Tạo project:
   - Vào "Projects" > "New Project"
   - Name: `eshelf`
   - Public: Có thể chọn Public hoặc Private

### Bước 2: Build và Push Images

#### Option 1: Script Tự Động (Khuyến nghị)

Script tự động build và push tất cả images:

```powershell
# Port-forward Harbor trước
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Chạy script (trong terminal khác)
.\scripts\push-images-to-harbor.ps1

# Hoặc push từng service
.\scripts\push-images-to-harbor.ps1 -Service api-gateway -Tag dev
```

Script sẽ:
- Tự động build images từ Dockerfiles
- Tag với đúng format cho Harbor
- Push lên Harbor registry
- Hỗ trợ push tất cả services hoặc từng service riêng

#### Option 2: Build và Push Thủ Công

```powershell
# Port-forward Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Login vào Harbor
docker login localhost:8080 -u admin -p Harbor12345

# Build và push từng service
# API Gateway
docker build -t localhost:8080/eshelf/api-gateway:dev backend/services/api-gateway/
docker push localhost:8080/eshelf/api-gateway:dev

# Auth Service
docker build -t localhost:8080/eshelf/auth-service:dev backend/services/auth-service/
docker push localhost:8080/eshelf/auth-service:dev

# Book Service
docker build -t localhost:8080/eshelf/book-service:dev backend/services/book-service/
docker push localhost:8080/eshelf/book-service:dev

# User Service
docker build -f backend/services/user-service/Dockerfile -t localhost:8080/eshelf/user-service:dev backend/
docker push localhost:8080/eshelf/user-service:dev

# ML Service
docker build -t localhost:8080/eshelf/ml-service:dev backend/services/ml-service/
docker push localhost:8080/eshelf/ml-service:dev
```

#### Option 3: Build và Push qua GitHub Actions (Tự Động)

Workflows đã được cấu hình sẵn để build và push lên Harbor. Cần:

1. **Cấu hình GitHub Secrets:**
   - Vào GitHub repository > Settings > Secrets and variables > Actions
   - Thêm các secrets:
     - `HARBOR_REGISTRY`: Địa chỉ Harbor (ví dụ: `harbor.yourdomain.com` hoặc IP public)
     - `HARBOR_USERNAME`: `admin`
     - `HARBOR_PASSWORD`: `Harbor12345`

2. **Lưu ý:** 
   - GitHub Actions không thể truy cập trực tiếp `harbor-core.harbor.svc.cluster.local` (cluster internal)
   - Cần dùng địa chỉ Harbor có thể truy cập từ internet (qua Ingress hoặc LoadBalancer)
   - Hoặc dùng port-forward từ GitHub Actions runner (phức tạp hơn)

3. **Workflows sẽ tự động:**
   - Build images khi có code changes
   - Push lên Harbor registry
   - Tag với commit SHA và `latest`

### Bước 3: Verify Images trong Harbor

1. Vào Harbor UI
2. Vào project "eshelf"
3. Kiểm tra repositories có images chưa

### Bước 4: Scale Up Deployments

Sau khi images đã được push:

```powershell
kubectl scale deployment -n eshelf-dev --all --replicas=1
```

Hoặc apply lại kustomization:

```powershell
kubectl apply -k infrastructure/kubernetes/overlays/dev
```

## Cấu Hình Đã Sửa

### 1. Image References

Đã sửa trong `infrastructure/kubernetes/overlays/dev/kustomization.yaml`:
- Từ: `harbor.yourdomain.com/eshelf/api-gateway:dev`
- Thành: `harbor-core.harbor.svc.cluster.local/eshelf/api-gateway:dev`

### 2. ImagePullSecrets

Đã thêm vào tất cả deployments:
- `api-gateway-deployment.yaml`
- `auth-service-deployment.yaml`
- `book-service-deployment.yaml`
- `user-service-deployment.yaml`
- `ml-service-deployment.yaml`

Secret đã được tạo:
- Name: `harbor-registry-secret`
- Namespace: `eshelf-dev`
- Username: `admin`
- Password: `Harbor12345`

## Troubleshooting

### Lỗi: "failed to pull image"

1. Kiểm tra image có trong Harbor:
   ```powershell
   # Port-forward Harbor
   kubectl port-forward svc/harbor-core -n harbor 8080:80
   # Truy cập http://localhost:8080 và kiểm tra
   ```

2. Kiểm tra secret:
   ```powershell
   kubectl get secret harbor-registry-secret -n eshelf-dev
   ```

3. Kiểm tra image reference:
   ```powershell
   kubectl get deployment dev-api-gateway -n eshelf-dev -o jsonpath="{.spec.template.spec.containers[0].image}"
   ```

### Lỗi: "unauthorized"

1. Kiểm tra credentials trong secret
2. Đảm bảo project trong Harbor không phải private hoặc user có quyền

## Lưu Ý

- Images hiện đang được scale down (replicas=0) để tránh lỗi
- Sau khi push images, scale up lại
- Có thể dùng GitHub Actions để tự động build và push khi có code changes

