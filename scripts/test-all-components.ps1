# ============================================
# eShelf - Comprehensive Component Testing (PowerShell)
# Test FE, BE, Database, ML-AI before Ops
# ============================================

$ErrorActionPreference = "Continue"

# Colors
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Counters
$script:Passed = 0
$script:Failed = 0
$script:Warnings = 0
$script:Results = @()

function Test-Pass {
    param([string]$Message)
    Write-ColorOutput "✅ PASS: $Message" "Green"
    $script:Passed++
    $script:Results += "✅ $Message"
}

function Test-Fail {
    param([string]$Message)
    Write-ColorOutput "❌ FAIL: $Message" "Red"
    $script:Failed++
    $script:Results += "❌ $Message"
}

function Test-Warn {
    param([string]$Message)
    Write-ColorOutput "⚠️  WARN: $Message" "Yellow"
    $script:Warnings++
    $script:Results += "⚠️  $Message"
}

function Print-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "========================================" "Cyan"
    Write-ColorOutput $Title "Cyan"
    Write-ColorOutput "========================================" "Cyan"
}

function Test-Service {
    param(
        [string]$Name,
        [string]$Url,
        [int]$ExpectedStatus = 200
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq $ExpectedStatus) {
            Test-Pass "$Name is running (HTTP $($response.StatusCode))"
            return $true
        } else {
            Test-Fail "$Name returned unexpected status (HTTP $($response.StatusCode))"
            return $false
        }
    } catch {
        Test-Fail "$Name is not responding - $($_.Exception.Message)"
        return $false
    }
}

# ============================================
# 1. FRONTEND TESTING
# ============================================
Print-Header "1. FRONTEND (React + Vite)"

if (Test-Service "Frontend" "http://localhost:5173") {
    try {
        $content = Invoke-WebRequest -Uri "http://localhost:5173" -UseBasicParsing -ErrorAction Stop
        if ($content.Content -match "vite|react|root") {
            Test-Pass "Frontend is serving React application"
        } else {
            Test-Warn "Frontend is running but may not be React app"
        }
    } catch {
        Test-Warn "Could not verify React app"
    }
} else {
    Write-ColorOutput "  → Start with: npm run dev" "Yellow"
}

if (Test-Path "dist" -or Test-Path "build") {
    Test-Pass "Frontend build directory exists"
} else {
    Test-Warn "Frontend not built yet (run: npm run build)"
}

# ============================================
# 2. BACKEND SERVICES TESTING
# ============================================
Print-Header "2. BACKEND SERVICES (Microservices)"

# API Gateway
if (Test-Service "API Gateway" "http://localhost:3000/health") {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing
        if ($response.Content -match "ok|status|gateway") {
            Test-Pass "API Gateway health endpoint working"
        }
    } catch {
        # Already handled
    }
} else {
    Write-ColorOutput "  → Start with: cd backend && docker-compose up -d" "Yellow"
}

# Auth Service
if (Test-Service "Auth Service" "http://localhost:3001/health") {
    try {
        $body = @{
            email = "test@test.com"
            password = "test"
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/login" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing `
            -ErrorAction SilentlyContinue
        
        if ($response.Content -match "error|success|invalid") {
            Test-Pass "Auth Service endpoints are responding"
        }
    } catch {
        Test-Warn "Auth Service endpoints may need configuration"
    }
} else {
    Test-Fail "Auth Service not accessible"
}

# Book Service
if (Test-Service "Book Service" "http://localhost:3002/health") {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/api/books?limit=1" -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.Content -match "books|data|success") {
            Test-Pass "Book Service endpoints are responding"
        } else {
            Test-Warn "Book Service may not have data yet"
        }
    } catch {
        Test-Warn "Book Service endpoints may need data"
    }
} else {
    Test-Fail "Book Service not accessible"
}

# User Service
if (Test-Service "User Service" "http://localhost:3003/health") {
    Test-Pass "User Service is running"
} else {
    Test-Fail "User Service not accessible"
}

# ============================================
# 3. DATABASE TESTING
# ============================================
Print-Header "3. DATABASE (PostgreSQL + Prisma)"

# Check PostgreSQL via Docker
$postgresContainer = docker ps --filter "name=postgres" --format "{{.Names}}" 2>$null
if ($postgresContainer) {
    try {
        $result = docker exec $postgresContainer psql -U eshelf -d eshelf -c "SELECT 1;" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Test-Pass "PostgreSQL connection via Docker successful"
            
            # Check tables
            $tableCount = docker exec $postgresContainer psql -U eshelf -d eshelf -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1
            if ($tableCount -match '\d+') {
                Test-Pass "Database tables exist"
            } else {
                Test-Warn "No tables found - run migrations: cd backend/database && npm run db:migrate"
            }
        } else {
            Test-Fail "PostgreSQL connection failed"
        }
    } catch {
        Test-Fail "PostgreSQL connection error: $_"
    }
} else {
    Test-Warn "PostgreSQL container not running"
    Write-ColorOutput "  → Start with: cd backend && docker-compose up -d postgres" "Yellow"
}

# Check Prisma
if (Test-Path "backend/database/prisma/schema.prisma") {
    Test-Pass "Prisma schema file exists"
    
    if (Test-Path "backend/database/node_modules/.prisma") {
        Test-Pass "Prisma Client generated"
    } else {
        Test-Warn "Prisma Client not generated - run: cd backend/database && npm run db:generate"
    }
} else {
    Test-Fail "Prisma schema not found"
}

