# Kịch Bản Rollback - eShelf Project

## Tổng Quan

Tài liệu này mô tả các kịch bản rollback khi deployment thất bại hoặc phát hiện lỗi trong production.

## Kịch Bản 1: Rollback Tự Động Khi Deployment Thất Bại

### Tình Huống
Deployment mới thất bại trong quá trình rollout, pods không start được hoặc health check fail.

### Cơ Chế
GitHub Actions workflow `deploy-rollback.yml` tự động rollback khi:
- Deployment timeout
- Health check fail
- Pods CrashLoopBackOff

### Các Bước

1. **Workflow tự động detect failure:**
```yaml
- name: Rollback on failure
  if: failure() && github.event.inputs.rollback != 'true'
  run: |
    kubectl rollout undo deployment/api-gateway -n eshelf-prod
    kubectl rollout undo deployment/auth-service -n eshelf-prod
    # ... các services khác
```

2. **Verify rollback:**
```bash
kubectl rollout status deployment/api-gateway -n eshelf-prod
kubectl get pods -n eshelf-prod
```

### Kết Quả Mong Đợi
- Tất cả deployments rollback về version trước
- Services hoạt động bình thường với version cũ
- Không có downtime

---

## Kịch Bản 2: Rollback Thủ Công Qua GitHub Actions

### Tình Huống
Phát hiện lỗi sau khi deployment thành công (ví dụ: bug trong business logic).

### Các Bước

1. **Trigger rollback workflow:**
   - Vào GitHub Actions
   - Chọn workflow "Deploy with Rollback"
   - Click "Run workflow"
   - Chọn environment (staging/production)
   - Check "Rollback to previous version"
   - Run workflow

2. **Workflow sẽ:**
   - Get current deployment version
   - Rollback tất cả services về version trước
   - Wait for rollout complete
   - Verify health checks

3. **Verify:**
```bash
kubectl get deployments -n eshelf-prod -o wide
kubectl rollout history deployment/api-gateway -n eshelf-prod
```

### Kết Quả Mong Đợi
- Services rollback về version trước
- Application hoạt động với version ổn định

---

## Kịch Bản 3: Rollback Bằng Kubectl

### Tình Huống
Cần rollback nhanh trực tiếp trên cluster, không qua GitHub Actions.

### Các Bước

1. **Check rollout history:**
```bash
kubectl rollout history deployment/api-gateway -n eshelf-prod
```

2. **Rollback về version trước:**
```bash
kubectl rollout undo deployment/api-gateway -n eshelf-prod
kubectl rollout undo deployment/auth-service -n eshelf-prod
kubectl rollout undo deployment/book-service -n eshelf-prod
kubectl rollout undo deployment/user-service -n eshelf-prod
kubectl rollout undo deployment/ml-service -n eshelf-prod
```

3. **Rollback về version cụ thể:**
```bash
kubectl rollout undo deployment/api-gateway --to-revision=2 -n eshelf-prod
```

4. **Verify:**
```bash
kubectl rollout status deployment/api-gateway -n eshelf-prod
kubectl get pods -n eshelf-prod
```

### Kết Quả Mong Đợi
- Services rollback về version được chỉ định
- Pods restart với image cũ

---

## Kịch Bản 4: Rollback Image Tag Trong ArgoCD

### Tình Huống
ArgoCD đã sync deployment mới nhưng cần rollback image tag.

### Các Bước

1. **Check current image:**
```bash
kubectl get deployment api-gateway -n eshelf-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
```

2. **Update Kustomize overlay:**
```bash
cd infrastructure/kubernetes/overlays/prod
kustomize edit set image api-gateway=harbor.yourdomain.com/eshelf/api-gateway:<previous-tag>
```

3. **Commit và push:**
```bash
git add infrastructure/kubernetes/overlays/prod/kustomization.yaml
git commit -m "rollback: revert api-gateway to previous version"
git push origin main
```

