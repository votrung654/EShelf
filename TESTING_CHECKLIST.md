# Testing Checklist - eShelf Infrastructure

## Trước Khi Test

### 1. Kiểm Tra Cluster
```powershell
kubectl get nodes
# Kỳ vọng: 3 nodes (1 master, 2 workers) đều Ready
```

### 2. Kiểm Tra Namespaces
```powershell
kubectl get namespaces
# Kỳ vọng: argocd, monitoring, harbor, jenkins, sonarqube, eshelf-dev
```

## Test Tự Động (Đã Có Script)

```powershell
.\scripts\test-and-demo.ps1
```

## Test Thủ Công (Cần Browser)

### 1. ArgoCD UI

**Setup:**
```powershell
# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Test trong Browser:**
1. Truy cập: `https://localhost:8080`
2. Bỏ qua cảnh báo SSL (self-signed certificate)
3. Đăng nhập:
   - Username: `admin`
   - Password: Lấy bằng command:
     ```powershell
     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
     ```

**Kiểm tra:**
- [ ] Có thể đăng nhập thành công
- [ ] Thấy 6 applications (api-gateway, auth-service, book-service, ml-service, monitoring, user-service)
- [ ] Có thể click vào từng application để xem chi tiết
- [ ] Sync status hiển thị đúng

### 2. Grafana Dashboard

**Setup:**
```powershell
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

**Test trong Browser:**
1. Truy cập: `http://localhost:3000`
2. Đăng nhập:
   - Username: `admin`
   - Password: `admin123`

**Kiểm tra:**
- [ ] Có thể đăng nhập thành công
- [ ] Vào "Dashboards" > "Browse" thấy có dashboards
- [ ] Vào "Data sources" thấy Prometheus và Loki đã được cấu hình
- [ ] Có thể query metrics từ Prometheus
- [ ] Có thể query logs từ Loki

### 3. Prometheus

**Setup:**
```powershell
kubectl port-forward svc/prometheus -n monitoring 9090:9090
```

**Test trong Browser:**
1. Truy cập: `http://localhost:9090`

**Kiểm tra:**
- [ ] UI load được
- [ ] Vào "Status" > "Targets" thấy các targets đang scrape
- [ ] Vào "Graph" có thể query metrics (thử: `up`, `kube_pod_info`)
- [ ] Vào "Alerts" thấy các alerts đã được cấu hình

### 4. Harbor Registry

**Setup:**
```powershell
kubectl port-forward svc/harbor-core -n harbor 8080:80
```

**Test trong Browser:**
1. Truy cập: `http://localhost:8080`
2. Đăng nhập:
   - Username: `admin`
   - Password: `Harbor12345`

**Kiểm tra:**
- [ ] Có thể đăng nhập thành công
- [ ] Vào "Projects" có thể tạo project mới
- [ ] Tạo project "eshelf" (nếu chưa có)
- [ ] Vào "Repositories" xem có images nào chưa (hiện tại chưa có)

### 5. Loki Logs (Qua Grafana)

**Trong Grafana UI:**
1. Vào "Explore"
2. Chọn datasource "Loki"
3. Query: `{namespace="monitoring"}`
4. Kiểm tra logs có được collect không

### 6. SonarQube (Nếu Pod Running)

**Kiểm tra trạng thái:**
```powershell
kubectl get pods -n sonarqube
```

**Nếu pod đang Running:**
```powershell
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000
```

**Test trong Browser:**
1. Truy cập: `http://localhost:9000`
2. Đăng nhập:
   - Username: `admin`
   - Password: `admin` (đổi password lần đầu)

**Kiểm tra:**
- [ ] Có thể đăng nhập
- [ ] Có thể tạo project
- [ ] Có thể generate token

### 7. Jenkins (Nếu Pod Running)

**Kiểm tra trạng thái:**
```powershell
kubectl get pods -n jenkins
```

**Nếu pod đang Running:**
```powershell
kubectl port-forward svc/jenkins -n jenkins 8080:8080
```

**Lấy admin password:**
```powershell
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

**Test trong Browser:**
1. Truy cập: `http://localhost:8080`
2. Đăng nhập với password từ command trên

**Kiểm tra:**
- [ ] Có thể đăng nhập
- [ ] Có thể tạo pipeline job
- [ ] Có thể point đến Jenkinsfile

## Test eShelf Applications (Sau Khi Push Images)

### 1. Push Images Lên Harbor
Xem `HARBOR_IMAGE_SETUP.md`

### 2. Scale Up Deployments
```powershell
kubectl scale deployment -n eshelf-dev --all --replicas=1
```

### 3. Kiểm Tra Pods
```powershell
kubectl get pods -n eshelf-dev
# Kỳ vọng: Tất cả pods đang Running
```

### 4. Test API Gateway
```powershell
# Port-forward
kubectl port-forward svc/dev-api-gateway -n eshelf-dev 3000:3000

# Test trong Browser hoặc curl
curl http://localhost:3000/health
```

## Checklist Tổng Hợp

### Infrastructure
- [ ] Cluster có 3 nodes đều Ready
- [ ] Tất cả namespaces đã được tạo
- [ ] Network policies đã được apply

### ArgoCD
- [ ] ArgoCD UI accessible
- [ ] Có thể đăng nhập
- [ ] Thấy 6 applications
- [ ] Applications có sync status

### Monitoring
- [ ] Grafana accessible và có thể đăng nhập
- [ ] Prometheus accessible
- [ ] Có thể query metrics
- [ ] Có thể query logs qua Grafana

### Harbor
- [ ] Harbor UI accessible và có thể đăng nhập
- [ ] Có thể tạo project
- [ ] Có thể push images (sau khi setup)

### SonarQube (Optional)
- [ ] Pod đang Running (nếu đủ resources)
- [ ] UI accessible
- [ ] Có thể tạo project và token

### Jenkins (Optional)
- [ ] Pod đang Running (nếu đủ resources)
- [ ] UI accessible
- [ ] Có thể tạo pipeline

### eShelf Applications
- [ ] Images đã được push lên Harbor
- [ ] Deployments đã được scale up
- [ ] Pods đang Running
- [ ] Services accessible

## Lưu Ý

1. **Port Forward:** Mỗi lần chỉ có thể port-forward một service. Cần mở terminal riêng cho mỗi service.

2. **SSL Warnings:** ArgoCD dùng self-signed certificate, browser sẽ cảnh báo. Có thể bỏ qua cho testing.

3. **Resources:** SonarQube và Jenkins có thể pending do thiếu resources. Có thể tạm thời bỏ qua hoặc tăng instance size.

4. **Images:** eShelf applications chưa có images nên đang được scale down. Cần push images lên Harbor trước.

