# Hướng Dẫn Test Thủ Công Đầy Đủ - eShelf Infrastructure

## Trước Khi Bắt Đầu

### Kiểm Tra Cluster Status

```powershell
# Kiểm tra nodes
kubectl get nodes

# Kiểm tra tất cả pods
kubectl get pods -A

# Kiểm tra services
kubectl get svc -A

# Kiểm tra resource usage
kubectl top nodes
kubectl top pods -A
```

**Kỳ vọng:**
- 3 nodes đều Ready
- Hầu hết pods đang Running
- Jenkins và SonarQube đã Running (sau khi optimize)

## Test 1: ArgoCD UI

### Setup

```powershell
# Terminal 1: Port-forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Test Trong Browser

1. **Truy cập:** `https://localhost:8080`
2. **Bỏ qua cảnh báo SSL:** Click "Advanced" > "Proceed to localhost"
3. **Lấy admin password:**
   ```powershell
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
   ```
4. **Đăng nhập:**
   - Username: `admin`
   - Password: (từ command trên)

### Kiểm Tra

- [ ] Có thể đăng nhập thành công
- [ ] Thấy dashboard với 6 applications
- [ ] Click vào từng application:
  - api-gateway
  - auth-service
  - book-service
  - ml-service
  - monitoring
  - user-service
- [ ] Kiểm tra sync status và health status
- [ ] Có thể click "Sync" nếu cần
- [ ] Xem resources của từng application

## Test 2: Grafana Dashboard

### Setup

```powershell
# Terminal 2: Port-forward Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

### Test Trong Browser

1. **Truy cập:** `http://localhost:3000`
2. **Đăng nhập:**
   - Username: `admin`
   - Password: `admin123`

### Kiểm Tra

- [ ] Có thể đăng nhập thành công
- [ ] Vào "Dashboards" > "Browse":
  - [ ] Thấy có dashboards (nếu có)
  - [ ] Có thể tạo dashboard mới
- [ ] Vào "Data sources":
  - [ ] Thấy Prometheus đã được cấu hình
  - [ ] Thấy Loki đã được cấu hình
  - [ ] Test connection cho cả hai
- [ ] Vào "Explore":
  - [ ] Chọn datasource "Prometheus"
  - [ ] Query: `up` hoặc `kube_pod_info`
  - [ ] Thấy kết quả
  - [ ] Chọn datasource "Loki"
  - [ ] Query: `{namespace="monitoring"}`
  - [ ] Thấy logs

## Test 3: Prometheus

### Setup

```powershell
# Terminal 3: Port-forward Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090
```

### Test Trong Browser

1. **Truy cập:** `http://localhost:9090`

### Kiểm Tra

- [ ] UI load được
- [ ] Vào "Status" > "Targets":
  - [ ] Thấy các targets đang scrape
  - [ ] Targets có status "UP"
- [ ] Vào "Graph":
  - [ ] Query: `up`
  - [ ] Thấy kết quả
  - [ ] Query: `kube_pod_info`
  - [ ] Thấy thông tin pods
- [ ] Vào "Alerts":
  - [ ] Thấy các alerts đã được cấu hình
  - [ ] Kiểm tra alert rules

## Test 4: Harbor Registry

### Setup

```powershell
# Terminal 4: Port-forward Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80
```

### Test Trong Browser

1. **Truy cập:** `http://localhost:8080`
2. **Đăng nhập:**
   - Username: `admin`
   - Password: `Harbor12345`

### Kiểm Tra

- [ ] Có thể đăng nhập thành công
- [ ] Vào "Projects":
  - [ ] Tạo project mới tên "eshelf" (nếu chưa có)
  - [ ] Đặt là Public hoặc Private
- [ ] Vào project "eshelf":
  - [ ] Xem repositories (hiện tại chưa có images)
  - [ ] Có thể tạo repository thủ công
- [ ] Vào "Administration" > "Registries":
  - [ ] Kiểm tra cấu hình registry

### Test Push Image (Sau Khi Có Script)

```powershell
# Chạy script push images
.\scripts\push-images-to-harbor.ps1

# Sau đó refresh Harbor UI và kiểm tra images đã được push
```

## Test 5: SonarQube

### Kiểm Tra Trạng Thái

```powershell
kubectl get pods -n sonarqube
# Kỳ vọng: sonarqube pod đang Running
```

### Setup (Nếu Pod Running)

```powershell
# Terminal 5: Port-forward SonarQube
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000
```

### Test Trong Browser

1. **Truy cập:** `http://localhost:9000`
2. **Đăng nhập lần đầu:**
   - Username: `admin`
   - Password: `admin`
   - Hệ thống sẽ yêu cầu đổi password

### Kiểm Tra

- [ ] Có thể đăng nhập thành công
- [ ] Đổi password mới
- [ ] Vào "Projects":
  - [ ] Tạo project mới
  - [ ] Generate token
- [ ] Vào "My Account" > "Security":
  - [ ] Generate token
  - [ ] Copy token để dùng trong GitHub Actions

## Test 6: Jenkins

### Kiểm Tra Trạng Thái

```powershell
kubectl get pods -n jenkins
# Kỳ vọng: jenkins pod đang Running
```

### Setup (Nếu Pod Running)

```powershell
# Terminal 6: Port-forward Jenkins
kubectl port-forward svc/jenkins -n jenkins 8080:8080
```

