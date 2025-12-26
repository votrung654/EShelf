# Final Testing Checklist - eShelf Infrastructure

## Trạng Thái Hiện Tại

### Đã Hoàn Thành
- [x] Cluster 3 nodes (1 master, 2 workers)
- [x] ArgoCD deployed (7/7 pods Running)
- [x] Monitoring stack deployed (7/7 pods Running)
- [x] Harbor deployed (8/8 pods Running)
- [x] Jenkins deployed (1/1 pod Running)
- [x] SonarQube deployed (Postgres Running, SonarQube đang start)
- [x] Network policies applied
- [x] Image references đã sửa
- [x] ImagePullSecrets đã tạo
- [x] Resources đã optimize (overcommit strategy)

### Cần Làm
- [ ] Push images lên Harbor
- [ ] Scale up eShelf applications
- [ ] Test thủ công qua browser

## Quick Test Commands

### 1. Kiểm Tra Tổng Quan

```powershell
# Tất cả pods
kubectl get pods -A

# Services
kubectl get svc -A

# Resource usage
kubectl top nodes
kubectl top pods -A

# Applications
kubectl get applications -n argocd
```

### 2. Test ArgoCD

```powershell
# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Browser: https://localhost:8080
# Username: admin
# Password: (lấy từ secret)
```

### 3. Test Grafana

```powershell
# Port-forward
kubectl port-forward svc/grafana -n monitoring 3000:3000

# Browser: http://localhost:3000
# Username: admin / Password: admin123
```

### 4. Test Prometheus

```powershell
# Port-forward
kubectl port-forward svc/prometheus -n monitoring 9090:9090

# Browser: http://localhost:9090
```

### 5. Test Harbor

```powershell
# Port-forward
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Browser: http://localhost:8080
# Username: admin / Password: Harbor12345
```

### 6. Test SonarQube

```powershell
# Kiểm tra pod
kubectl get pods -n sonarqube

# Port-forward (nếu pod Running)
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000

# Browser: http://localhost:9000
# Username: admin / Password: admin (đổi lần đầu)
```

### 7. Test Jenkins

```powershell
# Kiểm tra pod
kubectl get pods -n jenkins

# Port-forward
kubectl port-forward svc/jenkins -n jenkins 8080:8080

# Lấy admin password
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword

# Browser: http://localhost:8080
# Username: admin / Password: (từ command trên)
```

## Push Images và Test Applications

### Bước 1: Push Images

```powershell
# Terminal 1: Port-forward Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Terminal 2: Chạy script
.\scripts\push-images-to-harbor.ps1
```

### Bước 2: Verify Images trong Harbor

1. Truy cập Harbor UI: http://localhost:8080
2. Vào project "eshelf"
3. Kiểm tra có 5 repositories:
   - api-gateway
   - auth-service
   - book-service
   - user-service
   - ml-service

### Bước 3: Scale Up Deployments

```powershell
kubectl scale deployment -n eshelf-dev --all --replicas=1
```

### Bước 4: Kiểm Tra Pods

```powershell
kubectl get pods -n eshelf-dev
# Kỳ vọng: Tất cả pods đang Running
```

### Bước 5: Test API Gateway

```powershell
# Port-forward
kubectl port-forward svc/dev-api-gateway -n eshelf-dev 3000:3000

# Test
curl http://localhost:3000/health
# Hoặc mở browser: http://localhost:3000/health
```

## Checklist Test Thủ Công

### ArgoCD
- [ ] Port-forward thành công
- [ ] Truy cập https://localhost:8080
- [ ] Đăng nhập được
- [ ] Thấy 6 applications
- [ ] Có thể click vào từng application
- [ ] Sync status hiển thị đúng

### Grafana
- [ ] Port-forward thành công
- [ ] Truy cập http://localhost:3000
- [ ] Đăng nhập được
- [ ] Thấy dashboards
- [ ] Data sources (Prometheus, Loki) hoạt động
- [ ] Có thể query metrics và logs

### Prometheus
- [ ] Port-forward thành công
- [ ] Truy cập http://localhost:9090
- [ ] UI load được
- [ ] Targets đang scrape
- [ ] Có thể query metrics

### Harbor
- [ ] Port-forward thành công
- [ ] Truy cập http://localhost:8080
- [ ] Đăng nhập được
- [ ] Tạo project "eshelf"
- [ ] Push images thành công (sau khi chạy script)
- [ ] Thấy images trong repositories

### SonarQube
- [ ] Pod đang Running
- [ ] Port-forward thành công
- [ ] Truy cập http://localhost:9000
- [ ] Đăng nhập được
- [ ] Tạo project và token

### Jenkins
- [ ] Pod đang Running
- [ ] Port-forward thành công
- [ ] Truy cập http://localhost:8080
- [ ] Đăng nhập được
- [ ] Tạo pipeline job

### eShelf Applications
- [ ] Images đã push lên Harbor
- [ ] Deployments đã scale up
- [ ] Pods đang Running
- [ ] API Gateway accessible
- [ ] Health checks pass

## Lỗi Thường Gặp và Giải Pháp

### Lỗi: "Port already in use"
```powershell
# Tìm process đang dùng port
netstat -ano | findstr :8080
# Kill process
taskkill /PID <PID> /F
```

### Lỗi: "ImagePullBackOff"
- Kiểm tra images đã push lên Harbor chưa
- Kiểm tra imagePullSecrets
- Kiểm tra image reference đúng chưa

### Lỗi: "Connection refused"
- Kiểm tra port-forward đang chạy
- Kiểm tra pod đang Running
- Kiểm tra service tồn tại

### Lỗi: "SSL certificate error"
- Bỏ qua cảnh báo SSL cho ArgoCD (self-signed)

## Tài Liệu Tham Khảo

- `COMPLETE_TESTING_GUIDE.md` - Hướng dẫn test chi tiết
- `HARBOR_IMAGE_SETUP.md` - Hướng dẫn push images
- `TESTING_CHECKLIST.md` - Checklist test
- `MANUAL_TESTING_GUIDE.md` - Hướng dẫn test thủ công

