# Script để port-forward các monitoring services
# Sử dụng: .\port-forward-monitoring.ps1

Write-Host "=== Port Forwarding Monitoring Services ===" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra xem port-forward đã chạy chưa
$grafanaRunning = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
$prometheusRunning = Get-NetTCPConnection -LocalPort 9090 -ErrorAction SilentlyContinue

if ($grafanaRunning -or $prometheusRunning) {
    Write-Host "Warning: Port 3000 hoặc 9090 đã được sử dụng!" -ForegroundColor Yellow
    Write-Host "Đang dừng các port-forward cũ..." -ForegroundColor Yellow
    Get-Process | Where-Object { $_.ProcessName -eq "kubectl" -and $_.CommandLine -like "*port-forward*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "1. Starting Grafana port-forward (localhost:3000)..." -ForegroundColor Yellow
Start-Process -NoNewWindow kubectl -ArgumentList "port-forward", "-n", "monitoring", "svc/grafana", "3000:3000"

Start-Sleep -Seconds 2

Write-Host "2. Starting Prometheus port-forward (localhost:9090)..." -ForegroundColor Yellow
Start-Process -NoNewWindow kubectl -ArgumentList "port-forward", "-n", "monitoring", "svc/prometheus", "9090:9090"

Start-Sleep -Seconds 2

Write-Host ""
Write-Host "=== Monitoring Services đã sẵn sàng! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Grafana:    http://localhost:3000" -ForegroundColor Cyan
Write-Host "   Username: admin" -ForegroundColor Yellow
Write-Host "   Password: admin123" -ForegroundColor Yellow
Write-Host ""
Write-Host "Prometheus: http://localhost:9090" -ForegroundColor Cyan
Write-Host ""
Write-Host "Để dừng port-forward, nhấn Ctrl+C hoặc đóng cửa sổ này." -ForegroundColor Gray
Write-Host "Hoặc chạy: Get-Process | Where-Object {`$_.ProcessName -eq 'kubectl'} | Stop-Process" -ForegroundColor Gray
Write-Host ""

# Giữ script chạy để port-forward không bị dừng
try {
    while ($true) {
        Start-Sleep -Seconds 10
    }
} catch {
    Write-Host "`nĐang dừng port-forward..." -ForegroundColor Yellow
    Get-Process | Where-Object { $_.ProcessName -eq "kubectl" -and $_.CommandLine -like "*port-forward*" } | Stop-Process -Force -ErrorAction SilentlyContinue
}





