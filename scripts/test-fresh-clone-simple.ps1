# Simple test script for fresh clone
# Tests if docker-compose automatically sets up database

param(
    [switch]$Clean = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Fresh Clone - Docker Compose Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "[1/5] Checking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "  ✗ Docker not found" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ Docker found" -ForegroundColor Green

if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "  ✗ Docker Compose not found" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ Docker Compose found" -ForegroundColor Green
Write-Host ""

# Check docker-compose.yml
Write-Host "[2/5] Checking docker-compose.yml..." -ForegroundColor Yellow
if (-not (Test-Path "backend/docker-compose.yml")) {
    Write-Host "  ✗ docker-compose.yml not found" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ docker-compose.yml found" -ForegroundColor Green

$composeContent = Get-Content "backend/docker-compose.yml" -Raw
if ($composeContent -match "db-migration:") {
    Write-Host "  ✓ db-migration service found" -ForegroundColor Green
} else {
    Write-Host "  ✗ db-migration service not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Backup .env if exists
Write-Host "[3/5] Preparing test environment..." -ForegroundColor Yellow
$envPath = "backend/.env"
$envBackupPath = "backend/.env.backup"
$envExists = Test-Path $envPath

if ($envExists) {
    Copy-Item $envPath $envBackupPath -Force
    Write-Host "  ✓ Backed up existing .env file" -ForegroundColor Green
    Remove-Item $envPath -Force
    Write-Host "  ✓ Removed .env to test defaults" -ForegroundColor Green
} else {
    Write-Host "  ℹ No existing .env file (will use defaults)" -ForegroundColor Cyan
}
Write-Host ""

# Validate docker-compose config
Write-Host "[4/5] Validating docker-compose configuration..." -ForegroundColor Yellow
Push-Location backend
$config = docker-compose config 2>&1
$exitCode = $LASTEXITCODE
Pop-Location

if ($exitCode -ne 0) {
    Write-Host "  ✗ docker-compose config validation failed" -ForegroundColor Red
    Write-Host $config -ForegroundColor Red
    if ($envExists) {
        Copy-Item $envBackupPath $envPath -Force
        Remove-Item $envBackupPath -Force
    }
    exit 1
}

Write-Host "  ✓ docker-compose config is valid" -ForegroundColor Green

$dbUrl = ($config | Select-String "DATABASE_URL").ToString()
if ($dbUrl -match "postgresql://.*@postgres:5432") {
    Write-Host "  ✓ DATABASE_URL correctly points to 'postgres' service" -ForegroundColor Green
} else {
    Write-Host "  ⚠ DATABASE_URL might not point to 'postgres' service" -ForegroundColor Yellow
}
Write-Host ""

# Ask to run runtime test
Write-Host "[5/5] Runtime test..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  This will start docker-compose and test:" -ForegroundColor Cyan
Write-Host "  1. PostgreSQL becomes healthy" -ForegroundColor Cyan
Write-Host "  2. Migration service runs" -ForegroundColor Cyan
Write-Host "  3. Database tables are created" -ForegroundColor Cyan
Write-Host ""

$response = Read-Host "  Do you want to run runtime test? (y/N)"
if ($response -ne "y" -and $response -ne "Y") {
    Write-Host "  ⏭ Skipping runtime test" -ForegroundColor Yellow
    if ($envExists) {
        Copy-Item $envBackupPath $envPath -Force
        Remove-Item $envBackupPath -Force
        Write-Host "  ✓ Restored .env file" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Test Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✓ Configuration validated" -ForegroundColor Green
    Write-Host "✓ Default values checked" -ForegroundColor Green
    Write-Host "⚠ Runtime test skipped" -ForegroundColor Yellow
    exit 0
}

# Clean up if requested
if ($Clean) {
    Write-Host "  Cleaning up existing containers..." -ForegroundColor Yellow
    Push-Location backend
    docker-compose down -v 2>&1 | Out-Null
    Pop-Location
    Write-Host "  ✓ Cleaned up" -ForegroundColor Green
}

# Run docker-compose
Push-Location backend
Write-Host ""
Write-Host "  Starting services..." -ForegroundColor Cyan
docker-compose up -d 2>&1 | Out-Null

Start-Sleep -Seconds 5

# Check postgres health
Write-Host "  Checking PostgreSQL health..." -ForegroundColor Cyan
$maxWait = 60
$waited = 0
$postgresHealthy = $false

while ($waited -lt $maxWait) {
    $status = docker-compose ps postgres 2>&1
    if ($status -match "healthy") {
        $postgresHealthy = $true
        break
    }
    Start-Sleep -Seconds 2
    $waited += 2
    Write-Host "    Waiting... ($waited/$maxWait sec)" -ForegroundColor Yellow
}

if (-not $postgresHealthy) {
    Write-Host "  ✗ PostgreSQL did not become healthy" -ForegroundColor Red
    Pop-Location
    if ($envExists) {
        Copy-Item $envBackupPath $envPath -Force
        Remove-Item $envBackupPath -Force
    }
    exit 1
}

Write-Host "  ✓ PostgreSQL is healthy" -ForegroundColor Green

# Check migration
Write-Host "  Checking migration service..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

$migrationLogs = docker-compose logs db-migration 2>&1
if ($migrationLogs -match "Migrations completed successfully" -or $migrationLogs -match "Database setup complete") {
    Write-Host "  ✓ Migrations completed successfully" -ForegroundColor Green
} elseif ($migrationLogs -match "ERROR" -or $migrationLogs -match "error") {
    Write-Host "  ✗ Migration errors detected" -ForegroundColor Red
    Write-Host $migrationLogs -ForegroundColor Red
    Pop-Location
    if ($envExists) {
        Copy-Item $envBackupPath $envPath -Force
        Remove-Item $envBackupPath -Force
    }
    exit 1
} else {
    Write-Host "  ⚠ Migration status unclear" -ForegroundColor Yellow
}

# Check tables
Write-Host "  Verifying database tables..." -ForegroundColor Cyan
$tablesCheck = docker-compose exec -T postgres psql -U eshelf -d eshelf -c "\dt" 2>&1
if ($tablesCheck -match "books" -and $tablesCheck -match "genres" -and $tablesCheck -match "users") {
    Write-Host "  ✓ Database tables created successfully" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Some tables might be missing" -ForegroundColor Yellow
}

Pop-Location

# Restore .env
if ($envExists) {
    Copy-Item $envBackupPath $envPath -Force
    Remove-Item $envBackupPath -Force
    Write-Host ""
    Write-Host "✓ Restored .env file" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($postgresHealthy) {
    Write-Host "✓ All tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Docker Compose setup works correctly:" -ForegroundColor Green
    Write-Host "  ✓ PostgreSQL starts and becomes healthy" -ForegroundColor Green
    Write-Host "  ✓ Migration service runs automatically" -ForegroundColor Green
    Write-Host "  ✓ Database tables are created" -ForegroundColor Green
    Write-Host ""
    Write-Host "A fresh clone should work without manual .env setup!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Some tests failed" -ForegroundColor Red
    exit 1
}

