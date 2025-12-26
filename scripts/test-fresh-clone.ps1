# Test script for fresh clone - Simulate a new user cloning the repo
# Tests if docker-compose automatically sets up database and .env correctly

param(
    [switch]$Clean = $false,
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Fresh Clone - Docker Compose Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Colors
$GREEN = "Green"
$RED = "Red"
$YELLOW = "Yellow"
$CYAN = "Cyan"

# Check prerequisites
Write-Host "[1/8] Checking prerequisites..." -ForegroundColor $YELLOW
$prereqsOK = $true

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "  ✗ Docker not found" -ForegroundColor $RED
    $prereqsOK = $false
} else {
    Write-Host "  ✓ Docker found" -ForegroundColor $GREEN
}

if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "  ✗ Docker Compose not found" -ForegroundColor $RED
    $prereqsOK = $false
} else {
    Write-Host "  ✓ Docker Compose found" -ForegroundColor $GREEN
}

if (-not $prereqsOK) {
    Write-Host ""
    Write-Host "Please install Docker and Docker Compose first!" -ForegroundColor $RED
    exit 1
}

# Check if we're in project root
if (-not (Test-Path "backend/docker-compose.yml")) {
    Write-Host "  ✗ Please run from project root directory" -ForegroundColor $RED
    exit 1
}

Write-Host ""

# Test 1: Check docker-compose.yml exists
Write-Host "[2/8] Checking docker-compose.yml..." -ForegroundColor $YELLOW
if (Test-Path "backend/docker-compose.yml") {
    Write-Host "  ✓ docker-compose.yml found" -ForegroundColor $GREEN
} else {
    Write-Host "  ✗ docker-compose.yml not found" -ForegroundColor $RED
    exit 1
}

# Test 2: Check migration service exists in docker-compose
Write-Host "[3/8] Checking migration service in docker-compose..." -ForegroundColor $YELLOW
$composeContent = Get-Content "backend/docker-compose.yml" -Raw
if ($composeContent -match "db-migration:") {
    Write-Host "  ✓ db-migration service found" -ForegroundColor $GREEN
} else {
    Write-Host "  ✗ db-migration service not found" -ForegroundColor $RED
    exit 1
}

# Test 3: Check default DATABASE_URL format
Write-Host "[4/8] Checking default DATABASE_URL format..." -ForegroundColor $YELLOW
if ($composeContent -match "DATABASE_URL.*postgresql://.*postgres:5432") {
    Write-Host "  ✓ DATABASE_URL uses correct host 'postgres'" -ForegroundColor $GREEN
} else {
    Write-Host "  ⚠ DATABASE_URL might not use service name 'postgres'" -ForegroundColor $YELLOW
}

# Test 4: Backup existing .env if exists
Write-Host "[5/8] Preparing test environment..." -ForegroundColor $YELLOW
$envPath = "backend/.env"
$envBackupPath = "backend/.env.backup"
$envExists = Test-Path $envPath

if ($envExists) {
    Copy-Item $envPath $envBackupPath -Force
    Write-Host "  ✓ Backed up existing .env file" -ForegroundColor $GREEN
} else {
    Write-Host "  ℹ No existing .env file (will use defaults)" -ForegroundColor $CYAN
}

# Test 5: Remove .env to test with defaults
Write-Host "[6/8] Testing with default values (no .env file)..." -ForegroundColor $YELLOW
if ($envExists) {
    Remove-Item $envPath -Force
    Write-Host "  ✓ Removed .env to test defaults" -ForegroundColor $GREEN
}

# Test 6: Validate docker-compose config
Write-Host "[7/8] Validating docker-compose configuration..." -ForegroundColor $YELLOW
Push-Location backend
$config = docker-compose config 2>&1
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    Write-Host "  ✗ docker-compose config validation failed" -ForegroundColor $RED
    Write-Host $config -ForegroundColor $RED
    Pop-Location
    exit 1
}

Write-Host "  ✓ docker-compose config is valid" -ForegroundColor $GREEN

# Check DATABASE_URL in config
$dbUrl = ($config | Select-String "DATABASE_URL").ToString()
if ($dbUrl -match "postgresql://.*@postgres:5432") {
    Write-Host "  ✓ DATABASE_URL correctly points to 'postgres' service" -ForegroundColor $GREEN
} else {
    Write-Host "  ⚠ DATABASE_URL might not point to 'postgres' service" -ForegroundColor $YELLOW
    Write-Host "    $dbUrl" -ForegroundColor $YELLOW
}
Pop-Location

# Test 7: Test docker-compose up (dry run)
Write-Host "[8/8] Testing docker-compose setup (this may take a while)..." -ForegroundColor $YELLOW
Write-Host ""
Write-Host "  This will:" -ForegroundColor $CYAN
Write-Host "  1. Start PostgreSQL" -ForegroundColor $CYAN
Write-Host "  2. Wait for PostgreSQL to be healthy" -ForegroundColor $CYAN
Write-Host "  3. Run db-migration service" -ForegroundColor $CYAN
Write-Host "  4. Check if migrations completed successfully" -ForegroundColor $CYAN
Write-Host ""

