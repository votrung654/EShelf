# Kịch Bản Quay Video Demo - eShelf Project

## Tổng Quan

**Thời lượng:** ~45-60 phút  
**Mục đích:** Demo đầy đủ các tính năng DevOps của project  
**Format:** Screen recording với voice-over hoặc live demo

---

## CHUẨN BỊ TRƯỚC KHI QUAY

### 1. Setup Môi Trường

**Terminal Windows (mở sẵn):**
- Terminal 1: VS Code với project mở
- Terminal 2: PowerShell - kubectl commands
- Terminal 3: PowerShell - port-forward ArgoCD
- Terminal 4: PowerShell - port-forward Grafana
- Terminal 5: PowerShell - port-forward Prometheus
- Terminal 6: PowerShell - port-forward Harbor

**Browser Tabs (mở sẵn):**
- Tab 1: GitHub Repository
- Tab 2: GitHub Actions
- Tab 3: ArgoCD UI (https://localhost:8080)
- Tab 4: Grafana (http://localhost:3000)
- Tab 5: Prometheus (http://localhost:9090)
- Tab 6: Harbor (http://localhost:8080)

**Commands sẵn sàng:**
```powershell
# Terminal 3 - ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 4 - Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000

# Terminal 5 - Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090

# Terminal 6 - Harbor
kubectl port-forward svc/harbor-core -n harbor 8080:80
```

### 2. Kiểm Tra Cluster

```powershell
# Terminal 2
.\scripts\quick-check.ps1 -Detailed
kubectl get nodes
kubectl get pods -A
```

### 3. Chuẩn Bị Code Changes

```powershell
# Tạo branch demo
git checkout -b demo/video-recording
```

---

## PHẦN 1: GIỚI THIỆU (5 phút)

> **Lưu ý:** Chi tiết về các công cụ, cấu hình và quy trình tích hợp được mô tả đầy đủ trong [TOOLS_AND_CONFIGURATION.md](TOOLS_AND_CONFIGURATION.md)

### [00:00 - 00:30] Intro Slide

**Lời nói:**
> "Xin chào, tôi là [Tên]. Hôm nay tôi sẽ demo project eShelf - một nền tảng đọc sách điện tử được xây dựng theo kiến trúc microservices với các công nghệ DevOps hiện đại."

**Show trên màn hình:**
- Slide title: "eShelf - Microservices Platform với CI/CD và GitOps"
- Team members
- Mục tiêu project

### [00:30 - 02:00] Kiến Trúc Tổng Quan

**Lời nói:**
> "Project sử dụng kiến trúc microservices với 5 services chính: API Gateway, Auth Service, User Service, Book Service, và ML Service. Tất cả được deploy trên K3s cluster trên AWS EC2."

**Show trên màn hình:**
- Architecture diagram từ presentation
- Zoom vào các components
- Giải thích flow

**Actions:**
- Click vào diagram
- Highlight các services
- Show database per service pattern

### [02:00 - 03:00] Technology Stack

**Lời nói:**
> "Tech stack bao gồm Terraform cho Infrastructure as Code, Ansible cho configuration management, GitHub Actions cho CI/CD, Harbor cho container registry, ArgoCD cho GitOps, và Prometheus/Grafana cho monitoring."

**Show trên màn hình:**
- List technologies
- Icons/logos nếu có
- Highlight key technologies

### [03:00 - 05:00] Project Structure

**Lời nói:**
> "Hãy xem cấu trúc project. Đây là monorepo với backend services, infrastructure code, và CI/CD workflows."

**Show trên màn hình:**
```powershell
# Terminal 1 - VS Code
tree -L 2
# Hoặc show trong VS Code Explorer
```

**Highlight:**
- `backend/services/` - 5 microservices
- `infrastructure/` - Terraform, Ansible, Kubernetes
- `.github/workflows/` - CI/CD pipelines
- `infrastructure/kubernetes/` - K8s manifests

---

## PHẦN 2: DEMO SMART BUILD SYSTEM (8 phút)

### [05:00 - 06:00] Giải Thích Smart Build

**Lời nói:**
> "Smart Build System là một tính năng quan trọng. Thay vì build tất cả services mỗi khi có thay đổi, hệ thống chỉ build services có file thay đổi. Điều này tiết kiệm thời gian và tài nguyên."

**Show trên màn hình:**
- Smart Build workflow diagram
- Code trong `.github/workflows/smart-build.yml`

**Actions:**
- Open file `smart-build.yml`
- Explain path-based filtering
- Show matrix strategy

### [06:00 - 07:00] Show Code Structure

**Lời nói:**
> "Hãy xem cấu trúc services. Mỗi service có thư mục riêng trong backend/services/."

**Show trên màn hình:**
```powershell
# Terminal 1 - VS Code
# Navigate to backend/services/
# Show structure
```

**Actions:**
- Expand `backend/services/` folder
- Show 5 services: api-gateway, auth-service, book-service, user-service, ml-service
- Click vào từng service để show structure

### [07:00 - 08:00] Tạo Code Change

**Lời nói:**
> "Bây giờ tôi sẽ sửa code trong api-gateway để demo Smart Build. Tôi sẽ thêm một comment hoặc log statement."

**Show trên màn hình:**
```javascript
// File: backend/services/api-gateway/src/app.js
// Thêm comment hoặc console.log
console.log('API Gateway started - Demo Smart Build');
```

**Actions:**
- Open file `backend/services/api-gateway/src/app.js`
- Add a line of code
- Save file
- Show git status

### [08:00 - 09:00] Commit và Push

**Lời nói:**
> "Tôi sẽ commit và push code change này lên GitHub."

**Show trên màn hình:**
```powershell
# Terminal 1
git status
git add backend/services/api-gateway/
git commit -m "feat: demo smart build - update api-gateway"
git push origin demo/video-recording
```

**Actions:**
- Show git status output
- Show commit message
- Show push output

### [09:00 - 10:00] Tạo Pull Request

**Lời nói:**
> "Bây giờ tôi sẽ tạo Pull Request để trigger PR pipeline."

**Show trên màn hình:**
- Browser Tab: GitHub Repository
- Click "New Pull Request"
- Select branches: `demo/video-recording` → `main`
- Fill PR title: "Demo: Smart Build System"
- Create PR

**Actions:**
- Show PR creation form
- Create PR
- Show PR page

### [10:00 - 12:00] Show PR Pipeline

**Lời nói:**
> "Khi PR được tạo, GitHub Actions sẽ chạy PR pipeline. Pipeline này chỉ chạy validation: lint, test, và security scan, không build hay deploy."

**Show trên màn hình:**
- Browser Tab: GitHub Actions
- Click vào PR workflow run
- Show jobs:
  - Frontend CI (nếu có changes)
  - Backend CI (matrix: api-gateway, auth-service, book-service, user-service)
  - Security Scan

**Actions:**
- Click vào từng job
- Show logs
- Highlight: Chỉ có api-gateway job chạy (vì chỉ sửa api-gateway)
- Show các services khác bị skip

**Lời nói:**
> "Như các bạn thấy, chỉ có api-gateway job chạy. Các services khác như auth-service, book-service, user-service đều bị skip vì không có thay đổi. Đây chính là Smart Build System."

### [12:00 - 13:00] Show PR Pipeline Results

**Lời nói:**
> "Hãy xem kết quả của PR pipeline. Tất cả checks đều pass: lint, test, và security scan."

**Show trên màn hình:**
- GitHub Actions logs
- Show lint results (green checkmarks)
- Show test results
- Show security scan results (Trivy, CodeQL)

**Actions:**
- Expand logs
- Show successful checks
- Explain: PR pipeline không build/deploy

---

## PHẦN 3: DEMO CI/CD PIPELINE (12 phút)

### [13:00 - 14:00] Merge PR

**Lời nói:**
> "Bây giờ tôi sẽ merge PR vào main branch. Điều này sẽ trigger Push pipeline, pipeline này sẽ build và deploy."

**Show trên màn hình:**
- Browser Tab: GitHub PR page
- Click "Merge pull request"
- Confirm merge
- Show merged status

### [14:00 - 16:00] Show Push Pipeline

**Lời nói:**
> "Push pipeline đã được trigger. Pipeline này sẽ build Docker image, scan security, và push lên Harbor registry."

**Show trên màn hình:**
- Browser Tab: GitHub Actions
- Click vào Push workflow run
- Show jobs:
  - Changes detection
  - Build Docker image (chỉ api-gateway)
  - Security scan (Trivy)
  - Push to Harbor

**Actions:**
- Click vào "Build Docker image" job
- Show build logs
- Highlight: Chỉ build api-gateway
- Show image tag (commit SHA)
- Show push to Harbor logs

**Lời nói:**
> "Pipeline đang build Docker image cho api-gateway. Image sẽ được tag với commit SHA và push lên Harbor registry."

### [16:00 - 18:00] Show Harbor UI

**Lời nói:**
> "Hãy kiểm tra Harbor registry. Image mới đã được push lên."

**Show trên màn hình:**
- Browser Tab: Harbor (http://localhost:8080)
- Login: admin / Harbor12345
- Navigate to project "eshelf"
- Show repositories
- Click vào "api-gateway" repository
- Show image tags
- Highlight image mới (commit SHA)

**Actions:**
- Show Harbor UI
- Show project "eshelf"
- Show repositories list
- Click vào api-gateway
- Show image tags
- Click vào image mới
- Show image details
- Show vulnerability scan results (nếu có)

**Lời nói:**
> "Đây là image mới của api-gateway. Harbor đã tự động scan image để tìm vulnerabilities. Kết quả scan hiển thị ở đây."

### [18:00 - 19:00] Show Image Update Mechanism

**Lời nói:**
> "Sau khi image được push lên Harbor, ArgoCD Image Updater sẽ detect image mới và tự động update manifest trong Git repository."

**Show trên màn hình:**
- Browser Tab: GitHub Repository
- Navigate to `infrastructure/kubernetes/overlays/dev/kustomization.yaml`
- Show file content
- Highlight image tag đã được update

**Actions:**
- Open kustomization.yaml
- Show image tag
- Explain: Image tag được update tự động bởi Image Updater

**Lời nói:**
> "Như các bạn thấy, image tag trong kustomization.yaml đã được update với commit SHA mới. Đây là commit tự động được tạo bởi ArgoCD Image Updater."

### [19:00 - 21:00] Show ArgoCD Sync

**Lời nói:**
> "Bây giờ hãy kiểm tra ArgoCD. ArgoCD sẽ detect thay đổi trong Git và sync về cluster."

**Show trên màn hình:**
- Browser Tab: ArgoCD UI (https://localhost:8080)
- Login: admin / (password từ secret)
- Show applications list
- Click vào "api-gateway" application
- Show sync status
- Show image tag mới

**Actions:**
- Show ArgoCD login
- Show applications (6 apps)
- Click vào api-gateway
- Show sync status (OutOfSync hoặc Synced)
- Show image tag
- Click "Sync" nếu cần
- Show sync process

**Lời nói:**
> "ArgoCD đã detect image tag mới. Application đang ở trạng thái OutOfSync. Tôi sẽ click Sync để deploy version mới."

### [21:00 - 22:00] Verify Deployment

**Lời nói:**
> "Hãy verify deployment bằng cách check pods trong cluster."

**Show trên màn hình:**
```powershell
# Terminal 2
kubectl get pods -n eshelf-dev
kubectl describe pod -n eshelf-dev -l app=api-gateway | Select-String -Pattern "Image:"
kubectl get pods -n eshelf-dev -l app=api-gateway -o jsonpath='{.items[0].spec.containers[0].image}'
```

**Actions:**
- Run commands
- Show output
- Highlight image tag mới
- Show pod status (Running)

**Lời nói:**
> "Pod đã được update với image mới. Pod đang ở trạng thái Running, có nghĩa là deployment thành công."

### [22:00 - 25:00] Show Rolling Update

**Lời nói:**
> "Kubernetes đang thực hiện rolling update. Pod cũ sẽ được terminate và pod mới với image mới sẽ được tạo."

**Show trên màn hình:**
```powershell
# Terminal 2
kubectl get pods -n eshelf-dev -l app=api-gateway -w
# Hoặc
kubectl rollout status deployment/dev-api-gateway -n eshelf-dev
```

**Actions:**
- Run watch command
- Show pods transitioning
- Explain rolling update process

---

## PHẦN 4: DEMO GITOPS & IMAGE UPDATER (8 phút)

### [25:00 - 26:00] Show ArgoCD Applications

**Lời nói:**
> "Hãy xem tất cả ArgoCD applications. Chúng ta có 6 applications: 5 microservices và 1 monitoring stack."

**Show trên màn hình:**
- Browser Tab: ArgoCD UI
- Show applications list
- Show sync status của từng app
- Show health status

**Actions:**
- Scroll through applications
- Click vào từng application
- Show details
- Highlight sync policy (Auto-sync)

**Lời nói:**
> "Tất cả applications đều có auto-sync policy, có nghĩa là ArgoCD sẽ tự động sync khi có thay đổi trong Git."

### [26:00 - 27:00] Show Image Updater Config

**Lời nói:**
> "Hãy xem cấu hình của ArgoCD Image Updater."

**Show trên màn hình:**
```powershell
# Terminal 2
kubectl get configmap -n argocd argocd-image-updater-config -o yaml
```

**Actions:**
- Run command
- Show config
- Explain: Image Updater monitor Harbor registry
- Explain: Write-back method: Git

### [27:00 - 28:00] Show Application Annotations

**Lời nói:**
> "Mỗi ArgoCD application có annotations để Image Updater biết monitor image nào."

**Show trên màn hình:**
```powershell
# Terminal 2
kubectl get application api-gateway -n argocd -o yaml | Select-String -Pattern "argocd-image-updater"
```

**Actions:**
- Run command
- Show annotations
- Explain: Image list annotation
- Explain: Update strategy

### [28:00 - 30:00] Show Multi-Environment

**Lời nói:**
> "Project hỗ trợ multi-environment: Dev, Staging, và Prod. Mỗi environment có Kustomize overlay riêng."

**Show trên màn hình:**
```powershell
# Terminal 1 - VS Code
# Navigate to infrastructure/kubernetes/overlays/
ls infrastructure/kubernetes/overlays/
```

**Actions:**
- Show overlays folder
- Open `dev/kustomization.yaml`
- Open `staging/kustomization.yaml`
- Open `prod/kustomization.yaml`
- Compare image tags
- Explain: Different image tags for different environments

**Lời nói:**
> "Mỗi environment có image tag riêng. Dev environment dùng tag 'dev', staging dùng 'staging', và prod dùng version tags."

### [30:00 - 33:00] Demo Manual Image Update (Optional)

**Lời nói:**
> "Nếu cần, chúng ta có thể manually trigger image update bằng cách push image mới với tag khác."

**Show trên màn hình:**
- Explain process
- Show how Image Updater detect
- Show manifest update
- Show ArgoCD sync

---

## PHẦN 5: DEMO MONITORING (10 phút)

### [33:00 - 35:00] Show Prometheus

**Lời nói:**
> "Bây giờ hãy xem monitoring stack. Prometheus đang collect metrics từ tất cả pods trong cluster."

**Show trên màn hình:**
- Browser Tab: Prometheus (http://localhost:9090)
- Navigate to "Status" → "Targets"
- Show targets đang scrape
- Show "up" status

**Actions:**
- Show Prometheus UI
- Click "Status" → "Targets"
- Show list of targets
- Highlight targets đang "up"
- Explain: Prometheus scrape metrics từ pods

**Lời nói:**
> "Prometheus đang scrape metrics từ các targets này. Tất cả đều ở trạng thái 'up', có nghĩa là Prometheus có thể collect metrics thành công."

### [35:00 - 37:00] Query Prometheus Metrics

**Lời nói:**
> "Hãy query một số metrics. Tôi sẽ query 'up' metric để xem services nào đang chạy."

**Show trên màn hình:**
- Browser Tab: Prometheus
- Navigate to "Graph"
- Query: `up`
- Show results
- Query: `kube_pod_info`
- Query: `container_memory_usage_bytes{namespace="eshelf-dev"}`

**Actions:**
- Type query
- Execute query
- Show graph
- Explain metrics
- Try different queries

**Lời nói:**
> "Đây là metrics về pods trong eshelf-dev namespace. Chúng ta có thể thấy memory usage, CPU usage, và nhiều metrics khác."

### [37:00 - 40:00] Show Grafana Dashboards

**Lời nói:**
> "Grafana cung cấp visualization cho metrics. Hãy xem dashboards."

**Show trên màn hình:**
- Browser Tab: Grafana (http://localhost:3000)
- Login: admin / admin123
- Navigate to "Dashboards" → "Browse"
- Show available dashboards
- Click vào một dashboard
- Show graphs

**Actions:**
- Show Grafana login
- Show dashboards list
- Open a dashboard
- Show graphs
- Explain: Metrics visualization
- Show different panels

**Lời nói:**
> "Đây là dashboard hiển thị metrics từ Prometheus. Chúng ta có thể thấy CPU usage, memory usage, request rate, và nhiều metrics khác."

### [40:00 - 42:00] Show Grafana Data Sources

**Lời nói:**
> "Grafana có 2 data sources: Prometheus cho metrics và Loki cho logs."

**Show trên màn hình:**
- Browser Tab: Grafana
- Navigate to "Configuration" → "Data Sources"
- Show Prometheus data source
- Show Loki data source
- Test connections

**Actions:**
- Show data sources
- Click vào Prometheus
- Show configuration
- Click "Test" → Show "Data source is working"
- Click vào Loki
- Show configuration
- Click "Test" → Show "Data source is working"

### [42:00 - 44:00] Show Logs với Loki

**Lời nói:**
> "Bây giờ hãy xem logs. Loki đang collect logs từ tất cả pods."

**Show trên màn hình:**
- Browser Tab: Grafana
- Navigate to "Explore"
- Select data source: Loki
- Query: `{namespace="eshelf-dev"}`
- Show logs
- Query: `{namespace="eshelf-dev", app="api-gateway"}`

**Actions:**
- Show Explore page
- Select Loki
- Type query
- Execute query
- Show logs
- Filter by service
- Show log details

**Lời nói:**
> "Đây là logs từ eshelf-dev namespace. Chúng ta có thể filter logs theo namespace, service, hoặc bất kỳ label nào."

### [44:00 - 45:00] Show Alertmanager (Optional)

**Lời nói:**
> "Alertmanager quản lý alerts. Khi có alert được trigger, Alertmanager sẽ gửi notification."

**Show trên màn hình:**
- Explain Alertmanager
- Show alert rules (nếu có)
- Show notification channels

---

## PHẦN 6: DEMO SECURITY & QUALITY (5 phút)

### [45:00 - 47:00] Show Security Scan Results

**Lời nói:**
> "Hãy xem kết quả security scanning từ GitHub Actions."

**Show trên màn hình:**
- Browser Tab: GitHub Actions
- Navigate to latest workflow run
- Click vào "Security Scan" job
- Show Trivy scan results
- Show CodeQL results

**Actions:**
- Show workflow run
- Click vào security scan job
- Show logs
- Highlight vulnerabilities (nếu có)
- Show CodeQL results
- Explain: Security scanning tự động

**Lời nói:**
> "Trivy scan Docker images để tìm vulnerabilities. CodeQL scan source code để tìm security issues. Tất cả đều tự động trong CI/CD pipeline."

### [47:00 - 49:00] Show Harbor Image Scanning

**Lời nói:**
> "Harbor cũng tự động scan images khi được push lên."

**Show trên màn hình:**
- Browser Tab: Harbor
- Navigate to api-gateway image
- Click vào "Vulnerabilities" tab
- Show scan results
- Show CVEs

**Actions:**
- Show image page
- Click "Vulnerabilities"
- Show scan results
- Show CVEs list
- Explain: Image scanning tự động

### [49:00 - 50:00] Show SonarQube (Optional)

**Lời nói:**
> "SonarQube cung cấp code quality analysis."

**Show trên màn hình:**
- Browser Tab: SonarQube (http://localhost:9000) - nếu có
- Show projects
- Show quality gates
- Show code coverage

---

## PHẦN 7: DEMO ROLLBACK (5 phút)

### [50:00 - 52:00] Show Rollback với kubectl

**Lời nói:**
> "Bây giờ tôi sẽ demo rollback. Có 2 cách: manual rollback với kubectl hoặc rollback qua ArgoCD UI."

**Show trên màn hình:**
```powershell
# Terminal 2
kubectl rollout history deployment/dev-api-gateway -n eshelf-dev
kubectl rollout undo deployment/dev-api-gateway -n eshelf-dev
kubectl get pods -n eshelf-dev -l app=api-gateway
```

**Actions:**
- Show deployment history
- Explain: History shows previous versions
- Run rollback command
- Show pods rolling back
- Verify rollback

**Lời nói:**
> "Tôi đã rollback deployment về version trước. Pods đang được update về image cũ."

### [52:00 - 54:00] Show ArgoCD Rollback

**Lời nói:**
> "Cách thứ 2 là rollback qua ArgoCD UI."

**Show trên màn hình:**
- Browser Tab: ArgoCD UI
- Navigate to api-gateway application
- Click "History"
- Show deployment history
- Click "Rollback" button
- Show rollback process

**Actions:**
- Show application page
- Click "History"
- Show history list
- Click "Rollback"
- Show rollback confirmation
- Confirm rollback
- Show sync process

**Lời nói:**
> "ArgoCD đã rollback application về version trước. Rollback được thực hiện bằng cách revert manifest trong Git và sync về cluster."

### [54:00 - 55:00] Verify Rollback

**Lời nói:**
> "Hãy verify rollback đã thành công."

**Show trên màn hình:**
```powershell
# Terminal 2
kubectl get pods -n eshelf-dev -l app=api-gateway
kubectl get pods -n eshelf-dev -l app=api-gateway -o jsonpath='{.items[0].spec.containers[0].image}'
```

**Actions:**
- Show pods
- Show image tag (should be old tag)
- Verify rollback success

---

## PHẦN 8: KẾT LUẬN (5 phút)

### [55:00 - 57:00] Tổng Kết

**Lời nói:**
> "Tóm lại, chúng ta đã demo các tính năng chính của project:"

**Show trên màn hình:**
- Summary slide hoặc list:
  1. ✅ Smart Build System - Chỉ build services có thay đổi
  2. ✅ CI/CD Pipeline - PR pipeline (validation) và Push pipeline (build/deploy)
  3. ✅ GitOps với ArgoCD - Tự động sync từ Git
  4. ✅ Image Updater - Tự động update image tags
  5. ✅ Multi-Environment - Dev, Staging, Prod
  6. ✅ Monitoring - Prometheus, Grafana, Loki
  7. ✅ Security - Trivy, CodeQL, Harbor scanning
  8. ✅ Rollback - Manual và automatic rollback

### [57:00 - 58:00] Show Code Highlights

**Lời nói:**
> "Hãy xem một số code highlights."

**Show trên màn hình:**
- Terminal 1 - VS Code
- Show `.github/workflows/smart-build.yml` - Smart Build logic
- Show `infrastructure/kubernetes/argocd/` - ArgoCD configs
- Show `infrastructure/kubernetes/overlays/` - Multi-environment configs

**Actions:**
- Open key files
- Highlight important parts
- Explain briefly

### [58:00 - 60:00] Hướng Phát Triển

**Lời nói:**
> "Trong tương lai, project có thể phát triển thêm:"

**Show trên màn hình:**
- List:
  - Canary deployment
  - Blue-Green deployment
  - Advanced monitoring
  - Cost optimization
  - Performance tuning

### [60:00] Kết Thúc

**Lời nói:**
> "Cảm ơn các bạn đã xem demo. Nếu có câu hỏi, vui lòng liên hệ. Thank you!"

**Show trên màn hình:**
- Thank you slide
- Contact information
- GitHub repository link

---

## CHECKLIST TRƯỚC KHI QUAY

### Setup
- [ ] Cluster đang chạy ổn định
- [ ] Tất cả port-forwards đang chạy
- [ ] Browser tabs mở sẵn
- [ ] VS Code mở project
- [ ] Terminal windows sẵn sàng
- [ ] Code changes chuẩn bị sẵn

### Testing
- [ ] Test PR pipeline hoạt động
- [ ] Test Push pipeline hoạt động
- [ ] Test Harbor accessible
- [ ] Test ArgoCD accessible
- [ ] Test Grafana accessible
- [ ] Test Prometheus accessible
- [ ] Test rollback hoạt động

### Recording
- [ ] Screen recording software ready
- [ ] Microphone ready
- [ ] Screen resolution set (1920x1080 recommended)
- [ ] Close unnecessary applications
- [ ] Turn off notifications

---

## TIPS KHI QUAY

1. **Nói rõ ràng, chậm rãi**
   - Pause giữa các phần
   - Giải thích từng bước

2. **Zoom vào các phần quan trọng**
   - Highlight code
   - Zoom vào UI elements
   - Show mouse cursor movements

3. **Tránh lỗi**
   - Practice trước 2-3 lần
   - Có backup plan nếu lỗi
   - Nếu lỗi, giải thích và tiếp tục

4. **Timing**
   - Không quá nhanh
   - Không quá chậm
   - Pause khi cần

5. **Editing**
   - Có thể edit sau để bỏ phần chờ đợi
   - Add annotations nếu cần
   - Add background music (optional)

---

## BACKUP PLANS

### Nếu Cluster Lỗi
- Show screenshots
- Explain architecture
- Show code và configs

### Nếu Pipeline Lỗi
- Show logs
- Explain error
- Show cách fix
- Hoặc skip và giải thích

### Nếu Services Không Accessible
- Check port-forward
- Restart nếu cần
- Hoặc show screenshots

---

## SCRIPT COMMANDS TÓM TẮT

```powershell
# Setup
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl port-forward svc/grafana -n monitoring 3000:3000
kubectl port-forward svc/prometheus -n monitoring 9090:9090
kubectl port-forward svc/harbor-core -n harbor 8080:80

# Check cluster
kubectl get nodes
kubectl get pods -A
kubectl get pods -n eshelf-dev

# Check deployment
kubectl get pods -n eshelf-dev -l app=api-gateway
kubectl describe pod -n eshelf-dev -l app=api-gateway
kubectl get pods -n eshelf-dev -l app=api-gateway -o jsonpath='{.items[0].spec.containers[0].image}'

# Rollback
kubectl rollout history deployment/dev-api-gateway -n eshelf-dev
kubectl rollout undo deployment/dev-api-gateway -n eshelf-dev

# ArgoCD
kubectl get applications -n argocd
kubectl get configmap -n argocd argocd-image-updater-config -o yaml
kubectl get application api-gateway -n argocd -o yaml | Select-String -Pattern "argocd-image-updater"
```

---

**Tổng thời lượng:** ~60 phút  
**Format:** Screen recording với voice-over  
**Output:** MP4 video file

