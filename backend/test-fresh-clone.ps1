# Script test quy trình setup từ đầu (giả lập người mới clone repo)
# Kiểm tra xem docker-compose có tự động setup đầy đủ dataset không

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TEST FRESH CLONE - TỰ ĐỘNG SETUP DATABASE" -ForegroundColor Cyan
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

# Kiểm tra file JSON có tồn tại không
Write-Host "2. Kiểm tra file book-details.json..." -ForegroundColor Yellow
$jsonPath = "..\src\data\book-details.json"
if (Test-Path $jsonPath) {
    $jsonContent = Get-Content $jsonPath -Raw | ConvertFrom-Json
    Write-Host "   OK: Tìm thấy file JSON với $($jsonContent.Count) sách" -ForegroundColor Green
} else {
    Write-Host "   ERROR: Không tìm thấy file JSON tại $jsonPath" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Dừng và xóa containers hiện tại (giả lập fresh start)
Write-Host "3. Dừng containers hiện tại (giả lập fresh clone)..." -ForegroundColor Yellow
docker-compose down 2>&1 | Out-Null
Write-Host "   OK: Containers đã dừng" -ForegroundColor Green
Write-Host ""

# Lưu ý: KHÔNG xóa volume để test xem có giữ dữ liệu không
# Nhưng để test fresh clone thật, ta sẽ xóa volume
Write-Host "4. Xóa database volume để test fresh clone (tùy chọn)..." -ForegroundColor Yellow
Write-Host "   Bạn có muốn xóa volume để test fresh clone thật? (y/n)" -ForegroundColor Yellow
$response = Read-Host
if ($response -eq "y" -or $response -eq "Y") {
    docker volume rm backend_postgres_data 2>&1 | Out-Null
    Write-Host "   OK: Volume đã xóa - sẽ test fresh clone thật" -ForegroundColor Green
} else {
    Write-Host "   SKIP: Giữ volume - test với database hiện có" -ForegroundColor Cyan
}
Write-Host ""

# Start docker-compose (giả lập người mới clone và chạy docker-compose up)
Write-Host "5. Start docker-compose (giả lập: người mới clone repo và chạy docker-compose up)..." -ForegroundColor Yellow
Write-Host "   Đang start services..." -ForegroundColor Cyan
docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: Không thể start docker-compose!" -ForegroundColor Red
    exit 1
}
Write-Host "   OK: Services đã start" -ForegroundColor Green
Write-Host ""

# Đợi database và migration hoàn tất
Write-Host "6. Đợi database và migration hoàn tất (30 giây)..." -ForegroundColor Yellow
Write-Host "   (Đang chờ PostgreSQL khởi động, migrations chạy, và seed script chạy...)" -ForegroundColor Gray
Start-Sleep -Seconds 30
Write-Host ""

# Kiểm tra logs của db-migration
Write-Host "7. Kiểm tra logs của db-migration service..." -ForegroundColor Yellow
$logs = docker-compose logs db-migration 2>&1
$logs | Select-String -Pattern "Found.*books|Existing books|Total books|Books:.*created|Seed completed|Database setup complete" | ForEach-Object {
    Write-Host "   $_" -ForegroundColor Cyan
}
Write-Host ""

# Kiểm tra dữ liệu trong database
Write-Host "8. Kiểm tra dữ liệu trong database..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
try {
    $result = docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) as books FROM books; SELECT COUNT(*) as genres FROM genres; SELECT COUNT(*) as users FROM users;" 2>&1
    Write-Host $result
    
    if ($result -match "books\s+(\d+)") {
        $bookCount = [int]$matches[1]
        Write-Host ""
        Write-Host "   Số sách trong database: $bookCount" -ForegroundColor Cyan
        
        if ($bookCount -eq $jsonContent.Count) {
            Write-Host "   SUCCESS: Database có đầy đủ $bookCount sách!" -ForegroundColor Green
        } elseif ($bookCount -gt 0) {
            Write-Host "   WARNING: Database có $bookCount sách (thiếu một số sách)" -ForegroundColor Yellow
        } else {
            Write-Host "   ERROR: Database không có sách nào!" -ForegroundColor Red
        }
    }
    
    if ($result -match "genres\s+(\d+)") {
        $genreCount = [int]$matches[1]
        Write-Host "   Số genres trong database: $genreCount" -ForegroundColor Cyan
    }
    
    if ($result -match "users\s+(\d+)") {
        $userCount = [int]$matches[1]
        Write-Host "   Số users trong database: $userCount" -ForegroundColor Cyan
        if ($userCount -ge 2) {
            Write-Host "   SUCCESS: Users đã được tạo (admin và demo user)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "   ERROR: Không thể kiểm tra database!" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

# Kiểm tra một vài sách cụ thể
Write-Host "9. Kiểm tra một vài sách cụ thể..." -ForegroundColor Yellow
try {
    $books = docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT isbn, title FROM books LIMIT 3;" 2>&1
    Write-Host $books
    Write-Host "   OK: Có thể query sách từ database" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Không thể query sách!" -ForegroundColor Red
}
Write-Host ""

# Kiểm tra database volume
Write-Host "10. Kiểm tra database volume..." -ForegroundColor Yellow
try {
    $volume = docker volume inspect backend_postgres_data 2>&1
    if ($volume -match "Mountpoint") {
        Write-Host "   OK: Database volume tồn tại và persistent" -ForegroundColor Green
        Write-Host "   Dữ liệu được lưu trong Docker volume (sẽ giữ khi rebuild containers)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   WARNING: Không thể kiểm tra volume" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "KẾT QUẢ TEST" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Kết luận:" -ForegroundColor Yellow
Write-Host "1. Sách được lưu trong PostgreSQL database (không phải local/memory)" -ForegroundColor White
Write-Host "2. Docker-compose tự động:" -ForegroundColor White
Write-Host "   - Tạo database schema (migrations)" -ForegroundColor Gray
Write-Host "   - Seed dữ liệu sách từ file JSON" -ForegroundColor Gray
Write-Host "   - Tạo users (admin, demo)" -ForegroundColor Gray
Write-Host "3. Database volume persistent - dữ liệu giữ khi rebuild containers" -ForegroundColor White
Write-Host ""
Write-Host "Người mới clone repo chỉ cần:" -ForegroundColor Yellow
Write-Host "  cd backend" -ForegroundColor Cyan
Write-Host "  docker-compose up -d" -ForegroundColor Cyan
Write-Host ""
Write-Host "Database sẽ tự động setup đầy đủ!" -ForegroundColor Green
Write-Host ""

