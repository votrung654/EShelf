# Script tim cac thu muc lon trong o C
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

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
Write-Host "TIM CAC THU MUC LON TREN O C" -ForegroundColor Magenta
Write-Host ""

# Kiem tra Packages
Write-Host "1. Windows Packages (AppData\Local\Packages):" -ForegroundColor Cyan
$packagesPath = "$env:LOCALAPPDATA\Packages"
if (Test-Path $packagesPath) {
    $packages = Get-ChildItem -Path $packagesPath -Directory -ErrorAction SilentlyContinue
    $largePackages = @()
    foreach ($pkg in $packages) {
        $size = Get-FolderSize -Path $pkg.FullName
        if ($size -gt 0.5) {
            $largePackages += [PSCustomObject]@{
                Name = $pkg.Name
                SizeGB = $size
            }
        }
    }
    $largePackages = $largePackages | Sort-Object SizeGB -Descending
    foreach ($pkg in $largePackages) {
        $color = if ($pkg.SizeGB -gt 2) { "Red" } elseif ($pkg.SizeGB -gt 1) { "Yellow" } else { "White" }
        Write-Host "   $($pkg.Name): $($pkg.SizeGB) GB" -ForegroundColor $color
    }
    if ($largePackages.Count -eq 0) {
        Write-Host "   [OK] Khong co package nao > 500MB" -ForegroundColor Green
    }
}

# Kiem tra Downloads
Write-Host ""
Write-Host "2. Downloads Folder:" -ForegroundColor Cyan
$downloadsPath = "$env:USERPROFILE\Downloads"
if (Test-Path $downloadsPath) {
    $size = Get-FolderSize -Path $downloadsPath
    $color = if ($size -gt 5) { "Red" } elseif ($size -gt 2) { "Yellow" } else { "Green" }
    Write-Host "   Downloads: $size GB" -ForegroundColor $color
    if ($size -gt 2) {
        Write-Host "   [GOI Y] Co the xoa cac file khong can thiet trong Downloads" -ForegroundColor Yellow
    }
}

# Kiem tra Program Files
Write-Host ""
Write-Host "3. Program Files (top 10 ung dung lon nhat):" -ForegroundColor Cyan
$programFiles = @(
    "C:\Program Files",
    "C:\Program Files (x86)"
)
foreach ($pf in $programFiles) {
    if (Test-Path $pf) {
        Write-Host "   Kiem tra: $pf" -ForegroundColor Gray
        $apps = Get-ChildItem -Path $pf -Directory -ErrorAction SilentlyContinue | Select-Object -First 20
        $appSizes = @()
        foreach ($app in $apps) {
            $size = Get-FolderSize -Path $app.FullName
            if ($size -gt 0.1) {
                $appSizes += [PSCustomObject]@{
                    Name = $app.Name
                    SizeGB = $size
                }
            }
        }
        $appSizes = $appSizes | Sort-Object SizeGB -Descending | Select-Object -First 10
        foreach ($app in $appSizes) {
            $color = if ($app.SizeGB -gt 5) { "Red" } elseif ($app.SizeGB -gt 2) { "Yellow" } else { "White" }
            Write-Host "      $($app.Name): $($app.SizeGB) GB" -ForegroundColor $color
        }
    }
}

Write-Host ""
Write-Host "GOI Y DON DEP:" -ForegroundColor Yellow
Write-Host "   1. Xoa cac file khong can thiet trong Downloads" -ForegroundColor Cyan
Write-Host "   2. Go cac ung dung khong dung trong Settings > Apps" -ForegroundColor Cyan
Write-Host "   3. Chay Disk Cleanup voi quyen Admin: cleanmgr.exe /sagerun:1" -ForegroundColor Cyan
Write-Host "   4. Di chuyen project sang o D neu o C qua day" -ForegroundColor Cyan
Write-Host ""

