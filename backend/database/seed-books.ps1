# Script to seed books data manually
$env:DATABASE_URL = "postgresql://eshelf:eshelf123@localhost:5432/eshelf?schema=public"

Write-Host "Seeding books data..." -ForegroundColor Yellow
Write-Host "DATABASE_URL: $env:DATABASE_URL" -ForegroundColor Gray

Set-Location $PSScriptRoot
node prisma/seed.js

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSeeding completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nSeeding failed!" -ForegroundColor Red
    exit 1
}