4. **ArgoCD sẽ tự động sync:**
   - ArgoCD detect changes trong Git
   - Sync deployment với image tag cũ
   - Rollout pods với image cũ

### Kết Quả Mong Đợi
- ArgoCD sync changes
- Deployment sử dụng image tag cũ
- Git repo có record của rollback

---

## Kịch Bản 5: Rollback Database Migration

### Tình Huống
Deployment mới có database migration gây lỗi, cần rollback cả code và database.

### Các Bước

1. **Rollback application code:**
```bash
kubectl rollout undo deployment/api-gateway -n eshelf-prod
```

2. **Rollback database migration:**
```bash
# Nếu dùng Prisma
cd backend/services/user-service
npx prisma migrate resolve --rolled-back <migration-name>
npx prisma migrate deploy
```

3. **Verify:**
```bash
kubectl get pods -n eshelf-prod
kubectl logs deployment/api-gateway -n eshelf-prod
```

### Kết Quả Mong Đợi
- Application và database đồng bộ với version cũ
- Không có data inconsistency

---

## Kịch Bản 6: Partial Rollback (Chỉ Một Service)

### Tình Huống
Chỉ một service có vấn đề, các service khác hoạt động bình thường.

### Các Bước

1. **Identify problematic service:**
```bash
kubectl get pods -n eshelf-prod
kubectl logs deployment/<problematic-service> -n eshelf-prod
```

2. **Rollback chỉ service đó:**
```bash
kubectl rollout undo deployment/<problematic-service> -n eshelf-prod
```

3. **Verify other services:**
```bash
kubectl get pods -n eshelf-prod
# Check other services still running
```

### Kết Quả Mong Đợi
- Chỉ service có vấn đề được rollback
- Các service khác tiếp tục chạy version mới

---

## Best Practices

### 1. Luôn Giữ Image Tags
- Sử dụng commit SHA làm image tag
- Giữ lại các image tags cũ trong registry
- Không xóa images đang được sử dụng

### 2. Test Rollback Process
- Định kỳ test rollback process
- Document các bước rollback
- Train team về rollback procedures

### 3. Monitor Rollback Events
- Set up alerts cho rollback events
- Log tất cả rollback actions
- Review rollback frequency để identify issues

### 4. Database Migration Safety
- Luôn có rollback migration scripts
- Test migrations trên staging trước
- Backup database trước khi migrate

### 5. Communication
- Thông báo team khi rollback
- Document lý do rollback
- Post-mortem sau rollback

---

## Troubleshooting

### Rollback Không Hoạt Động

**Vấn đề:** `kubectl rollout undo` không có effect

**Giải pháp:**
```bash
# Check rollout history
kubectl rollout history deployment/api-gateway -n eshelf-prod

# Force rollback
kubectl set image deployment/api-gateway api-gateway=<old-image> -n eshelf-prod
```

### Image Cũ Không Tồn Tại

**Vấn đề:** Image tag cũ đã bị xóa khỏi registry

**Giải pháp:**
- Check Harbor registry cho image tags
- Restore từ backup nếu có
- Rebuild image từ code version cũ

### ArgoCD Không Sync Rollback

**Vấn đề:** ArgoCD không detect changes trong Git

**Giải pháp:**
```bash
# Force sync
argocd app sync api-gateway

# Hoặc qua UI
# ArgoCD UI → Application → Sync
```

---

## Checklist Trước Khi Rollback

- [ ] Xác định version cần rollback
- [ ] Verify image tag tồn tại trong registry
- [ ] Check database migration compatibility
- [ ] Backup database (nếu cần)
- [ ] Thông báo team
- [ ] Document lý do rollback
- [ ] Có rollback plan rõ ràng

---

## Kết Luận

Rollback là một phần quan trọng của deployment strategy. Project eShelf có nhiều cơ chế rollback:
- Automatic rollback trong GitHub Actions
- Manual rollback qua workflow
- Direct kubectl rollback
- ArgoCD GitOps rollback

Tất cả các cơ chế đều được test và document để đảm bảo an toàn khi cần rollback.

