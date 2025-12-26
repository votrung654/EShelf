# Script tự động build và push images lên Harbor
# Sử dụng khi có Docker images sẵn hoặc build từ source

param(
    [string]$Service = "all",
    [string]$Tag = "dev",
    [string]$HarborHost = "localhost:8080"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Push Images to Harbor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Docker not found. Please install Docker Desktop." -ForegroundColor Red
    exit 1
}

# Kiểm tra port-forward
Write-Host "Checking Harbor connection..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$HarborHost/api/v2.0/health" -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host "[OK] Harbor is accessible at http://$HarborHost" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Cannot connect to Harbor at http://$HarborHost" -ForegroundColor Yellow
    Write-Host "Please start port-forward first:" -ForegroundColor Yellow
    Write-Host "  kubectl port-forward svc/harbor-core -n harbor 8080:80" -ForegroundColor Cyan
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

# Login to Harbor
Write-Host "`nLogging in to Harbor..." -ForegroundColor Yellow
$harborUser = "admin"
$harborPass = "Harbor12345"

$loginResult = docker login $HarborHost -u $harborUser -p $harborPass 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to login to Harbor" -ForegroundColor Red
    Write-Host $loginResult -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Logged in to Harbor" -ForegroundColor Green

# Services to build
$services = @()
if ($Service -eq "all") {
    $services = @("api-gateway", "auth-service", "book-service", "user-service", "ml-service")
} else {
    $services = @($Service)
}

foreach ($svc in $services) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Processing: $svc" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Build image
    Write-Host "Building image..." -ForegroundColor Yellow
    $dockerfilePath = ""
    $buildContext = ""
    
    if ($svc -eq "user-service") {
        $dockerfilePath = "backend/services/user-service/Dockerfile"
        $buildContext = "backend"
    } elseif ($svc -eq "ml-service") {
        $dockerfilePath = "backend/services/ml-service/Dockerfile"
        $buildContext = "backend/services/ml-service"
    } else {
        $dockerfilePath = "backend/services/$svc/Dockerfile"
        $buildContext = "backend/services/$svc"
    }
    
    if (-not (Test-Path $dockerfilePath)) {
        Write-Host "[WARN] Dockerfile not found: $dockerfilePath" -ForegroundColor Yellow
        Write-Host "Skipping $svc..." -ForegroundColor Yellow
        continue
    }
    
    $imageName = "$HarborHost/eshelf/$svc"
    $imageTag = "$imageName`:$Tag"
    $imageLatest = "$imageName`:latest"
    
    # Build
    if ($svc -eq "user-service") {
        docker build -f $dockerfilePath -t $imageTag -t $imageLatest $buildContext
    } else {
        docker build -t $imageTag -t $imageLatest $buildContext
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to build $svc" -ForegroundColor Red
        continue
    }
    
    Write-Host "[OK] Image built: $imageTag" -ForegroundColor Green
    
    # Push
    Write-Host "Pushing image..." -ForegroundColor Yellow
    docker push $imageTag
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to push $imageTag" -ForegroundColor Red
        continue
    }
    
    docker push $imageLatest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] Failed to push $imageLatest" -ForegroundColor Yellow
    } else {
        Write-Host "[OK] Image pushed: $imageTag and $imageLatest" -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify images in Harbor UI: http://$HarborHost" -ForegroundColor White
Write-Host "2. Scale up deployments:" -ForegroundColor White
Write-Host "   kubectl scale deployment -n eshelf-dev --all --replicas=1" -ForegroundColor Cyan

