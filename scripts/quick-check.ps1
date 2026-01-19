param(
    [switch]$Detailed
)

Write-Host "=== Quick Cluster Check ===" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()

Write-Host "1. Nodes Status" -ForegroundColor Yellow
$nodes = kubectl get nodes --no-headers 2>&1
if ($LASTEXITCODE -eq 0) {
    $readyNodes = ($nodes | Where-Object { $_ -match "Ready" }).Count
    $totalNodes = ($nodes -split "`n").Count
    Write-Host "   Nodes: $readyNodes/$totalNodes Ready" -ForegroundColor $(if ($readyNodes -eq $totalNodes) { "Green" } else { "Yellow" })
    if ($readyNodes -lt $totalNodes) {
        $warnings += "Some nodes are not Ready"
    }
} else {
    $errors += "Cannot connect to cluster"
}

Write-Host "`n2. Pods Status" -ForegroundColor Yellow
$pods = kubectl get pods -A --no-headers 2>&1
if ($LASTEXITCODE -eq 0) {
    $running = ($pods | Where-Object { $_ -match "Running" }).Count
    $pending = ($pods | Where-Object { $_ -match "Pending" }).Count
    $failed = ($pods | Where-Object { $_ -match "Error|CrashLoopBackOff|ImagePullBackOff" }).Count
    $total = ($pods -split "`n").Count
    Write-Host "   Running: $running/$total" -ForegroundColor Green
    if ($pending -gt 0) {
        Write-Host "   Pending: $pending" -ForegroundColor Yellow
        $warnings += "$pending pods are Pending"
    }
    if ($failed -gt 0) {
        Write-Host "   Failed: $failed" -ForegroundColor Red
        $warnings += "$failed pods have errors"
    }
} else {
    $errors += "Cannot get pods"
}

Write-Host "`n3. ArgoCD Applications" -ForegroundColor Yellow
$apps = kubectl get applications -n argocd --no-headers 2>&1
if ($LASTEXITCODE -eq 0) {
    $synced = ($apps | Where-Object { $_ -match "Synced" }).Count
    $outofsync = ($apps | Where-Object { $_ -match "OutOfSync" }).Count
    Write-Host "   Synced: $synced" -ForegroundColor Green
    if ($outofsync -gt 0) {
        Write-Host "   OutOfSync: $outofsync" -ForegroundColor Yellow
        $warnings += "$outofsync applications are OutOfSync"
    }
} else {
    $warnings += "Cannot get ArgoCD applications"
}

Write-Host "`n4. Services Status" -ForegroundColor Yellow
$services = @("argocd-server", "grafana", "prometheus", "harbor-core", "jenkins", "sonarqube")
foreach ($svc in $services) {
    $namespace = switch ($svc) {
        "argocd-server" { "argocd" }
        "grafana" { "monitoring" }
        "prometheus" { "monitoring" }
        "harbor-core" { "harbor" }
        "jenkins" { "jenkins" }
        "sonarqube" { "sonarqube" }
    }
    $result = kubectl get svc -n $namespace $svc --no-headers 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   $svc : OK" -ForegroundColor Green
    } else {
        Write-Host "   $svc : Not found" -ForegroundColor Yellow
        $warnings += "$svc service not found"
    }
}

if ($Detailed) {
    Write-Host "`n5. Detailed Pod Status" -ForegroundColor Yellow
    kubectl get pods -A | Select-String -Pattern "Pending|Error|CrashLoop|ImagePull" | ForEach-Object {
        Write-Host "   $_" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "All checks passed!" -ForegroundColor Green
} else {
    if ($errors.Count -gt 0) {
        Write-Host "Errors:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
    if ($warnings.Count -gt 0) {
        Write-Host "Warnings:" -ForegroundColor Yellow
        $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
}