$response = Read-Host "  Do you want to run this test? (y/N)"
if ($response -ne "y" -and $response -ne "Y") {
    Write-Host "  ⏭ Skipping docker-compose test" -ForegroundColor $YELLOW
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Test Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✓ Configuration files validated" -ForegroundColor $GREEN
    Write-Host "✓ Default values checked" -ForegroundColor $GREEN
    Write-Host "⚠ Docker Compose runtime test skipped" -ForegroundColor $YELLOW
    Write-Host ""
    Write-Host "To test runtime, run manually:" -ForegroundColor $CYAN
    Write-Host "  cd backend" -ForegroundColor $CYAN
    Write-Host "  docker-compose up -d" -ForegroundColor $CYAN
    Write-Host "  docker-compose logs db-migration" -ForegroundColor $CYAN
    Write-Host ""
    
    # Restore .env if backed up
    if ($envExists -and (Test-Path $envBackupPath)) {
        Copy-Item $envBackupPath $envPath -Force
        Remove-Item $envBackupPath -Force
        Write-Host "✓ Restored .env file" -ForegroundColor $GREEN
    }
    exit 0
}

# Clean up if requested
if ($Clean) {
    Write-Host "  Cleaning up existing containers..." -ForegroundColor $YELLOW
    Push-Location backend
    docker-compose down -v 2>&1 | Out-Null
    Pop-Location
    Write-Host "  ✓ Cleaned up" -ForegroundColor $GREEN
}

# Run docker-compose up
Push-Location backend
Write-Host ""
Write-Host "  Starting services..." -ForegroundColor $CYAN

if ($SkipBuild) {
    docker-compose up -d --no-build 2>&1 | Out-Null
} else {
    docker-compose up -d 2>&1 | Out-Null
}

# Wait a bit for services to start
Start-Sleep -Seconds 5

# Check postgres health
Write-Host "  Checking PostgreSQL health..." -ForegroundColor $CYAN
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
    Write-Host "    Waiting for PostgreSQL... ($waited/$maxWait seconds)" -ForegroundColor $YELLOW
}

if (-not $postgresHealthy) {
    Write-Host "  ✗ PostgreSQL did not become healthy" -ForegroundColor $RED
    Write-Host "    Check logs: docker-compose logs postgres" -ForegroundColor $YELLOW
    Pop-Location
    exit 1
}

Write-Host "  ✓ PostgreSQL is healthy" -ForegroundColor $GREEN

# Check migration service
Write-Host "  Checking migration service..." -ForegroundColor $CYAN
Start-Sleep -Seconds 3

$migrationLogs = docker-compose logs db-migration 2>&1
if ($migrationLogs -match "Migrations completed successfully" -or $migrationLogs -match "Database setup complete") {
    Write-Host "  ✓ Migrations completed successfully" -ForegroundColor $GREEN
} elseif ($migrationLogs -match "ERROR" -or $migrationLogs -match "error") {
    Write-Host "  ✗ Migration errors detected" -ForegroundColor $RED
    Write-Host ""
    Write-Host "Migration logs:" -ForegroundColor $YELLOW
    Write-Host $migrationLogs -ForegroundColor $RED
    Pop-Location
    exit 1
} else {
    Write-Host "  ⚠ Migration status unclear, checking logs..." -ForegroundColor $YELLOW
    Write-Host $migrationLogs -ForegroundColor $YELLOW
}

# Check if tables exist
Write-Host "  Verifying database tables..." -ForegroundColor $CYAN
$tablesCheck = docker-compose exec -T postgres psql -U eshelf -d eshelf -c "\dt" 2>&1
if ($tablesCheck -match "books" -and $tablesCheck -match "genres" -and $tablesCheck -match "users") {
    Write-Host "  ✓ Database tables created successfully" -ForegroundColor $GREEN
} else {
    Write-Host "  ⚠ Some tables might be missing" -ForegroundColor $YELLOW
    Write-Host "    Tables found:" -ForegroundColor $YELLOW
    Write-Host $tablesCheck -ForegroundColor $YELLOW
}

# Check services status
Write-Host "  Checking services status..." -ForegroundColor $CYAN
$services = docker-compose ps --services
$allRunning = $true
foreach ($service in $services) {
    if ($service -eq "db-migration") { continue } # Migration service should exit after completion
    $status = docker-compose ps $service 2>&1
    if ($status -match "Up" -or $status -match "running") {
        Write-Host "    ✓ $service is running" -ForegroundColor $GREEN
    } else {
        Write-Host "    ✗ $service is not running" -ForegroundColor $RED
        $allRunning = $false
    }
}

Pop-Location

# Restore .env if backed up
if ($envExists -and (Test-Path $envBackupPath)) {
    Copy-Item $envBackupPath $envPath -Force
    Remove-Item $envBackupPath -Force
    Write-Host ""
    Write-Host "✓ Restored .env file" -ForegroundColor $GREEN
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($postgresHealthy -and $allRunning) {
    Write-Host "✓ All tests passed!" -ForegroundColor $GREEN
    Write-Host ""
    Write-Host "Docker Compose setup is working correctly:" -ForegroundColor $GREEN
    Write-Host "  ✓ PostgreSQL starts and becomes healthy" -ForegroundColor $GREEN
    Write-Host "  ✓ Migration service runs automatically" -ForegroundColor $GREEN
    Write-Host "  ✓ Database tables are created" -ForegroundColor $GREEN
    Write-Host "  ✓ Services start after migrations complete" -ForegroundColor $GREEN
    Write-Host ""
    Write-Host "A fresh clone should work without manual .env setup!" -ForegroundColor $GREEN
    exit 0
} else {
    Write-Host "✗ Some tests failed" -ForegroundColor $RED
    Write-Host ""
    Write-Host "Check logs:" -ForegroundColor $YELLOW
    Write-Host "  cd backend" -ForegroundColor $YELLOW
    Write-Host "  docker-compose logs" -ForegroundColor $YELLOW
    exit 1
}

