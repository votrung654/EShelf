# Script to deploy Local Environment using Docker Compose
# Usage: .\scripts\deploy-local.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Local Environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# Check Docker
Write-Host "`n[1/5] Checking Docker..." -ForegroundColor Yellow
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Docker not found. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}

$dockerRunning = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Docker is running" -ForegroundColor Green

# Check Docker Compose
Write-Host "`n[2/5] Checking Docker Compose..." -ForegroundColor Yellow
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Docker Compose not found. Please install Docker Compose." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Docker Compose is available" -ForegroundColor Green

# Check if in correct directory
Write-Host "`n[3/5] Checking directory..." -ForegroundColor Yellow
if (-not (Test-Path "backend/docker-compose.yml")) {
    Write-Host "[ERROR] docker-compose.yml not found. Please run this script from project root." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Found docker-compose.yml" -ForegroundColor Green

# Check ports
Write-Host "`n[4/5] Checking ports..." -ForegroundColor Yellow
$ports = @(3000, 3001, 3002, 3003, 5432, 6379, 8000)
$portsInUse = @()

foreach ($port in $ports) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connection) {
        $portsInUse += $port
    }
}

if ($portsInUse.Count -gt 0) {
    Write-Host "[WARN] The following ports are already in use: $($portsInUse -join ', ')" -ForegroundColor Yellow
    Write-Host "       You may need to stop existing services or change ports." -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 0
    }
} else {
    Write-Host "[OK] All required ports are available" -ForegroundColor Green
}

# Deploy
Write-Host "`n[5/5] Deploying services..." -ForegroundColor Yellow
Set-Location backend

Write-Host "`nBuilding and starting containers..." -ForegroundColor Cyan
docker-compose up -d --build

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to start containers" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Set-Location ..

# Wait for services to be ready
Write-Host "`nWaiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check status
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deployment Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

docker-compose -f backend/docker-compose.yml ps

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Service URLs" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "API Gateway:    http://localhost:3000" -ForegroundColor Green
Write-Host "Auth Service:   http://localhost:3001" -ForegroundColor Green
Write-Host "Book Service:  http://localhost:3002" -ForegroundColor Green
Write-Host "User Service:  http://localhost:3003" -ForegroundColor Green
Write-Host "ML Service:    http://localhost:8000" -ForegroundColor Green
Write-Host "PostgreSQL:    localhost:5432" -ForegroundColor Green
Write-Host "Redis:         localhost:6379" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend:      http://localhost:5173 (run 'npm run dev' separately)" -ForegroundColor Yellow

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Useful Commands" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "View logs:     docker-compose -f backend/docker-compose.yml logs -f" -ForegroundColor Gray
Write-Host "Stop:          docker-compose -f backend/docker-compose.yml down" -ForegroundColor Gray
Write-Host "Restart:       docker-compose -f backend/docker-compose.yml restart" -ForegroundColor Gray
Write-Host "Remove all:    docker-compose -f backend/docker-compose.yml down -v" -ForegroundColor Gray

Write-Host "`n[OK] Local environment deployed successfully!" -ForegroundColor Green
Write-Host "`nNote: Don't forget to run 'npm run dev' in the root directory for the frontend." -ForegroundColor Yellow






