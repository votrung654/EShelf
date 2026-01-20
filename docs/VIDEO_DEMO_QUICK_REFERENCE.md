# Video Demo - Quick Reference

## Timeline Tóm Tắt

| Time | Phần | Nội Dung Chính |
|------|------|----------------|
| 0:00-5:00 | Intro | Giới thiệu project, kiến trúc, tech stack |
| 5:00-13:00 | Smart Build | Code change → PR → Verify chỉ build service thay đổi |
| 13:00-25:00 | CI/CD | Merge PR → Build → Push Harbor → ArgoCD Sync → Deploy |
| 25:00-33:00 | GitOps | ArgoCD Apps → Image Updater → Multi-env |
| 33:00-45:00 | Monitoring | Prometheus → Grafana → Loki logs |
| 45:00-50:00 | Security | Trivy → CodeQL → Harbor scanning |
| 50:00-55:00 | Rollback | kubectl rollback → ArgoCD rollback |
| 55:00-60:00 | Kết luận | Tổng kết, highlights, hướng phát triển |

## URLs Cần Mở

- GitHub: https://github.com/[repo]
- GitHub Actions: https://github.com/[repo]/actions
- ArgoCD: https://localhost:8080 (admin / [password])
- Grafana: http://localhost:3000 (admin / admin123)
- Prometheus: http://localhost:9090
- Harbor: http://localhost:8080 (admin / Harbor12345)

## Commands Cần Chạy

### Setup Port-Forwards
```powershell
# Terminal 3
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 4
kubectl port-forward svc/grafana -n monitoring 3000:3000

# Terminal 5
kubectl port-forward svc/prometheus -n monitoring 9090:9090

# Terminal 6
kubectl port-forward svc/harbor-core -n harbor 8080:80
```

### Check Cluster
```powershell
kubectl get nodes
kubectl get pods -A
kubectl get pods -n eshelf-dev
```

### Verify Deployment
```powershell
kubectl get pods -n eshelf-dev -l app=api-gateway
kubectl get pods -n eshelf-dev -l app=api-gateway -o jsonpath='{.items[0].spec.containers[0].image}'
```

### Rollback
```powershell
kubectl rollout history deployment/dev-api-gateway -n eshelf-dev
kubectl rollout undo deployment/dev-api-gateway -n eshelf-dev
```

## Key Points Cần Nhấn Mạnh

1. **Smart Build**: Chỉ build service có thay đổi
2. **Harbor**: Self-hosted registry (không phải Docker Hub)
3. **PostgreSQL**: In-cluster, database per service (không phải RDS)
4. **GitOps**: ArgoCD tự động sync từ Git
5. **Image Updater**: Tự động update image tags
6. **Monitoring**: Prometheus + Grafana + Loki
7. **Security**: Trivy + CodeQL + Harbor scanning
8. **Rollback**: Manual và automatic

## Screenshots Cần Chụp

- [ ] Architecture diagram
- [ ] GitHub Actions PR pipeline (chỉ api-gateway chạy)
- [ ] GitHub Actions Push pipeline (build và push)
- [ ] Harbor UI với image mới
- [ ] ArgoCD UI với applications
- [ ] Prometheus targets
- [ ] Grafana dashboard
- [ ] Loki logs
- [ ] Security scan results

## Backup Plans

- Nếu cluster lỗi → Show screenshots + explain
- Nếu pipeline lỗi → Show logs + explain error
- Nếu service không accessible → Check port-forward hoặc show screenshots

## Checklist Trước Khi Quay

- [ ] Cluster running
- [ ] Port-forwards active
- [ ] Browser tabs ready
- [ ] VS Code open
- [ ] Terminals ready
- [ ] Code changes prepared
- [ ] Recording software ready
- [ ] Microphone ready
- [ ] Notifications off





