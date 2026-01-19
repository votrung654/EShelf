# Script don dep cache trong Windows Store Packages
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$totalFreed = 0

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            $size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            return [math]::Round($size / 1GB, 2)
        } catch {
            return 0
        }
    }
    return 0
}

Write-Host ""
Write-Host "DON DEP WINDOWS STORE PACKAGES CACHE" -ForegroundColor Magenta
Write-Host ""

$packagesPath = "$env:LOCALAPPDATA\Packages"
if (-not (Test-Path $packagesPath)) {
    Write-Host "Khong tim thay Packages folder" -ForegroundColor Yellow
    exit 0
}

$packages = Get-ChildItem -Path $packagesPath -Directory -ErrorAction SilentlyContinue

foreach ($pkg in $packages) {
    $cacheDirs = @(
        "LocalCache",
        "TempState",
        "AC\INetCache",
        "AC\INetCookies",
        "AC\Microsoft\CryptnetUrlCache",
        "LocalState\cache",
        "LocalState\Cache"
    )
    
    $pkgFreed = 0
    foreach ($cacheDir in $cacheDirs) {
        $cachePath = Join-Path $pkg.FullName $cacheDir
        if (Test-Path $cachePath) {
            $size = Get-FolderSize -Path $cachePath
            if ($size -gt 0.1) {
                Write-Host "[INFO] $($pkg.Name)\$cacheDir : $size GB" -ForegroundColor Cyan
                try {
                    Remove-Item -Path $cachePath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "  [OK] Da xoa" -ForegroundColor Green
                    $pkgFreed += $size
                    $totalFreed += $size
                } catch {
                    Write-Host "  [WARN] Khong the xoa: $_" -ForegroundColor Yellow
                }
            }
        }
    }
    
    if ($pkgFreed -gt 0) {
        Write-Host "  Tong giai phong tu $($pkg.Name): $([math]::Round($pkgFreed, 2)) GB" -ForegroundColor Green
        Write-Host ""
    }
}

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "TONG KET" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "Tong dung luong da giai phong: $([math]::Round($totalFreed, 2)) GB" -ForegroundColor Green
Write-Host ""