### Lấy Admin Password

```powershell
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### Test Trong Browser

1. **Truy cập:** `http://localhost:8080`
2. **Đăng nhập:**
   - Username: `admin`
   - Password: (từ command trên)

### Kiểm Tra

- [ ] Có thể đăng nhập thành công
- [ ] Install recommended plugins
- [ ] Tạo pipeline job:
  - [ ] New Item > Pipeline
  - [ ] Point to `jenkins/Jenkinsfile`
  - [ ] Configure SonarQube và Harbor credentials
- [ ] Chạy build và kiểm tra kết quả

## Test 7: eShelf Applications (Sau Khi Push Images)

### Push Images Trước

```powershell
# Terminal 1: Port-forward Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Terminal 2: Chạy script
.\scripts\push-images-to-harbor.ps1
```

### Scale Up Deployments

```powershell
kubectl scale deployment -n eshelf-dev --all --replicas=1
```

### Kiểm Tra Pods

```powershell
kubectl get pods -n eshelf-dev
# Kỳ vọng: Tất cả pods đang Running
```

### Test API Gateway

```powershell
# Port-forward
kubectl port-forward svc/dev-api-gateway -n eshelf-dev 3000:3000
```

**Test trong Browser hoặc curl:**
```powershell
# Health check
curl http://localhost:3000/health

# Hoặc mở browser: http://localhost:3000/health
```

## Test 8: Network Connectivity

### Test Từ Pod Đến Service

```powershell
# Tạo debug pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# Trong pod debug:
# Test Prometheus
wget -O- http://prometheus.monitoring.svc.cluster.local:9090/-/healthy

# Test Grafana
wget -O- http://grafana.monitoring.svc.cluster.local:3000/api/health

# Test API Gateway (nếu đang chạy)
wget -O- http://dev-api-gateway.eshelf-dev.svc.cluster.local:3000/health
```

## Test 9: Resource Usage

### Kiểm Tra Resources

```powershell
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -A

# Chi tiết từng pod
kubectl describe pod <pod-name> -n <namespace>
```

### Kiểm Tra Trong Grafana

1. Vào Grafana UI
2. Tạo dashboard mới hoặc dùng dashboard có sẵn
3. Query metrics:
   - CPU usage: `rate(container_cpu_usage_seconds_total[5m])`
   - Memory usage: `container_memory_usage_bytes`
   - Pod count: `count(kube_pod_info)`

## Test 10: Logs

### Kiểm Tra Logs Qua kubectl

```powershell
# Logs của một pod
kubectl logs <pod-name> -n <namespace>

# Logs của tất cả pods trong namespace
kubectl logs -n <namespace> --all-containers=true

# Follow logs
kubectl logs -f <pod-name> -n <namespace>
```

### Kiểm Tra Logs Qua Grafana

1. Vào Grafana UI
2. Vào "Explore"
3. Chọn datasource "Loki"
4. Query: `{namespace="monitoring"}`
5. Xem logs real-time

## Checklist Tổng Hợp

### Infrastructure
- [ ] Cluster có 3 nodes đều Ready
- [ ] Tất cả namespaces đã được tạo
- [ ] Network policies đã được apply
- [ ] Resource usage hợp lý

### ArgoCD
- [ ] UI accessible và có thể đăng nhập
- [ ] Thấy 6 applications
- [ ] Có thể sync applications
- [ ] Applications có sync status đúng

### Monitoring
- [ ] Grafana accessible và có thể đăng nhập
- [ ] Prometheus accessible
- [ ] Có thể query metrics
- [ ] Có thể query logs qua Grafana
- [ ] Dashboards hoạt động

### Harbor
- [ ] UI accessible và có thể đăng nhập
- [ ] Có thể tạo project
- [ ] Có thể push images (sau khi chạy script)
- [ ] Images có thể pull được

### SonarQube
- [ ] Pod đang Running
- [ ] UI accessible và có thể đăng nhập
- [ ] Có thể tạo project và token

### Jenkins
- [ ] Pod đang Running
- [ ] UI accessible và có thể đăng nhập
- [ ] Có thể tạo pipeline job

### eShelf Applications
- [ ] Images đã được push lên Harbor
- [ ] Deployments đã được scale up
- [ ] Pods đang Running
- [ ] Services accessible
- [ ] Health checks pass

## Troubleshooting

### Lỗi: "Port already in use"

Giải pháp: Dùng port khác hoặc kill process đang dùng port:
```powershell
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

### Lỗi: "Connection refused"

Giải pháp:
- Kiểm tra port-forward đang chạy
- Kiểm tra pod đang Running
- Kiểm tra service tồn tại

### Lỗi: "SSL certificate error"

Giải pháp: Bỏ qua cảnh báo SSL cho ArgoCD (self-signed certificate)

### Lỗi: "Cannot login"

Giải pháp:
- Kiểm tra credentials
- Kiểm tra pod đang Running
- Kiểm tra logs của pod

## Lưu Ý

1. **Port Forward:** Mỗi service cần một terminal riêng hoặc chạy background
2. **Thứ tự test:** Nên test theo thứ tự (ArgoCD → Monitoring → Harbor → SonarQube → Jenkins)
3. **Images:** eShelf applications cần push images trước khi test
4. **Resources:** Monitor resource usage để tránh quá tải

