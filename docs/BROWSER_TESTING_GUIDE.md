# Hướng Dẫn Test và Demo Trên Browser

Tài liệu này hướng dẫn cách test và demo các tools qua browser sau khi đã setup infrastructure.

## Mục Lục
1. [AWS Console Testing](#aws-console-testing)
2. [ArgoCD UI Testing](#argocd-ui-testing)
3. [Grafana Dashboard Testing](#grafana-dashboard-testing)
4. [Harbor Registry Testing](#harbor-registry-testing)
5. [Application Testing](#application-testing)

---

## AWS Console Testing

### Mở AWS Console

```powershell
.\scripts\open-aws-console.ps1
```

Hoặc truy cập trực tiếp: `https://644123626050.signin.aws.amazon.com/console?region=us-east-1`

### Đăng Nhập

- **Username:** `cloud_user`
- **Password:** `3ZJ7)y2GAjsk#P+^aD8y`

### Kiểm Tra Sau Khi Đăng Nhập

#### ✅ Thành Công - Bạn sẽ thấy:
1. **AWS Console Dashboard** hiển thị
2. **Top bar** có:
   - Account ID: `644123626050`
   - Region selector (mặc định: `us-east-1`)
   - Search bar để tìm services
3. **Services menu** ở bên trái với các services như:
   - EC2 (Compute)
   - VPC (Networking)
   - IAM (Security)
   - S3 (Storage)
   - etc.

#### ❌ Thất Bại - Các dấu hiệu:
- **Error message:** "Invalid username or password"
  - **Giải pháp:** Kiểm tra lại credentials trong `aws-academy-credentials.txt`
- **Error message:** "Account locked" hoặc "Access denied"
  - **Giải pháp:** Sandbox có thể đã bị khóa, thử lại sau hoặc liên hệ support
- **Page không load:**
  - **Giải pháp:** Kiểm tra internet connection, thử refresh

### Test Các Services Quan Trọng

#### 1. EC2 Service
1. Tìm "EC2" trong search bar hoặc click vào "EC2" trong services
2. **Kiểm tra:**
   - ✅ EC2 Dashboard load được
   - ✅ Có thể thấy "Instances" menu
   - ✅ Có thể thấy "Security Groups" menu
   - ✅ Có thể thấy "Key Pairs" menu

#### 2. VPC Service
1. Tìm "VPC" trong search bar
2. **Kiểm tra:**
   - ✅ VPC Dashboard load được
   - ✅ Có thể thấy "Your VPCs" menu
   - ✅ Có thể thấy "Subnets" menu
   - ✅ Có thể thấy "Internet Gateways" menu

#### 3. IAM Service (Để lấy Access Key)
1. Tìm "IAM" trong search bar
2. Click vào "Users" trong menu bên trái
3. Click vào user của bạn (thường là `cloud_user`)
4. Click tab "Security credentials"
5. Scroll xuống "Access keys"
6. **Kiểm tra:**
   - ✅ Có thể thấy "Create access key" button
   - ✅ Có thể tạo access key mới (nếu chưa có)

### Lấy Temporary Credentials

1. Vào **IAM** → **Users** → chọn user của bạn
2. Tab **Security credentials**
3. Scroll xuống **Access keys** → **Create access key**
4. Chọn **Command Line Interface (CLI)**
5. Copy **Access Key ID** và **Secret Access Key**
6. **Lưu ý:** Secret chỉ hiển thị một lần!

Sau đó configure AWS CLI:
```powershell
aws configure
```

---

## ArgoCD UI Testing

### Port-Forward ArgoCD

```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Truy Cập ArgoCD

- **URL:** `https://localhost:8080`
- **Username:** `admin`
- **Password:** Lấy bằng command:
  ```powershell
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
  ```

### Kiểm Tra ArgoCD

#### ✅ Thành Công - Bạn sẽ thấy:

1. **Login Page:**
   - ✅ Page load được
   - ✅ Có thể đăng nhập với admin credentials

2. **Dashboard:**
   - ✅ Hiển thị danh sách applications
   - ✅ Mỗi application có:
     - **Name:** Tên service (api-gateway, auth-service, etc.)
     - **Status:** Healthy/Unhealthy
     - **Sync Status:** Synced/OutOfSync
     - **Namespace:** Namespace của application

3. **Application Details:**
   - Click vào một application
   - ✅ Hiển thị resource tree
   - ✅ Hiển thị sync history
   - ✅ Hiển thị health status
   - ✅ Có thể thấy pods, services, deployments

4. **Sync Status:**
   - ✅ Tất cả applications có status "Synced"
   - ✅ Health status: "Healthy"
   - ✅ Không có errors hoặc warnings

#### ❌ Thất Bại - Các dấu hiệu:

- **"Connection refused" khi port-forward:**
  - **Giải pháp:** Kiểm tra ArgoCD pods đang chạy:
    ```powershell
    kubectl get pods -n argocd
    ```
  - Đảm bảo pods status: `Running`

- **"Login failed":**
  - **Giải pháp:** Kiểm tra lại password, lấy password mới bằng command trên

- **Applications không sync:**
  - **Giải pháp:** 
    - Kiểm tra ArgoCD logs:
      ```powershell
      kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
      ```
    - Kiểm tra repository access
    - Kiểm tra image pull errors

### Demo Scenarios

#### Scenario 1: Manual Sync
1. Tìm một application có status "OutOfSync"
2. Click vào application
3. Click "Sync" button
4. Chọn "Synchronize"
5. **Kết quả mong đợi:** Application sync thành công, status chuyển sang "Synced"

#### Scenario 2: View Application Resources
1. Click vào một application (ví dụ: `api-gateway`)
2. Click tab "Resource Tree"
3. **Kiểm tra:**
   - ✅ Deployment được hiển thị
   - ✅ Service được hiển thị
   - ✅ Pods được hiển thị
   - ✅ Tất cả resources có status "Healthy"

#### Scenario 3: Rollback
1. Click vào một application
2. Click tab "History"
3. Chọn một revision cũ
4. Click "Rollback"
5. **Kết quả mong đợi:** Application rollback về version cũ

---

## Grafana Dashboard Testing

### Port-Forward Grafana

```powershell
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

### Truy Cập Grafana

- **URL:** `http://localhost:3000`
- **Username:** `admin`
- **Password:** `admin` (sẽ được yêu cầu đổi sau lần đăng nhập đầu)

### Kiểm Tra Grafana

#### ✅ Thành Công - Bạn sẽ thấy:

1. **Login Page:**
   - ✅ Page load được
   - ✅ Có thể đăng nhập

2. **Home Dashboard:**
   - ✅ Hiển thị dashboard mặc định
   - ✅ Có menu bên trái với:
     - Dashboards
     - Explore
     - Alerting
     - Configuration

3. **Data Sources:**
   - Vào **Configuration** → **Data Sources**
   - ✅ Có Prometheus data source
   - ✅ Prometheus data source status: "Success"
   - ✅ Có thể test connection

4. **Dashboards:**
   - Vào **Dashboards** → **Browse**
   - ✅ Có các dashboards mặc định
   - ✅ Có thể import dashboards mới
   - ✅ Dashboards hiển thị metrics

5. **Metrics:**
   - Vào **Explore**
   - Chọn Prometheus data source
   - Thử query: `up`
   - ✅ Hiển thị metrics từ Prometheus

#### ❌ Thất Bại - Các dấu hiệu:

- **"Connection refused":**
  - **Giải pháp:** Kiểm tra Grafana pods:
    ```powershell
    kubectl get pods -n monitoring -l app=grafana
    ```

- **"No data" trong dashboards:**
  - **Giải pháp:**
    - Kiểm tra Prometheus đang chạy:
      ```powershell
      kubectl get pods -n monitoring -l app=prometheus
      ```
    - Kiểm tra Prometheus scrape configs
    - Kiểm tra service discovery

- **Prometheus data source không connect:**
  - **Giải pháp:**
    - Kiểm tra Prometheus service URL trong Grafana config
    - Kiểm tra network connectivity giữa Grafana và Prometheus

### Demo Scenarios

#### Scenario 1: View Application Metrics
1. Vào **Explore**
2. Chọn Prometheus data source
3. Query: `kube_pod_info{namespace="default"}`
4. **Kết quả mong đợi:** Hiển thị thông tin về pods

#### Scenario 2: Create Custom Dashboard
1. Vào **Dashboards** → **New Dashboard**
2. Add panel
3. Chọn metric từ Prometheus
4. **Kết quả mong đợi:** Dashboard hiển thị metrics

#### Scenario 3: View Service Metrics
1. Tìm dashboard cho service cụ thể (nếu có)
2. Hoặc tạo query trong Explore
3. **Kết quả mong đợi:** Hiển thị metrics từ service

---

## Harbor Registry Testing

### Port-Forward Harbor

```powershell
kubectl port-forward svc/harbor-core -n harbor 8081:80
```

### Truy Cập Harbor

- **URL:** `http://localhost:8081`
- **Username:** `admin`
- **Password:** Xem trong Harbor values.yaml hoặc secret:
  ```powershell
  kubectl get secret harbor-core -n harbor -o jsonpath="{.data.HARBOR_ADMIN_PASSWORD}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
  ```

### Kiểm Tra Harbor

#### ✅ Thành Công - Bạn sẽ thấy:

1. **Login Page:**
   - ✅ Page load được
   - ✅ Có thể đăng nhập

2. **Dashboard:**
   - ✅ Hiển thị thống kê:
     - Projects count
     - Repositories count
     - Images count
   - ✅ Có menu bên trái:
     - Projects
     - Repositories
     - Artifacts
     - Vulnerability Scanning

3. **Projects:**
   - Vào **Projects**
   - ✅ Có thể tạo project mới
   - ✅ Có thể xem danh sách projects
   - ✅ Có thể xem repositories trong project

4. **Repositories:**
   - Vào **Repositories**
   - ✅ Hiển thị danh sách images
   - ✅ Có thể xem tags của images
   - ✅ Có thể xem vulnerability scan results

5. **Vulnerability Scanning:**
   - Vào một repository
   - Click vào tag
   - ✅ Hiển thị vulnerability scan results (nếu đã scan)

#### ❌ Thất Bại - Các dấu hiệu:

- **"Connection refused":**
  - **Giải pháp:** Kiểm tra Harbor pods:
    ```powershell
    kubectl get pods -n harbor
    ```

- **"Login failed":**
  - **Giải pháp:** Kiểm tra lại password, lấy password từ secret

- **"Cannot push/pull images":**
  - **Giải pháp:**
    - Kiểm tra Harbor ingress config
    - Kiểm tra Docker registry endpoint
    - Kiểm tra credentials

### Demo Scenarios

#### Scenario 1: Create Project
1. Vào **Projects** → **New Project**
2. Điền tên project (ví dụ: `eshelf`)
3. Chọn visibility (Public/Private)
4. Click **OK**
5. **Kết quả mong đợi:** Project được tạo thành công

#### Scenario 2: Push Image
1. Login vào Harbor từ Docker:
   ```powershell
   docker login localhost:8081
   ```
2. Tag image:
   ```powershell
   docker tag <image> localhost:8081/eshelf/<image>
   ```
3. Push image:
   ```powershell
   docker push localhost:8081/eshelf/<image>
   ```
4. **Kết quả mong đợi:** Image được push thành công, hiển thị trong Harbor UI

#### Scenario 3: Vulnerability Scanning
1. Vào một repository
2. Click vào một tag
3. Click "Scan" button (nếu chưa scan)
4. **Kết quả mong đợi:** Scan results hiển thị vulnerabilities (nếu có)

---

## Application Testing

### Kiểm Tra Applications Đang Chạy

```powershell
kubectl get pods -A
```

### Port-Forward Applications

#### API Gateway
```powershell
kubectl port-forward svc/api-gateway -n default 3000:3000
```
- **URL:** `http://localhost:3000`

#### Frontend (nếu có)
```powershell
kubectl port-forward svc/frontend -n default 5173:5173
```
- **URL:** `http://localhost:5173`

### Kiểm Tra Applications

#### ✅ Thành Công - Bạn sẽ thấy:

1. **API Gateway:**
   - ✅ API endpoints accessible
   - ✅ Health check endpoint: `http://localhost:3000/health`
   - ✅ API documentation (nếu có)

2. **Services:**
   - ✅ Auth service: Login/Register endpoints hoạt động
   - ✅ Book service: Book endpoints hoạt động
   - ✅ User service: User endpoints hoạt động

3. **Frontend (nếu có):**
   - ✅ Page load được
   - ✅ Có thể navigate giữa các pages
   - ✅ Có thể login/register
   - ✅ Có thể xem books

#### ❌ Thất Bại - Các dấu hiệu:

- **"Connection refused":**
  - **Giải pháp:** Kiểm tra pods đang chạy:
    ```powershell
    kubectl get pods -n default
    ```

- **"502 Bad Gateway" hoặc "503 Service Unavailable":**
  - **Giải pháp:**
    - Kiểm tra service endpoints:
      ```powershell
      kubectl get endpoints -n default
      ```
    - Kiểm tra pods logs:
      ```powershell
      kubectl logs <pod-name> -n default
      ```

- **"401 Unauthorized":**
  - **Giải pháp:** Kiểm tra authentication flow, JWT tokens

### Demo Scenarios

#### Scenario 1: Health Check
1. Truy cập: `http://localhost:3000/health`
2. **Kết quả mong đợi:** Response `{"status": "ok"}`

#### Scenario 2: API Test
1. Test login endpoint:
   ```powershell
   curl -X POST http://localhost:3000/api/auth/login -H "Content-Type: application/json" -d '{"username":"test","password":"test"}'
   ```
2. **Kết quả mong đợi:** Response với JWT token

#### Scenario 3: Frontend Flow
1. Mở frontend URL
2. Navigate qua các pages
3. Test login/register
4. Test book browsing
5. **Kết quả mong đợi:** Tất cả features hoạt động bình thường

---

## Checklist Tổng Hợp

### AWS Console
- [ ] Có thể đăng nhập
- [ ] Có thể xem EC2 instances
- [ ] Có thể xem VPC resources
- [ ] Có thể lấy Access Key từ IAM

### ArgoCD
- [ ] Có thể đăng nhập
- [ ] Tất cả applications hiển thị
- [ ] Tất cả applications status: Synced
- [ ] Có thể xem application resources
- [ ] Có thể sync/rollback applications

### Grafana
- [ ] Có thể đăng nhập
- [ ] Prometheus data source connected
- [ ] Dashboards hiển thị metrics
- [ ] Có thể query metrics

### Harbor
- [ ] Có thể đăng nhập
- [ ] Có thể tạo projects
- [ ] Có thể push/pull images
- [ ] Vulnerability scanning hoạt động

### Applications
- [ ] API Gateway accessible
- [ ] Health checks pass
- [ ] API endpoints hoạt động
- [ ] Frontend (nếu có) load được

---

## Troubleshooting Browser Issues

### Lỗi: "This site can't be reached"

**Nguyên nhân:** Port-forward không hoạt động hoặc service chưa ready

**Giải pháp:**
1. Kiểm tra port-forward process đang chạy
2. Kiểm tra service pods đang running
3. Thử port-forward lại

### Lỗi: "Certificate error" (HTTPS)

**Nguyên nhân:** Self-signed certificate

**Giải pháp:**
1. Click "Advanced" → "Proceed to localhost"
2. Hoặc import certificate vào browser

### Lỗi: "Timeout" hoặc "Slow loading"

**Nguyên nhân:** Resources chưa ready hoặc network issues

**Giải pháp:**
1. Kiểm tra pods status
2. Kiểm tra resource limits
3. Kiểm tra network connectivity

---

## Tips cho Demo

1. **Chuẩn bị trước:**
   - Mở tất cả port-forwards trước khi demo
   - Verify tất cả services đang running
   - Có sẵn credentials để login

2. **Trình bày:**
   - Bắt đầu từ AWS Console (infrastructure)
   - Sau đó ArgoCD (GitOps)
   - Tiếp theo Grafana (monitoring)
   - Cuối cùng Applications (end result)

3. **Highlight features:**
   - Auto-sync trong ArgoCD
   - Real-time metrics trong Grafana
   - Image scanning trong Harbor
   - Health checks và monitoring



