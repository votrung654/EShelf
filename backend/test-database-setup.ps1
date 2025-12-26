# Script test quy trình tự động setup database
# Đảm bảo database không bị mất dữ liệu khi rebuild

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TEST DATABASE SETUP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $PSScriptRoot

# Kiểm tra Docker
Write-Host "1. Kiểm tra Docker..." -ForegroundColor Yellow
docker ps > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: Docker không hoạt động!" -ForegroundColor Red
    exit 1
}
Write-Host "   OK: Docker đang chạy" -ForegroundColor Green
Write-Host ""

# Kiểm tra số lượng books hiện tại (nếu có)
Write-Host "2. Kiểm tra dữ liệu hiện tại trong database..." -ForegroundColor Yellow
$existingCount = 0
try {
    $result = docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) as count FROM books;" 2>&1
    if ($result -match "count\s+(\d+)") {
        $existingCount = [int]$matches[1]
        Write-Host "   Số sách hiện tại: $existingCount" -ForegroundColor Cyan
    } else {
        Write-Host "   Database chưa có dữ liệu hoặc chưa khởi động" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Database chưa khởi động hoặc chưa có dữ liệu" -ForegroundColor Gray
}
Write-Host ""

# Rebuild db-migration service
Write-Host "3. Rebuild db-migration service với seed script mới..." -ForegroundColor Yellow
docker-compose build db-migration
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: Không thể build db-migration!" -ForegroundColor Red
    exit 1
}
Write-Host "   OK: Build thành công" -ForegroundColor Green
Write-Host ""

# Restart db-migration để chạy seed
Write-Host "4. Restart db-migration service..." -ForegroundColor Yellow
docker-compose down db-migration 2>&1 | Out-Null
docker-compose up -d db-migration
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: Không thể start db-migration!" -ForegroundColor Red
    exit 1
}
Write-Host "   OK: Service đã start" -ForegroundColor Green
Write-Host ""

# Đợi seed chạy xong
Write-Host "5. Đợi seed script chạy (20 giây)..." -ForegroundColor Yellow
Start-Sleep -Seconds 20
Write-Host ""

# Kiểm tra logs
Write-Host "6. Kiểm tra logs của db-migration..." -ForegroundColor Yellow
$logs = docker-compose logs db-migration 2>&1
$logs | Select-String -Pattern "Found.*books|Existing books|Total books|Books:.*created|Seed completed" | ForEach-Object {
    Write-Host "   $_" -ForegroundColor Cyan
}
Write-Host ""

# Kiểm tra số lượng books sau khi seed
Write-Host "7. Kiểm tra dữ liệu sau khi seed..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
try {
    $result = docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) as count FROM books; SELECT COUNT(*) as genres FROM genres;" 2>&1
    Write-Host $result
    
    if ($result -match "count\s+(\d+)") {
        $newCount = [int]$matches[1]
        Write-Host ""
        Write-Host "   Số sách sau seed: $newCount" -ForegroundColor Cyan
        
        if ($existingCount -gt 0) {
            if ($newCount -ge $existingCount) {
                Write-Host "   SUCCESS: Dữ liệu được bảo toàn! ($existingCount -> $newCount)" -ForegroundColor Green
            } else {
                Write-Host "   WARNING: Số sách giảm! Có thể đã bị mất dữ liệu!" -ForegroundColor Red
            }
        } else {
            if ($newCount -gt 0) {
                Write-Host "   SUCCESS: Seed đã tạo $newCount sách mới!" -ForegroundColor Green
            } else {
                Write-Host "   ERROR: Không có sách nào được tạo!" -ForegroundColor Red
            }
        }
    }
} catch {
    Write-Host "   ERROR: Không thể kiểm tra database!" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

# Kiểm tra users
Write-Host "8. Kiểm tra users..." -ForegroundColor Yellow
try {
    $users = docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT email, role FROM users;" 2>&1
    if ($users -match "admin@eshelf.com") {
        Write-Host "   OK: Admin user tồn tại" -ForegroundColor Green
    }
    if ($users -match "user@eshelf.com") {
        Write-Host "   OK: Demo user tồn tại" -ForegroundColor Green
    }
} catch {
    Write-Host "   WARNING: Không thể kiểm tra users" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TEST HOÀN TẤT" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Lưu ý:" -ForegroundColor Yellow
Write-Host "- Seed script sẽ BẢO TOÀN dữ liệu hiện có" -ForegroundColor Yellow
Write-Host "- Chỉ thêm sách mới nếu chưa có trong database" -ForegroundColor Yellow
Write-Host "- Database volume (postgres_data) sẽ giữ dữ liệu khi rebuild" -ForegroundColor Yellow
Write-Host ""

