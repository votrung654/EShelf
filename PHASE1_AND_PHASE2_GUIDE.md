# Phase 1 & Phase 2 Setup Guide

## 🎯 PHASE 1: Tạo PR và Kiểm Tra Pipeline

### Bước 1: Tạo Pull Request

**Từ ảnh bạn đính kèm, tôi thấy:**
- ✅ Banner màu cam: "feature/test-pr-pipeline had recent pushes 2 minutes ago"
- ✅ Button "Compare & pull request" sẵn sàng

**Cách tạo PR:**

1. **Click vào button "Compare & pull request"** trên GitHub
   - Hoặc truy cập: https://github.com/votrung654/EShelf/pull/new/feature/test-pr-pipeline

2. **Điền thông tin PR:**
   - **Title:** `test: Phase 1 - PR Pipeline Test`
   - **Description:**
     ```markdown
     ## Test PR Pipeline
     
     This PR is for testing Phase 1 validation:
     - Test PR-only pipeline
     - Verify no deploy steps run
     - Test CI/CD workflows
     
     Changes:
     - Updated README.md (test comment)
     - Updated package.json description
     ```

3. **Click "Create pull request"**

### Bước 2: Kiểm Tra PR Pipeline

**Sau khi tạo PR, kiểm tra:**

1. **Vào tab "Actions"** trên GitHub
   - URL: https://github.com/votrung654/EShelf/actions

2. **Tìm workflow "Pull Request Pipeline"**
   - Sẽ có workflow mới chạy với tên PR của bạn

3. **Click vào workflow để xem chi tiết**

4. **Kiểm tra các jobs:**
   - ✅ **Frontend CI** - Should run (lint, test, build)
   - ✅ **Backend CI** - Should run (lint, test)
   - ✅ **Code Quality Scan** - Should run (SonarQube)
   - ✅ **Security Scan** - Should run (Checkov)
   - ❌ **Docker Build** - Should NOT run
   - ❌ **Deploy** - Should NOT run

**Kỳ vọng:**
- Tất cả test/scan jobs chạy
- Không có build/deploy jobs
- Pipeline pass hoặc fail (tùy code quality)

**Nếu có lỗi:**
- Xem logs trong từng job
- Sửa code nếu cần
- Push thêm commit để trigger lại

---

## 🚀 PHASE 2: Setup Local Kubernetes Cluster

### Bước 1: Cài đặt k3d (Khuyên dùng - Nhẹ nhất)

```powershell
# Cài đặt k3d
winget install k3d

# Hoặc nếu winget không có:
# Download từ: https://k3d.io/
# Hoặc dùng Chocolatey: choco install k3d
```

### Bước 2: Tạo Local K8s Cluster

```powershell
# Tạo cluster với 1 master và 2 workers (giống AWS setup)
k3d cluster create eshelf-cluster `
  --servers 1 `
  --agents 2 `
  --port "8080:80@loadbalancer" `
  --port "8443:443@loadbalancer" `
  --wait

# Verify cluster
kubectl get nodes
```

**Kết quả mong đợi:**
```
NAME                      STATUS   ROLES           AGE   VERSION
k3d-eshelf-cluster-0      Ready    control-plane   30s   v1.28.x
k3d-eshelf-cluster-agent-0 Ready   <none>          25s   v1.28.x
k3d-eshelf-cluster-agent-1 Ready   <none>          25s   v1.28.x
```

### Bước 3: Cài đặt kubectl (Nếu chưa có)

```powershell
# Kiểm tra kubectl
kubectl version --client

# Nếu chưa có, cài đặt:
winget install Kubernetes.kubectl
```

### Bước 4: Verify Cluster

```powershell
# Check nodes
kubectl get nodes

# Check cluster info
kubectl cluster-info

# Check all pods
kubectl get pods --all-namespaces
```

---

## 📋 CÁC BƯỚC TIẾP THEO (Phase 2)

Sau khi cluster sẵn sàng, có thể test các bước:

### 4.3 Deploy Applications
### 4.4 Setup Monitoring  
### 4.5 Setup ArgoCD
### 4.6 Setup Harbor
### 4.7 Setup Jenkins
### 4.8 Setup SonarQube

**Xem chi tiết trong:** `SETUP_WITHOUT_AWS.md`

---

## 🔍 TROUBLESHOOTING

### PR Pipeline không chạy?
- Kiểm tra branch đã push chưa
- Kiểm tra workflow file `.github/workflows/pr-only.yml`
- Xem tab Actions có workflow nào không

### k3d không cài được?
- Thử winget: `winget install k3d`
- Hoặc download manual: https://k3d.io/
- Hoặc dùng minikube thay thế

### Cluster không tạo được?
- Kiểm tra Docker Desktop đang chạy
- Kiểm tra port 8080, 8443 có bị chiếm không
- Thử tạo với port khác

---

## ✅ CHECKLIST

### Phase 1:
- [ ] Tạo PR trên GitHub
- [ ] Xem PR pipeline chạy
- [ ] Verify chỉ có test/scan jobs
- [ ] Verify không có deploy jobs

### Phase 2:
- [ ] Cài đặt k3d
- [ ] Tạo cluster
- [ ] Verify nodes
- [ ] Sẵn sàng deploy apps

---

**Sau khi hoàn thành Phase 1 & 2, bạn sẽ có:**
- ✅ PR pipeline hoạt động
- ✅ Local K8s cluster sẵn sàng
- ✅ Có thể test tất cả deployments



