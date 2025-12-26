# Phase 2 Deployment Guide - Local K8s Cluster

**Cluster:** k3d-eshelf-cluster  
**Status:** ✅ Ready (3/3 nodes)

---

## 🔧 FIX: kubectl Connection Issue

### Giải pháp: Dùng kubectl từ container

**Script helper đã tạo:** `scripts/kubectl-k3d.ps1`

**Cách dùng:**
```powershell
# Thay vì: kubectl get nodes
.\scripts\kubectl-k3d.ps1 get nodes

# Hoặc dùng trực tiếp:
docker exec k3d-eshelf-cluster-server-0 kubectl get nodes
```

**Hoặc tạo alias:**
```powershell
function k { docker exec k3d-eshelf-cluster-server-0 kubectl $args }
k get nodes
```

---

## 📋 PHASE 2 DEPLOYMENT PLAN

### Thứ tự deploy:
1. ✅ **Monitoring** (Prometheus, Grafana) - Dễ nhất
2. ✅ **SonarQube** - Đơn giản
3. ✅ **ArgoCD** - Quan trọng cho GitOps
4. ✅ **Harbor** - Cần storage, phức tạp hơn
5. ✅ **Jenkins** - Cần storage, phức tạp hơn
6. ✅ **Applications** - Deploy apps lên cluster

---

## 🚀 BẮT ĐẦU DEPLOYMENT



