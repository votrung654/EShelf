# Hướng Dẫn Test Thủ Công eShelf Infrastructure

## Tổng Quan

Tài liệu này hướng dẫn test thủ công các components quan trọng của infrastructure, đặc biệt là những phần không thể test tự động hoàn toàn.

## Lưu Ý Trước Khi Test

- **Images chưa có:** Các eShelf applications (api-gateway, user-service, etc.) đang được scale down vì images chưa được push lên Harbor. Xem `HARBOR_IMAGE_SETUP.md` để biết cách push images.
- **SonarQube và Jenkins:** Đang pending do thiếu resources. Có thể tạm thời bỏ qua hoặc tăng instance size.

## 1. Kiểm Tra Cluster và Nodes

### 1.1. Verify Cluster Status

```powershell
# Kiểm tra tất cả nodes
kubectl get nodes -o wide

# Kỳ vọng: 3 nodes (1 master, 2 workers) đều Ready
```

**Kiểm tra bằng browser:** Không cần

### 1.2. Verify Pod Distribution

```powershell
# Xem pods trên từng node
kubectl get pods -A -o wide

# Kiểm tra pods có được schedule đều trên các nodes không
kubectl get pods -A -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase
```

**Kiểm tra bằng browser:** Không cần

## 2. ArgoCD UI

### 2.1. Port Forward và Truy Cập

```powershell
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Kiểm tra bằng browser:**
1. Mở browser, truy cập: `https://localhost:8080`
2. Bỏ qua cảnh báo SSL (self-signed certificate)
3. Đăng nhập:
   - Username: `admin`
   - Password: Lấy bằng command:
     ```powershell
     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
     ```

### 2.2. Kiểm Tra ArgoCD Applications

**Trong ArgoCD UI:**
1. Click vào "Applications" ở sidebar
2. Kiểm tra xem có applications nào được tạo chưa
3. Nếu có, click vào từng application để xem:
   - Sync status
   - Health status
   - Resources

**Lưu ý:** Nếu chưa có applications, cần apply:
```powershell
kubectl apply -f infrastructure/kubernetes/argocd/applications/
```

## 3. Grafana Dashboard

### 3.1. Port Forward và Truy Cập

```powershell
# Port forward Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

**Kiểm tra bằng browser:**
1. Truy cập: `http://localhost:3000`
2. Đăng nhập:
   - Username: `admin`
   - Password: `admin123`
3. Kiểm tra:
   - Dashboards có sẵn
   - Data sources (Prometheus, Loki) đã được cấu hình
   - Có thể query metrics từ Prometheus

### 3.2. Kiểm Tra Dashboards

**Trong Grafana:**
1. Vào "Dashboards" > "Browse"
2. Tìm dashboard "eShelf" (nếu có)
3. Kiểm tra metrics hiển thị:
   - CPU usage
   - Memory usage
   - Pod status

## 4. Prometheus

### 4.1. Port Forward và Truy Cập

```powershell
# Port forward Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090
```

**Kiểm tra bằng browser:**
1. Truy cập: `http://localhost:9090`
2. Kiểm tra:
   - Status > Targets: Xem các targets đang scrape
   - Graph: Thử query một số metrics như `up`, `kube_pod_info`
   - Alerts: Xem các alerts đã được cấu hình

## 5. Harbor Registry

### 5.1. Port Forward và Truy Cập

```powershell
# Port forward Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80
```

**Kiểm tra bằng browser:**
1. Truy cập: `http://localhost:8080`
2. Đăng nhập:
   - Username: `admin`
   - Password: `Harbor12345`
3. Kiểm tra:
   - Projects: Xem có project nào chưa
   - Repositories: Xem có images nào đã push chưa
   - System Settings: Kiểm tra cấu hình

### 5.2. Test Docker Login (Tùy chọn)

```powershell
# Nếu có Docker local, test login
docker login localhost:8080 -u admin -p Harbor12345

# Lưu ý: Cần cấu hình insecure registry nếu dùng localhost
```

## 6. Loki Logs (Qua Grafana)

### 6.1. Kiểm Tra Logs

**Trong Grafana:**
1. Vào "Explore"
2. Chọn datasource "Loki"
3. Thử query: `{namespace="monitoring"}`
4. Kiểm tra logs có được collect không

**Hoặc qua CLI:**
```powershell
# Port forward Loki
kubectl port-forward svc/loki -n monitoring 3100:3100

# Query logs (cần curl hoặc Postman)
curl http://localhost:3100/loki/api/v1/query?query={namespace="monitoring"}
```

## 7. Kiểm Tra Services Health

### 7.1. Health Checks

```powershell
# Kiểm tra tất cả pods đang Running
kubectl get pods -A | Select-String -Pattern "Running|Pending|Error"

# Kiểm tra services
kubectl get svc -A

# Kiểm tra endpoints
kubectl get endpoints -A
```

### 7.2. Test Connectivity

```powershell
# Test từ một pod đến service khác
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# Trong pod debug:
# wget -O- http://prometheus.monitoring.svc.cluster.local:9090/-/healthy
# wget -O- http://grafana.monitoring.svc.cluster.local:3000/api/health
```

## 8. Kiểm Tra Resource Usage

### 8.1. Node Resources

```powershell
# Xem resource usage của nodes
kubectl top nodes

# Xem resource usage của pods
kubectl top pods -A
```

### 8.2. Kiểm Tra trong Grafana

**Trong Grafana Dashboard:**
- Xem CPU và Memory usage của từng node
- Xem pod resource requests/limits
- Kiểm tra có node nào bị overload không

## 9. Test ArgoCD Sync (Nếu có Applications)

### 9.1. Manual Sync Test

**Trong ArgoCD UI:**
1. Chọn một application
2. Click "Sync"
3. Kiểm tra sync status
4. Xem logs nếu có lỗi

### 9.2. Test Git Changes

```powershell
# Nếu có thay đổi trong Git repo chứa manifests
# ArgoCD sẽ tự động detect và sync (nếu auto-sync enabled)
# Hoặc manual sync qua UI
```

## 10. Kiểm Tra Network Policies

```powershell
# Xem network policies
kubectl get networkpolicies -A

# Kiểm tra connectivity giữa namespaces
```

## Checklist Test

- [ ] Cluster có 3 nodes (1 master, 2 workers) đều Ready
- [ ] ArgoCD UI accessible và có thể đăng nhập
- [ ] Grafana UI accessible, có dashboards và datasources
- [ ] Prometheus UI accessible, có targets và metrics
- [ ] Harbor UI accessible và có thể đăng nhập
- [ ] Loki logs có thể query qua Grafana
- [ ] Tất cả pods trong namespaces chính đang Running
- [ ] Services có endpoints đúng
- [ ] Resource usage hợp lý (không quá tải)
- [ ] Network connectivity giữa services hoạt động

## Lưu Ý

1. **Port Forward:** Mỗi lần chỉ có thể port-forward một service. Cần mở terminal riêng cho mỗi service hoặc dùng background process.

2. **SSL Warnings:** ArgoCD dùng self-signed certificate, browser sẽ cảnh báo. Có thể bỏ qua cho testing.

3. **Firewall:** Đảm bảo ports không bị block bởi firewall.

4. **Resource Limits:** Nếu cluster thiếu resources, một số pods có thể pending. Kiểm tra với `kubectl describe pod`.

5. **Timeouts:** Một số services cần thời gian để khởi động hoàn toàn. Đợi vài phút sau khi deploy.

