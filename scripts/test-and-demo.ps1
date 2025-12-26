# Test and Demo Script for eShelf Infrastructure
# This script tests all deployed services and provides demo instructions

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "eShelf Infrastructure Test & Demo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Colors
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Yellow"

# Test Functions
function Test-KubectlConnection {
    Write-Host "`n[1/8] Testing kubectl connection..." -ForegroundColor $infoColor
    try {
        $nodes = kubectl get nodes --no-headers 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] kubectl connected successfully" -ForegroundColor $successColor
            kubectl get nodes
            return $true
        } else {
            Write-Host "[FAIL] kubectl connection failed" -ForegroundColor $errorColor
            return $false
        }
    } catch {
        Write-Host "✗ Error: $_" -ForegroundColor $errorColor
        return $false
    }
}

function Test-Namespaces {
    Write-Host "`n[2/8] Checking namespaces..." -ForegroundColor $infoColor
    $namespaces = @("argocd", "monitoring", "harbor")
    $allExist = $true
    
    foreach ($ns in $namespaces) {
        $exists = kubectl get namespace $ns --ignore-not-found 2>&1
        if ($exists -match $ns) {
            Write-Host "[OK] Namespace '$ns' exists" -ForegroundColor $successColor
        } else {
            Write-Host "[FAIL] Namespace '$ns' not found" -ForegroundColor $errorColor
            $allExist = $false
        }
    }
    return $allExist
}

function Test-Pods {
    Write-Host "`n[3/8] Checking pod status..." -ForegroundColor $infoColor
    Write-Host "`nAll Pods Status:" -ForegroundColor $infoColor
    kubectl get pods -A
    
    Write-Host "`nPod Health Summary:" -ForegroundColor $infoColor
    $namespaces = @("argocd", "monitoring", "harbor")
    $allHealthy = $true
    
    foreach ($ns in $namespaces) {
        Write-Host "`n--- $ns namespace ---" -ForegroundColor $infoColor
        $pods = kubectl get pods -n $ns --no-headers 2>&1
        if ($LASTEXITCODE -eq 0) {
            $running = ($pods | Select-String "Running").Count
            $pending = ($pods | Select-String "Pending|ContainerCreating|Init").Count
            $failed = ($pods | Select-String "Error|CrashLoopBackOff|ImagePullBackOff").Count
            
            Write-Host "  Running: $running" -ForegroundColor $(if ($running -gt 0) { $successColor } else { $errorColor })
            Write-Host "  Pending: $pending" -ForegroundColor $(if ($pending -eq 0) { $successColor } else { $infoColor })
            Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { $successColor } else { $errorColor })
            
            if ($failed -gt 0) {
                $allHealthy = $false
            }
        }
    }
    return $allHealthy
}

function Test-Services {
    Write-Host "`n[4/8] Checking services..." -ForegroundColor $infoColor
    Write-Host "`nKey Services:" -ForegroundColor $infoColor
    
    $services = @(
        @{Namespace="argocd"; Service="argocd-server"},
        @{Namespace="monitoring"; Service="prometheus"},
        @{Namespace="monitoring"; Service="grafana"},
        @{Namespace="monitoring"; Service="loki"},
        @{Namespace="harbor"; Service="harbor-core"}
    )
    
    $allExist = $true
    foreach ($svc in $services) {
        $result = kubectl get svc $svc.Service -n $svc.Namespace --ignore-not-found 2>&1
        if ($result -match $svc.Service) {
            Write-Host "[OK] $($svc.Namespace)/$($svc.Service)" -ForegroundColor $successColor
        } else {
            Write-Host "[FAIL] $($svc.Namespace)/$($svc.Service) not found" -ForegroundColor $errorColor
            $allExist = $false
        }
    }
    return $allExist
}

function Test-ArgoCD {
    Write-Host "`n[5/8] Testing ArgoCD..." -ForegroundColor $infoColor
    
    # Check if ArgoCD server is ready
    $serverReady = kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=10s 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] ArgoCD server is ready" -ForegroundColor $successColor
        
        # Get admin password
        Write-Host "`nArgoCD Admin Credentials:" -ForegroundColor $infoColor
        try {
            $password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>&1
            if ($password) {
                $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
                Write-Host "  Username: admin" -ForegroundColor $infoColor
                Write-Host "  Password: $decoded" -ForegroundColor $infoColor
            }
        } catch {
            Write-Host "  (Password not available yet)" -ForegroundColor $infoColor
        }
        
        return $true
    } else {
        Write-Host "[FAIL] ArgoCD server not ready" -ForegroundColor $errorColor
        return $false
    }
}

