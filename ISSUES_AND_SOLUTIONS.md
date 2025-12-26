# Issues và Solutions - eShelf Infrastructure

## Issues Hiện Tại

### 1. Harbor Pods Issues

**Status:**
- `harbor-core-6fbdd7f5d8-5pr4j`: Running nhưng có lỗi kết nối Redis (DNS lookup timeout)
- `harbor-nginx-86458b74c6-56jxz`: CrashLoopBackOff

**Nguyên nhân:**
- Harbor-core không thể kết nối đến `harbor-redis` (DNS lookup timeout)
- Có thể do network policy hoặc DNS issue

**Logs:**
```
failed to ping redis://harbor-redis:6379/0?idle_timeout_seconds=30
dial tcp: lookup harbor-redis: i/o timeout
```

**Giải pháp:**
```powershell
# Kiểm tra logs
kubectl logs -n harbor harbor-core-6fbdd7f5d8-5pr4j --tail=50
kubectl logs -n harbor harbor-nginx-86458b74c6-56jxz --tail=50

# Kiểm tra events
kubectl describe pod -n harbor harbor-core-6fbdd7f5d8-5pr4j

# Nếu cần, restart pods
kubectl delete pod -n harbor harbor-core-6fbdd7f5d8-5pr4j
kubectl delete pod -n harbor harbor-nginx-86458b74c6-56jxz
```

### 2. eShelf Applications ImagePullBackOff

**Status:**
- `dev-api-gateway`: ImagePullBackOff
- `dev-auth-service`: ImagePullBackOff
- `dev-user-service`: ImagePullBackOff

**Nguyên nhân:**
- Images chưa được push lên Harbor
- Đây là expected behavior cho đến khi push images

**Giải pháp:**
```powershell
# Push images lên Harbor
.\scripts\push-images-to-harbor.ps1

# Sau đó pods sẽ tự động pull images
```

### 3. SonarQube ContainerCreating

**Status:**
- `sonarqube-856456f86f-zmfvr`: ContainerCreating
- `sonarqube-947b74d84-mgmrc`: ContainerCreating

**Nguyên nhân có thể:**
- Đang pull image (có thể mất thời gian)
- Hoặc thiếu resources

**Giải pháp:**
```powershell
# Kiểm tra events
kubectl describe pod -n sonarqube -l app=sonarqube

# Kiểm tra logs (nếu có)
kubectl logs -n sonarqube -l app=sonarqube

# Đợi thêm vài phút để image pull hoàn tất
```

### 4. Metrics API Not Available

**Status:**
- `kubectl top nodes` báo lỗi "Metrics API not available"

**Nguyên nhân:**
- metrics-server có thể đang restart sau khi patch resources
- Hoặc pod chưa ready

**Giải pháp:**
```powershell
# Kiểm tra metrics-server pod
kubectl get pods -n kube-system | Select-String -Pattern "metrics-server"

# Kiểm tra logs
kubectl logs -n kube-system -l k8s-app=metrics-server

# Đợi vài phút để metrics-server ready
```

## Solutions Đã Áp Dụng

### 1. Resource Optimization (Overcommit Strategy)

**Đã sửa:**
- Jenkins: `requests.memory: 10Mi` (từ 2Gi)
- SonarQube: `requests.memory: 10Mi` (từ 2Gi)
- CoreDNS: `requests.memory: 50Mi` (từ 70Mi)
- metrics-server: `requests.memory: 50Mi` (từ 70Mi)

**Kết quả:**
- Jenkins pod đã Running
- SonarQube pods đang ContainerCreating (đang pull image)

### 2. Image References và Secrets

**Đã sửa:**
- Image references: `harbor-core.harbor.svc.cluster.local/eshelf/*`
- ImagePullSecrets: `harbor-registry-secret` đã tạo
- Tất cả deployments đã có imagePullSecrets

**Kết quả:**
- Sẵn sàng pull images từ Harbor (sau khi push)

## Checklist Kiểm Tra

### Infrastructure
- [x] Cluster 3 nodes Ready
- [x] System pods optimized
- [x] Jenkins Running
- [ ] SonarQube Running (đang start)
- [ ] Harbor pods stable (có vấn đề)

### Applications
- [ ] Images pushed to Harbor
- [ ] eShelf apps scaled up
- [ ] All pods Running

### Monitoring
- [x] Prometheus Running
- [x] Grafana Running
- [x] Loki Running
- [ ] Metrics API available (đang restart)

## Next Steps

1. **Kiểm tra Harbor pods:**
   ```powershell
   kubectl logs -n harbor harbor-core-6fbdd7f5d8-5pr4j
   kubectl describe pod -n harbor harbor-core-6fbdd7f5d8-5pr4j
   ```

2. **Đợi SonarQube start:**
   ```powershell
   kubectl get pods -n sonarqube -w
   ```

3. **Đợi metrics-server ready:**
   ```powershell
   kubectl get pods -n kube-system -w | Select-String -Pattern "metrics-server"
   ```

4. **Push images:**
   ```powershell
   .\scripts\push-images-to-harbor.ps1
   ```

5. **Scale up applications:**
   ```powershell
   kubectl scale deployment -n eshelf-dev --all --replicas=1
   ```

## Lưu Ý

- Harbor pods có thể cần restart hoặc kiểm tra cấu hình
- SonarQube đang pull image, cần đợi thêm
- Metrics API sẽ available sau khi metrics-server ready
- eShelf apps sẽ chạy sau khi push images

