# Script để sửa lỗi Monitoring (Grafana CrashLoopBackOff và Prometheus không scrape được metrics)
# Sử dụng: .\fix-monitoring.ps1

Write-Host "=== Fixing Monitoring System ===" -ForegroundColor Cyan

# Xác định đường dẫn đến folder monitoring
$monitoringPath = Join-Path $PSScriptRoot "monitoring"

Write-Host "`n1. Deleting existing Grafana deployment..." -ForegroundColor Yellow
kubectl delete deploy grafana -n monitoring --ignore-not-found=true

if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Error deleting Grafana deployment (may not exist)" -ForegroundColor Yellow
}

Write-Host "`n2. Waiting for Grafana pod to be fully terminated..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "`n3. Applying monitoring manifests from $monitoringPath..." -ForegroundColor Yellow
kubectl apply -k $monitoringPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to apply monitoring manifests!" -ForegroundColor Red
    exit 1
}

Write-Host "`n4. Waiting for Grafana deployment rollout..." -ForegroundColor Yellow
kubectl rollout status deploy/grafana -n monitoring --timeout=5m

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Grafana deployment rollout failed!" -ForegroundColor Red
    Write-Host "Checking pod status..." -ForegroundColor Yellow
    kubectl get pods -n monitoring
    kubectl describe pod -l app=grafana -n monitoring
    exit 1
}

Write-Host "`n5. Checking Grafana pod status..." -ForegroundColor Yellow
kubectl get pods -n monitoring -l app=grafana

Write-Host "`n6. Checking Prometheus targets..." -ForegroundColor Yellow
Write-Host "Note: You can check Prometheus targets by port-forwarding: kubectl port-forward -n monitoring svc/prometheus 9090:9090" -ForegroundColor Cyan
Write-Host "Then visit: http://localhost:9090/targets" -ForegroundColor Cyan

Write-Host "`n=== Monitoring fix completed! ===" -ForegroundColor Green
Write-Host "`nTo verify Grafana is running:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n monitoring" -ForegroundColor White
Write-Host "`nTo check Grafana logs:" -ForegroundColor Cyan
Write-Host "  kubectl logs -n monitoring -l app=grafana --tail=50" -ForegroundColor White

