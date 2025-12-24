# Script kiểm tra setup biến môi trường
# Chạy: .\scripts\test-env-setup.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kiểm tra Setup Biến Môi Trường" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()

# 1. Kiểm tra file .env.example
Write-Host "[1/6] Kiểm tra file .env.example..." -ForegroundColor Yellow
if (Test-Path ".env.example") {
    Write-Host "  ✓ File .env.example tồn tại" -ForegroundColor Green
} else {
    $errors += "File .env.example khong ton tai"
    Write-Host "  ✗ File .env.example không tồn tại" -ForegroundColor Red
}

if (Test-Path "backend\.env.example") {
    Write-Host "  ✓ File backend/.env.example tồn tại" -ForegroundColor Green
} else {
    $warnings += "File backend/.env.example khong ton tai (khong bat buoc)"
    Write-Host "  ⚠ File backend/.env.example không tồn tại" -ForegroundColor Yellow
}

# 2. Kiểm tra file .env (không nên commit)
Write-Host ""
Write-Host "[2/6] Kiểm tra file .env (không nên commit)..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "  ✓ File .env tồn tại (local only)" -ForegroundColor Green
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match "your-secret-key-change-in-production") {
        $warnings += "JWT_SECRET vẫn là giá trị mặc định - nên thay đổi cho production"
        Write-Host "  ⚠ JWT_SECRET vẫn là giá trị mặc định" -ForegroundColor Yellow
    }
    if ($envContent -match "eshelf123") {
        $warnings += "POSTGRES_PASSWORD vẫn là giá trị mặc định - nên thay đổi cho production"
        Write-Host "  ⚠ POSTGRES_PASSWORD vẫn là giá trị mặc định" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ℹ File .env chưa tồn tại (tạo từ .env.example)" -ForegroundColor Cyan
}

# 3. Kiểm tra .gitignore
Write-Host ""
Write-Host "[3/6] Kiểm tra .gitignore..." -ForegroundColor Yellow
if (Test-Path ".gitignore") {
    $gitignore = Get-Content ".gitignore" -Raw
    if ($gitignore -match "\.env[^.]") {
        Write-Host "  ✓ .env đã được ignore" -ForegroundColor Green
    } else {
        $errors += ".env chưa được thêm vào .gitignore"
        Write-Host "  ✗ .env chưa được thêm vào .gitignore" -ForegroundColor Red
    }
    if ($gitignore -match "aws-academy-credentials\.txt") {
        Write-Host "  ✓ aws-academy-credentials.txt đã được ignore" -ForegroundColor Green
    } else {
        $warnings += "aws-academy-credentials.txt chưa được thêm vào .gitignore"
        Write-Host "  ⚠ aws-academy-credentials.txt chưa được ignore" -ForegroundColor Yellow
    }
} else {
    $errors += "File .gitignore khong ton tai"
    Write-Host "  ✗ File .gitignore không tồn tại" -ForegroundColor Red
}

# 4. Kiểm tra docker-compose.yml
Write-Host ""
Write-Host "[4/6] Kiểm tra docker-compose.yml..." -ForegroundColor Yellow
if (Test-Path "backend\docker-compose.yml") {
    $dockerCompose = Get-Content "backend\docker-compose.yml" -Raw
    if ($dockerCompose -match '\$\{POSTGRES_PASSWORD') {
        Write-Host "  ✓ POSTGRES_PASSWORD sử dụng biến môi trường" -ForegroundColor Green
    } else {
        if ($dockerCompose -match "eshelf123") {
            $warnings += "docker-compose.yml vẫn có hardcoded password"
            Write-Host "  ⚠ docker-compose.yml vẫn có hardcoded password" -ForegroundColor Yellow
        }
    }
    if ($dockerCompose -match '\$\{DATABASE_URL') {
        Write-Host "  ✓ DATABASE_URL sử dụng biến môi trường" -ForegroundColor Green
    } else {
        if ($dockerCompose -match "postgresql://eshelf:eshelf123") {
            $warnings += "docker-compose.yml vẫn có hardcoded DATABASE_URL"
            Write-Host "  ⚠ docker-compose.yml vẫn có hardcoded DATABASE_URL" -ForegroundColor Yellow
        }
    }
    if ($dockerCompose -match '\$\{JWT_SECRET\}') {
        Write-Host "  ✓ JWT_SECRET sử dụng biến môi trường" -ForegroundColor Green
    } else {
        $warnings += "docker-compose.yml vẫn có hardcoded JWT_SECRET"
        Write-Host "  ⚠ docker-compose.yml vẫn có hardcoded JWT_SECRET" -ForegroundColor Yellow
    }
} else {
    $warnings += "File backend/docker-compose.yml không tồn tại"
    Write-Host "  ⚠ File backend/docker-compose.yml không tồn tại" -ForegroundColor Yellow
}