function Test-Monitoring {
    Write-Host "`n[6/8] Testing Monitoring Stack..." -ForegroundColor $infoColor
    
    $components = @("prometheus", "grafana", "loki", "alertmanager")
    $allReady = $true
    
    foreach ($comp in $components) {
        $pods = kubectl get pods -n monitoring -l app=$comp --no-headers 2>&1
        if ($pods -match "Running") {
            Write-Host "[OK] $comp is running" -ForegroundColor $successColor
        } else {
            Write-Host "[FAIL] $comp not running" -ForegroundColor $errorColor
            $allReady = $false
        }
    }
    
    return $allReady
}

function Test-Harbor {
    Write-Host "`n[7/8] Testing Harbor..." -ForegroundColor $infoColor
    
    $coreReady = kubectl wait --for=condition=ready pod -l app=harbor,component=core -n harbor --timeout=30s 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Harbor core is ready" -ForegroundColor $successColor
        Write-Host "  Admin Password: Harbor12345" -ForegroundColor $infoColor
        return $true
    } else {
        Write-Host "⚠ Harbor core still initializing (this may take several minutes)" -ForegroundColor $infoColor
        Write-Host "  Check status: kubectl get pods -n harbor" -ForegroundColor $infoColor
        return $false
    }
}

function Show-DemoInstructions {
    Write-Host "`n[8/8] Demo Instructions" -ForegroundColor $infoColor
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "=== ArgoCD UI ===" -ForegroundColor Yellow
    Write-Host "1. Port-forward ArgoCD:" -ForegroundColor White
    Write-Host "   kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Access in browser:" -ForegroundColor White
    Write-Host "   https://localhost:8080" -ForegroundColor Gray
    Write-Host "   Username: admin" -ForegroundColor Gray
    Write-Host "   Password: (get with command below)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Get admin password:" -ForegroundColor White
    Write-Host '   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }' -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "=== Grafana Dashboard ===" -ForegroundColor Yellow
    Write-Host "1. Port-forward Grafana:" -ForegroundColor White
    Write-Host "   kubectl port-forward svc/grafana -n monitoring 3000:3000" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Access in browser:" -ForegroundColor White
    Write-Host "   http://localhost:3000" -ForegroundColor Gray
    Write-Host "   Username: admin" -ForegroundColor Gray
    Write-Host "   Password: admin123" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "=== Prometheus ===" -ForegroundColor Yellow
    Write-Host "1. Port-forward Prometheus:" -ForegroundColor White
    Write-Host "   kubectl port-forward svc/prometheus -n monitoring 9090:9090" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Access in browser:" -ForegroundColor White
    Write-Host "   http://localhost:9090" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "=== Harbor Registry ===" -ForegroundColor Yellow
    Write-Host "1. Port-forward Harbor:" -ForegroundColor White
    Write-Host "   kubectl port-forward svc/harbor-core -n harbor 8080:80" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Access in browser:" -ForegroundColor White
    Write-Host "   http://localhost:8080" -ForegroundColor Gray
    Write-Host "   Username: admin" -ForegroundColor Gray
    Write-Host "   Password: Harbor12345" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "=== Quick Status Check ===" -ForegroundColor Yellow
    Write-Host "kubectl get pods -A" -ForegroundColor Gray
    Write-Host "kubectl get svc -A" -ForegroundColor Gray
    Write-Host ""
}

# Main Execution
Write-Host "Starting comprehensive test..." -ForegroundColor Cyan
Write-Host ""

$results = @{
    Kubectl = Test-KubectlConnection
    Namespaces = Test-Namespaces
    Pods = Test-Pods
    Services = Test-Services
    ArgoCD = Test-ArgoCD
    Monitoring = Test-Monitoring
    Harbor = Test-Harbor
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

foreach ($test in $results.GetEnumerator()) {
    $status = if ($test.Value) { "PASS" } else { "FAIL/WARN" }
    $color = if ($test.Value) { $successColor } else { $errorColor }
    Write-Host "$($test.Key): $status" -ForegroundColor $color
}

$passed = ($results.Values | Where-Object { $_ -eq $true }).Count
$total = $results.Count
Write-Host "`nTotal: $passed/$total tests passed" -ForegroundColor $(if ($passed -eq $total) { $successColor } else { $infoColor })

Show-DemoInstructions

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

