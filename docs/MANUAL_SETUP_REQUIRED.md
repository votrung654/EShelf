# Manual Setup Required - eShelf Project

## Tổng Hợp Phần Cần Setup Thủ Công

### 1. GitHub Secrets (Critical - Phải Làm)

**Cần Setup:**
- `HARBOR_REGISTRY`: Địa chỉ Harbor có thể truy cập từ GitHub Actions
- `HARBOR_USERNAME`: `admin`
- `HARBOR_PASSWORD`: `Harbor12345`

**Cách Setup:**
1. Vào GitHub repository
2. Settings > Secrets and variables > Actions
3. New repository secret
4. Thêm từng secret:
   - Name: `HARBOR_REGISTRY`
     Value: Địa chỉ Harbor (ví dụ: `harbor.yourdomain.com` hoặc IP public nếu có Ingress)
   - Name: `HARBOR_USERNAME`
     Value: `admin`
   - Name: `HARBOR_PASSWORD`
     Value: `Harbor12345`

**Lưu Ý:**
- GitHub Actions không thể truy cập `harbor-core.harbor.svc.cluster.local` (cluster internal)
- Cần địa chỉ Harbor có thể truy cập từ internet
- Có thể dùng Ingress với domain hoặc LoadBalancer service

**Verify:**
- Push code và check GitHub Actions logs
- Xem có push images lên Harbor không

---

### 2. Fix Harbor Issues

**Vấn Đề:**
- `harbor-core` không kết nối được Redis (DNS lookup timeout)
- `harbor-nginx` CrashLoopBackOff

**Cần Làm:**

```powershell
# 1. Kiểm tra logs
kubectl logs -n harbor harbor-core-6fbdd7f5d8-5pr4j --tail=50
kubectl logs -n harbor harbor-nginx-86458b74c6-56jxz --tail=50

# 2. Kiểm tra Redis service
kubectl get svc -n harbor harbor-redis
kubectl get pods -n harbor | Select-String -Pattern "redis"

# 3. Kiểm tra network policies
kubectl get networkpolicies -n harbor

# 4. Test DNS resolution từ harbor-core pod
kubectl exec -n harbor harbor-core-6fbdd7f5d8-5pr4j -- nslookup harbor-redis

# 5. Restart pods nếu cần
kubectl delete pod -n harbor harbor-core-6fbdd7f5d8-5pr4j
kubectl delete pod -n harbor harbor-nginx-86458b74c6-56jxz

# 6. Kiểm tra lại
kubectl get pods -n harbor
```

**Nếu Vẫn Lỗi:**
- Kiểm tra network policies có block traffic không
- Kiểm tra DNS config
- Có thể cần recreate Harbor deployment

---

### 3. Push Images Lên Harbor

**Cần Làm:**

```powershell
# Terminal 1: Port-forward Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Terminal 2: Chạy script
.\scripts\push-images-to-harbor.ps1
```

**Hoặc Thủ Công:**

```powershell
# 1. Port-forward Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80

# 2. Login to Harbor
docker login localhost:8080 -u admin -p Harbor12345

# 3. Build và push từng service
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

**Verify:**
- Vào Harbor UI: http://localhost:8080
- Login: admin / Harbor12345
- Vào project "eshelf"
- Kiểm tra có 5 repositories

---

### 4. Sửa ArgoCD Image Updater Annotations

**Vấn Đề:**
- Tất cả ArgoCD applications có annotation `harbor.yourdomain.com`
- Cần sửa thành địa chỉ Harbor thật

**Cần Sửa Files:**
- `infrastructure/kubernetes/argocd/applications/api-gateway-app.yaml`
- `infrastructure/kubernetes/argocd/applications/auth-service-app.yaml`
- `infrastructure/kubernetes/argocd/applications/book-service-app.yaml`
- `infrastructure/kubernetes/argocd/applications/user-service-app.yaml`
- `infrastructure/kubernetes/argocd/applications/ml-service-app.yaml`

**Sửa:**
```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: api-gateway=harbor.yourdomain.com/eshelf/api-gateway
```

**Thành:**
```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: api-gateway=harbor-core.harbor.svc.cluster.local/eshelf/api-gateway
```

**Hoặc nếu có Ingress:**
```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: api-gateway=harbor.yourdomain.com/eshelf/api-gateway
```

**Apply:**
```powershell
kubectl apply -f infrastructure/kubernetes/argocd/applications/
```

---

### 5. Test Thủ Công Qua Browser

**Cần Port-Forward:**

```powershell
# Terminal 1 - ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2 - Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000

# Terminal 3 - Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090

# Terminal 4 - Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Terminal 5 - Jenkins (nếu cần)
kubectl port-forward svc/jenkins -n jenkins 8081:8080

# Terminal 6 - SonarQube (nếu cần)
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000
```

**Test Checklist:**
- [ ] ArgoCD UI: https://localhost:8080 (bỏ qua SSL warning)
- [ ] Grafana: http://localhost:3000 (admin/admin123)
- [ ] Prometheus: http://localhost:9090
- [ ] Harbor: http://localhost:8080 (admin/Harbor12345)
- [ ] Jenkins: http://localhost:8081 (nếu pod running)
- [ ] SonarQube: http://localhost:9000 (nếu pod running)

**Xem:** `FINAL_TESTING_CHECKLIST.md` để biết chi tiết

---

### 6. Fix Node NotReady (Nếu Có)

**Kiểm Tra:**
```powershell
kubectl get nodes
kubectl describe node <node-name>
```

**Có Thể Cần:**
- Restart node
- Check network connectivity
- Check kubelet status

---

### 7. Scale Up Applications

**Sau Khi Push Images:**
```powershell
kubectl scale deployment -n eshelf-dev --all --replicas=1
```

**Verify:**
```powershell
kubectl get pods -n eshelf-dev
# Kỳ vọng: Tất cả pods đang Running
```

---

### 8. Verify ArgoCD Sync

**Sau Khi Push Images và Update Manifests:**
```powershell
# Check applications
kubectl get applications -n argocd

# Sync nếu cần
kubectl patch application api-gateway -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

**Hoặc qua UI:**
- Vào ArgoCD UI
- Click vào từng application
- Click "Sync" nếu OutOfSync

---

## Thứ Tự Thực Hiện

1. **Setup GitHub Secrets** (Critical)
2. **Fix Harbor Issues** (Critical)
3. **Push Images** (Critical)
4. **Sửa ArgoCD Annotations** (Important)
5. **Scale Up Applications** (Important)
6. **Test Thủ Công** (Important)
7. **Verify ArgoCD Sync** (Nice to have)

## Thời Gian Ước Tính

- GitHub Secrets: 5 phút
- Fix Harbor: 15-30 phút
- Push Images: 10-20 phút
- Sửa Annotations: 5 phút
- Scale Up: 2 phút
- Test: 30-60 phút

**Tổng: ~1-2 giờ**