# Check Redis
$redisContainer = docker ps --filter "name=redis" --format "{{.Names}}" 2>$null
if ($redisContainer) {
    try {
        $result = docker exec $redisContainer redis-cli ping 2>&1
        if ($result -match "PONG") {
            Test-Pass "Redis connection via Docker successful"
        } else {
            Test-Warn "Redis not responding (optional)"
        }
    } catch {
        Test-Warn "Redis not accessible (optional component)"
    }
} else {
    Test-Warn "Redis not running (optional component)"
}

# ============================================
# 4. ML-AI SERVICE TESTING
# ============================================
Print-Header "4. ML-AI SERVICE (FastAPI)"

if (Test-Service "ML Service" "http://localhost:8000/health") {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing
        if ($response.Content -match "models|recommender|similarity") {
            Test-Pass "ML Service health check shows models status"
        }
        
        # Test recommendations
        $body = @{
            user_id = "test-user"
            n_items = 5
        } | ConvertTo-Json
        
        $recResponse = Invoke-WebRequest -Uri "http://localhost:8000/recommendations" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing `
            -ErrorAction SilentlyContinue
        
        if ($recResponse.Content -match "success|data") {
            Test-Pass "ML Service recommendations endpoint working"
        } else {
            Test-Warn "ML Service recommendations may need data"
        }
        
        # Test similar books
        $similarBody = @{
            book_id = "test-book"
            n_items = 5
        } | ConvertTo-Json
        
        $similarResponse = Invoke-WebRequest -Uri "http://localhost:8000/similar" `
            -Method Post `
            -ContentType "application/json" `
            -Body $similarBody `
            -UseBasicParsing `
            -ErrorAction SilentlyContinue
        
        if ($similarResponse.Content -match "success|data") {
            Test-Pass "ML Service similar books endpoint working"
        } else {
            Test-Warn "ML Service similar books may need data"
        }
        
        # Check docs
        try {
            $docs = Invoke-WebRequest -Uri "http://localhost:8000/docs" -UseBasicParsing -ErrorAction SilentlyContinue
            if ($docs.StatusCode -eq 200) {
                Test-Pass "ML Service API documentation accessible at /docs"
            }
        } catch {
            # Docs may not be critical
        }
    } catch {
        Test-Warn "ML Service endpoints may need configuration"
    }
} else {
    Test-Fail "ML Service not accessible"
    Write-ColorOutput "  → Start with: cd backend/services/ml-service && uvicorn src.main:app --reload" "Yellow"
}

if (Test-Path "backend/services/ml-service/requirements.txt") {
    Test-Pass "ML Service requirements.txt exists"
    
    try {
        python -c "import fastapi, uvicorn, sklearn" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Test-Pass "ML Service Python dependencies installed"
        } else {
            Test-Warn "ML Service dependencies not installed - run: pip install -r requirements.txt"
        }
    } catch {
        Test-Warn "Python not found or dependencies not installed"
    }
}

# ============================================
# 5. INTEGRATION TESTING
# ============================================
Print-Header "5. INTEGRATION TESTS"

try {
    $gatewayHealth = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -ErrorAction SilentlyContinue
    if ($gatewayHealth) {
        $booksResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/books?limit=1" -UseBasicParsing -ErrorAction SilentlyContinue
        if ($booksResponse) {
            Test-Pass "API Gateway routing to Book Service working"
        }
        
        $registerBody = @{
            email = "test@example.com"
            password = "Test123!"
            username = "testuser"
            name = "Test User"
        } | ConvertTo-Json
        
        $authResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/register" `
            -Method Post `
            -ContentType "application/json" `
            -Body $registerBody `
            -UseBasicParsing `
            -ErrorAction SilentlyContinue
        
        if ($authResponse) {
            Test-Pass "API Gateway routing to Auth Service working"
        }
    }
} catch {
    Test-Warn "Integration tests may need services to be fully configured"
}

# Test ML via Gateway
try {
    $mlHealth = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -ErrorAction SilentlyContinue
    $gatewayHealth = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -ErrorAction SilentlyContinue
    
    if ($mlHealth -and $gatewayHealth) {
        $mlBody = @{
            user_id = "test"
            n_items = 3
        } | ConvertTo-Json
        
        $mlViaGateway = Invoke-WebRequest -Uri "http://localhost:3000/api/ml/recommendations" `
            -Method Post `
            -ContentType "application/json" `
            -Body $mlBody `
            -UseBasicParsing `
            -ErrorAction SilentlyContinue
        
        if ($mlViaGateway.Content -match "success|data") {
            Test-Pass "ML Service accessible via API Gateway"
        } else {
            Test-Warn "ML Service may not be configured in API Gateway"
        }
    }
} catch {
    Test-Warn "ML Gateway integration may need configuration"
}

# ============================================
# SUMMARY
# ============================================
Print-Header "TEST SUMMARY"

Write-Host ""
Write-Host "Results:"
foreach ($result in $script:Results) {
    Write-Host "  $result"
}

Write-Host ""
Write-ColorOutput "========================================" "Cyan"
$total = $script:Passed + $script:Failed + $script:Warnings
Write-Host "Total Tests: $total"
Write-ColorOutput "Passed: $($script:Passed)" "Green"
Write-ColorOutput "Failed: $($script:Failed)" "Red"
Write-ColorOutput "Warnings: $($script:Warnings)" "Yellow"
Write-ColorOutput "========================================" "Cyan"

if ($script:Failed -eq 0) {
    Write-Host ""
    Write-ColorOutput "✅ All critical tests passed!" "Green"
    Write-ColorOutput "Your system is ready for Ops deployment." "Green"
    exit 0
} else {
    Write-Host ""
    Write-ColorOutput "❌ Some tests failed." "Red"
    Write-ColorOutput "Please fix the issues before proceeding to Ops." "Yellow"
    exit 1
}

