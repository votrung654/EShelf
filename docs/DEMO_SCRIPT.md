# Demo Script - eShelf Project

## Mục Đích Demo

Chứng minh project đáp ứng đầy đủ yêu cầu:
1. Smart Build System (chỉ build service thay đổi)
2. GitOps với ArgoCD (tự động sync)
3. Image auto-update mechanism
4. Multi-environment deployment
5. CI/CD pipeline (PR vs Push)
6. Security scanning
7. Monitoring & Observability

## Chuẩn Bị Trước Demo

### 1. Kiểm Tra Cluster

```powershell
.\scripts\quick-check.ps1 -Detailed
```

**Kỳ vọng:**
- 3 nodes Ready
- Hầu hết pods Running
- Services accessible

### 2. Port-Forward Services

Mở nhiều terminal windows:

**Terminal 1 - ArgoCD:**
```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Terminal 2 - Grafana:**
```powershell
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

**Terminal 3 - Prometheus:**
```powershell
kubectl port-forward svc/prometheus -n monitoring 9090:9090
```

**Terminal 4 - Harbor:**
```powershell
kubectl port-forward svc/harbor-core -n harbor 8080:80
```

**Terminal 5 - Jenkins (nếu cần):**
```powershell
kubectl port-forward svc/jenkins -n jenkins 8081:8080
```

**Terminal 6 - SonarQube (nếu cần):**
```powershell
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000
```

### 3. Chuẩn Bị Code Changes

Tạo branch mới để demo:
```powershell
git checkout -b demo/smart-build
```

## Kịch Bản Demo

### Phần 1: Giới Thiệu Kiến Trúc (5 phút)

**Slide 1: Tổng Quan**
- Giới thiệu eShelf project
- Microservices architecture
- Technology stack

**Slide 2: Infrastructure**
- AWS EC2 với Terraform
- K3s cluster (3 nodes)
- Ansible configuration

**Slide 3: CI/CD Pipeline**
- GitHub Actions workflows
- PR vs Push pipeline
- Smart Build System

**Slide 4: GitOps**
- ArgoCD setup
- Image Updater mechanism
- Multi-environment

**Slide 5: Monitoring**
- Prometheus, Grafana, Loki
- Metrics và logs
- Alerting

### Phần 2: Demo Smart Build System (10 phút)

**Bước 1: Show Code Structure**
```powershell
# Show project structure
tree backend/services -L 2
```

**Bước 2: Tạo Code Change**
```powershell
# Sửa file trong api-gateway
code backend/services/api-gateway/src/index.js
# Thêm comment hoặc log statement
```

**Bước 3: Commit và Push**
```powershell
git add backend/services/api-gateway/
git commit -m "feat: update api-gateway"
git push origin demo/smart-build
```

**Bước 4: Tạo Pull Request**
- Vào GitHub
- Tạo PR từ `demo/smart-build` → `main`
- Show PR pipeline đang chạy

**Bước 5: Verify Smart Build**
- Vào GitHub Actions
- Show chỉ có `api-gateway` job chạy
- Các services khác không chạy
- Giải thích path-based filtering

**Bước 6: Show PR Pipeline Results**
- Lint results
- Test results
- Security scan results
- Không có build/deploy

### Phần 3: Demo CI/CD Pipeline (15 phút)

**Bước 1: Merge PR**
- Merge PR vào main
- Trigger Push pipeline

**Bước 2: Show Push Pipeline**
- Vào GitHub Actions
- Show full pipeline:
  - Lint
  - Test
  - Build (chỉ api-gateway)
  - Security scan
  - Push to Harbor

**Bước 3: Show Harbor**
- Mở Harbor UI: http://localhost:8080
- Login: admin / Harbor12345
- Vào project "eshelf"
- Show image mới được push
- Show image scanning results

**Bước 4: Show Image Update**
- Vào GitHub repository
- Show commit tự động update manifest
- Show kustomization.yaml được update với image tag mới

**Bước 5: Show ArgoCD Sync**
- Mở ArgoCD UI: https://localhost:8080
- Login: admin / (password từ secret)
- Show application "api-gateway"
- Show sync status
- Show image tag mới
- Click "Sync" nếu cần

**Bước 6: Verify Deployment**
```powershell
# Check pods
kubectl get pods -n eshelf-dev

# Check image
kubectl describe pod -n eshelf-dev -l app=api-gateway | Select-String -Pattern "Image:"
```

### Phần 4: Demo GitOps & Image Updater (10 phút)

**Bước 1: Show ArgoCD Applications**
- ArgoCD UI
- List 6 applications
- Show sync status
- Show health status

