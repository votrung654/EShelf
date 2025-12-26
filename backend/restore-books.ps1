# Script khôi phục dữ liệu sách
# Chạy script này sau khi Docker Desktop hoạt động lại

Write-Host "Khôi phục dữ liệu sách..." -ForegroundColor Yellow
Write-Host ""

Set-Location $PSScriptRoot

# Kiểm tra Docker
Write-Host "Kiểm tra Docker..." -ForegroundColor Cyan
docker ps > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker không hoạt động! Vui lòng khởi động Docker Desktop trước." -ForegroundColor Red
    exit 1
}

# Rebuild image
Write-Host "Rebuild db-migration image..." -ForegroundColor Cyan
docker-compose build db-migration
if ($LASTEXITCODE -ne 0) {
    Write-Host "Lỗi khi build image!" -ForegroundColor Red
    exit 1
}

# Restart service
Write-Host "Restart db-migration service..." -ForegroundColor Cyan
docker-compose down db-migration
docker-compose up -d db-migration

# Đợi seed chạy
Write-Host "Đợi seed chạy (15 giây)..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

# Kiểm tra logs
Write-Host "`nKiểm tra logs..." -ForegroundColor Cyan
docker-compose logs db-migration | Select-String -Pattern "Found.*books|Book data file" -Context 2

# Kiểm tra số lượng books
Write-Host "`nKiểm tra dữ liệu trong database..." -ForegroundColor Cyan
$result = docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) as book_count FROM books; SELECT COUNT(*) as genre_count FROM genres;" 2>&1
Write-Host $result

# Kết quả
$bookCount = ($result | Select-String -Pattern "book_count|^\s+\d+" | Select-Object -First 1)
if ($bookCount -match "\d+") {
    $count = [int]($matches[0])
    if ($count -gt 0) {
        Write-Host "`nThành công! Đã khôi phục $count quyển sách." -ForegroundColor Green
    } else {
        Write-Host "`nCảnh báo: Không có sách nào được tìm thấy!" -ForegroundColor Yellow
        Write-Host "Kiểm tra file src/data/book-details.json có tồn tại không." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nKhông thể đọc kết quả từ database." -ForegroundColor Yellow
}

Write-Host "`nHoàn tất!" -ForegroundColor Green

