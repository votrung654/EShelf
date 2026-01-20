# Script to start eShelf microservices locally without Docker
# Usage: .\scripts\start-dev-local.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting eShelf Microservices (Local)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"

# Check Node.js
Write-Host "`n[1/6] Checking Node.js..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Node.js not found. Please install Node.js first." -ForegroundColor Red
    exit 1
}
$nodeVersion = node --version
Write-Host "[OK] Node.js $nodeVersion found" -ForegroundColor Green

# Check npm
Write-Host "`n[2/6] Checking npm..." -ForegroundColor Yellow
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] npm not found. Please install npm first." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] npm is available" -ForegroundColor Green

# Check Python (for ML service)
Write-Host "`n[3/6] Checking Python..." -ForegroundColor Yellow
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "[WARN] Python not found. ML Service will not start." -ForegroundColor Yellow
    $skipML = $true
} else {
    $pythonVersion = python --version
    Write-Host "[OK] $pythonVersion found" -ForegroundColor Green
    $skipML = $false
}

# Check ports
Write-Host "`n[4/6] Checking ports..." -ForegroundColor Yellow
$ports = @(3000, 3001, 3002, 3003, 8000)
$portsInUse = @()

foreach ($port in $ports) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connection) {
        $portsInUse += $port
    }
}

if ($portsInUse.Count -gt 0) {
    Write-Host "[WARN] The following ports are already in use: $($portsInUse -join ', ')" -ForegroundColor Yellow
    Write-Host "       You may need to stop existing services." -ForegroundColor Yellow
}

# Store original location
$originalLocation = Get-Location

# Function to start a service
function Start-Service {
    param(
        [string]$ServiceName,
        [string]$ServicePath,
        [int]$Port,
        [string]$EnvVar = ""
    )
    
    Write-Host "`nStarting $ServiceName on port $Port..." -ForegroundColor Cyan
    
    Set-Location $ServicePath
    
    # Install dependencies if node_modules doesn't exist
    if (-not (Test-Path "node_modules")) {
        Write-Host "  Installing dependencies..." -ForegroundColor Gray
        npm install 2>&1 | Out-Null
    }
    
    # Start service in background
    $env:PORT = $Port
    if ($EnvVar) {
        Invoke-Expression $EnvVar
    }
    
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ServicePath'; `$env:PORT=$Port; $EnvVar; npm run dev" -WindowStyle Minimized
    
    Set-Location $originalLocation
    Start-Sleep -Seconds 2
}

# Start API Gateway
Write-Host "`n[5/6] Starting services..." -ForegroundColor Yellow
Start-Service -ServiceName "API Gateway" -ServicePath "backend\services\api-gateway" -Port 3000

# Start Auth Service
Start-Service -ServiceName "Auth Service" -ServicePath "backend\services\auth-service" -Port 3001

# Start Book Service
Start-Service -ServiceName "Book Service" -ServicePath "backend\services\book-service" -Port 3002

# Start User Service
Start-Service -ServiceName "User Service" -ServicePath "backend\services\user-service" -Port 3003

# Start ML Service
if (-not $skipML) {
    Write-Host "`nStarting ML Service on port 8000..." -ForegroundColor Cyan
    Set-Location "backend\services\ml-service"
    
    # Check if virtual environment exists
    if (-not (Test-Path "venv")) {
        Write-Host "  Creating virtual environment..." -ForegroundColor Gray
        python -m venv venv
    }
    
    # Activate virtual environment and install dependencies
    Write-Host "  Installing dependencies..." -ForegroundColor Gray
    & ".\venv\Scripts\Activate.ps1"
    pip install -r requirements.txt 2>&1 | Out-Null
    
    # Start ML service
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$((Get-Location).Path)'; .\venv\Scripts\Activate.ps1; uvicorn src.main:app --host 0.0.0.0 --port 8000" -WindowStyle Minimized
    
    Set-Location $originalLocation
    Start-Sleep -Seconds 2
}

# Wait a bit for services to start
Write-Host "`n[6/6] Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Display status
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Services Started" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "API Gateway:    http://localhost:3000" -ForegroundColor Green
Write-Host "Auth Service:   http://localhost:3001" -ForegroundColor Green
Write-Host "Book Service:  http://localhost:3002" -ForegroundColor Green
Write-Host "User Service:  http://localhost:3003" -ForegroundColor Green
if (-not $skipML) {
    Write-Host "ML Service:    http://localhost:8000" -ForegroundColor Green
    Write-Host "ML API Docs:   http://localhost:8000/docs" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Note" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Each service is running in a separate PowerShell window." -ForegroundColor Yellow
Write-Host "Close those windows to stop the services." -ForegroundColor Yellow
Write-Host "`nTo start the frontend, run: npm run dev" -ForegroundColor Yellow
Write-Host "`n[OK] All services started!" -ForegroundColor Green