**Bước 2: Show Image Updater Config**
```powershell
# Show Image Updater config
kubectl get configmap -n argocd argocd-image-updater-config -o yaml
```

**Bước 3: Show Application Annotations**
```powershell
# Show annotations
kubectl get application api-gateway -n argocd -o yaml | Select-String -Pattern "argocd-image-updater"
```

**Bước 4: Demo Manual Image Update**
- Push image mới với tag khác
- ArgoCD Image Updater detect
- Update manifest
- ArgoCD sync
- Pods rolling update

**Bước 5: Show Multi-Environment**
```powershell
# Show overlays
ls infrastructure/kubernetes/overlays/
cat infrastructure/kubernetes/overlays/dev/kustomization.yaml
cat infrastructure/kubernetes/overlays/prod/kustomization.yaml
```

### Phần 5: Demo Monitoring (10 phút)

**Bước 1: Show Prometheus**
- Mở Prometheus: http://localhost:9090
- Query: `up`
- Query: `kube_pod_info`
- Query: `container_memory_usage_bytes`
- Show targets đang scrape

**Bước 2: Show Grafana**
- Mở Grafana: http://localhost:3000
- Login: admin / admin123
- Show dashboards
- Show data sources (Prometheus, Loki)
- Query metrics
- Query logs

**Bước 3: Show Logs**
- Grafana Explore
- Datasource: Loki
- Query: `{namespace="eshelf-dev"}`
- Show logs từ pods

**Bước 4: Show Alerts**
- Prometheus Alerts
- Show alert rules
- Show Alertmanager config

### Phần 6: Demo Security & Quality (5 phút)

**Bước 1: Show Security Scan Results**
- GitHub Actions
- Show Trivy scan results
- Show CodeQL results

**Bước 2: Show SonarQube**
- Mở SonarQube: http://localhost:9000
- Login: admin / admin
- Show projects
- Show quality gates
- Show code coverage

**Bước 3: Show Harbor Image Scanning**
- Harbor UI
- Vào image
- Show vulnerability scan results
- Show CVEs

### Phần 7: Demo Rollback (5 phút)

**Bước 1: Show Rollback Workflow**
```powershell
# Check deployment history
kubectl rollout history deployment dev-api-gateway -n eshelf-dev

# Rollback
kubectl rollout undo deployment dev-api-gateway -n eshelf-dev

# Verify
kubectl get pods -n eshelf-dev -l app=api-gateway
```

**Bước 2: Show ArgoCD Rollback**
- ArgoCD UI
- Vào application
- Show history
- Click "Rollback"
- Show sync

### Phần 8: Kết Luận (5 phút)

**Tổng Kết:**
- Smart Build: Chỉ build service thay đổi
- GitOps: Tự động sync từ Git
- Image Updater: Tự động update image tags
- Multi-Environment: Dev, Staging, Prod
- Security: Scanning và policies
- Monitoring: Metrics, logs, alerts

**Hướng Phát Triển:**
- Canary deployment
- Blue-Green deployment
- Advanced monitoring
- Cost optimization
- Performance tuning

## Checklist Demo

### Trước Demo
- [ ] Cluster đang chạy ổn định
- [ ] Tất cả services port-forward
- [ ] Code changes sẵn sàng
- [ ] GitHub repository accessible
- [ ] Browser tabs mở sẵn (ArgoCD, Grafana, Prometheus, Harbor)

### Trong Demo
- [ ] Show Smart Build hoạt động
- [ ] Show PR pipeline (không deploy)
- [ ] Show Push pipeline (build và deploy)
- [ ] Show Harbor images
- [ ] Show ArgoCD sync
- [ ] Show Image Updater
- [ ] Show Monitoring dashboards
- [ ] Show Security scans
- [ ] Show Rollback

### Sau Demo
- [ ] Q&A
- [ ] Show code và configs
- [ ] Explain architecture decisions

## Lưu Ý

1. **Timing**: Tổng thời gian demo: ~60 phút
2. **Backup**: Có video backup nếu demo trực tiếp lỗi
3. **Practice**: Practice trước ít nhất 2 lần
4. **Scripts**: Chuẩn bị scripts sẵn để chạy nhanh
5. **Screenshots**: Chụp screenshots các bước quan trọng

## Troubleshooting

### Nếu Cluster Lỗi
- Có backup cluster
- Hoặc dùng video demo

### Nếu Pipeline Lỗi
- Show logs
- Explain error
- Show cách fix

### Nếu Services Không Accessible
- Check port-forward
- Check pods status
- Restart nếu cần