# 5. Kiểm tra code không hardcode credentials
Write-Host ""
Write-Host "[5/6] Kiểm tra code không hardcode credentials..." -ForegroundColor Yellow
$sensitivePatterns = @(
    @{ Pattern = "eshelf123"; Description = "Database password" },
    @{ Pattern = "your-secret-key"; Description = "JWT secret" },
    @{ Pattern = "644123626050"; Description = "AWS account ID" },
    @{ Pattern = "cloud_user"; Description = "AWS username" },
    @{ Pattern = "3ZJ7"; Description = "AWS password" }
)

$foundIssues = $false
foreach ($pattern in $sensitivePatterns) {
    $files = Get-ChildItem -Recurse -File -Include *.js,*.jsx,*.ts,*.tsx,*.yml,*.yaml,*.json | 
        Where-Object { $_.FullName -notmatch "node_modules|\.git|dist|build" } |
        Select-String -Pattern $pattern.Pattern -SimpleMatch
    
    if ($files) {
        $foundIssues = $true
        Write-Host "  ⚠ Tìm thấy '$($pattern.Description)' trong:" -ForegroundColor Yellow
        foreach ($file in $files | Select-Object -First 3) {
            Write-Host "    - $($file.Path)" -ForegroundColor Yellow
        }
        if ($files.Count -gt 3) {
            Write-Host "    ... và $($files.Count - 3) file khác" -ForegroundColor Yellow
        }
    }
}

if (-not $foundIssues) {
    Write-Host "  ✓ Không tìm thấy hardcoded credentials trong code" -ForegroundColor Green
}

# 6. Kiểm tra biến môi trường trong code
Write-Host ""
Write-Host "[6/6] Kiểm tra code sử dụng process.env..." -ForegroundColor Yellow
$envUsage = Get-ChildItem -Recurse -File -Include *.js,*.jsx,*.ts,*.tsx | 
    Where-Object { $_.FullName -notmatch "node_modules|\.git|dist|build" } |
    Select-String -Pattern "process\.env\." | 
    Measure-Object

if ($envUsage.Count -gt 0) {
    Write-Host "  ✓ Tìm thấy $($envUsage.Count) lần sử dụng process.env" -ForegroundColor Green
} else {
    $warnings += "Không tìm thấy sử dụng process.env trong code"
    Write-Host "  ⚠ Không tìm thấy sử dụng process.env" -ForegroundColor Yellow
}

# Tổng kết
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "KẾT QUẢ KIỂM TRA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ Tất cả kiểm tra đều PASS!" -ForegroundColor Green
    exit 0
} else {
    if ($errors.Count -gt 0) {
        Write-Host ""
        Write-Host "LỖI ($($errors.Count)):" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  ✗ $error" -ForegroundColor Red
        }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "CẢNH BÁO ($($warnings.Count)):" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  ⚠ $warning" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Vui long sua cac loi va canh bao tren." -ForegroundColor Yellow
    exit 1
}

