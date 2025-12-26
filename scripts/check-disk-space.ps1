# Script kiem tra dung luong o C va cac thu muc lon
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "KIEM TRA DUNG LUONG O C" -ForegroundColor Magenta
Write-Host ""

# Kiem tra dung luong o C
$drive = Get-PSDrive C
$freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
$usedSpaceGB = [math]::Round(($drive.Used / 1GB), 2)
$totalSpaceGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
$percentFree = [math]::Round(($drive.Free / ($drive.Free + $drive.Used)) * 100, 2)

Write-Host "Thong tin o C:" -ForegroundColor Cyan
Write-Host "   Tong dung luong: $totalSpaceGB GB" -ForegroundColor White
Write-Host "   Da su dung: $usedSpaceGB GB" -ForegroundColor Yellow
$percentText = "$percentFree%"
$color = if ($percentFree -lt 10) { "Red" } elseif ($percentFree -lt 20) { "Yellow" } else { "Green" }
Write-Host "   Con trong: $freeSpaceGB GB ($percentText)" -ForegroundColor $color

if ($percentFree -lt 10) {
    Write-Host ""
    Write-Host "CANH BAO: O C sap day! Nen don dep ngay." -ForegroundColor Red
} elseif ($percentFree -lt 20) {
    Write-Host ""
    Write-Host "Goi y: O C dang gan day, nen don dep som." -ForegroundColor Yellow
}

# Kiem tra cac thu muc lon
Write-Host ""
Write-Host "Cac thu muc lon tren o C:" -ForegroundColor Cyan

$largeFolders = @(
    @{ Path = "C:\Windows\Temp"; Name = "Windows Temp" },
    @{ Path = "$env:LOCALAPPDATA\Temp"; Name = "User Temp" },
    @{ Path = "$env:APPDATA"; Name = "AppData\Roaming" },
    @{ Path = "$env:LOCALAPPDATA"; Name = "AppData\Local" },
    @{ Path = "C:\Program Files"; Name = "Program Files" },
    @{ Path = 'C:\Program Files (x86)'; Name = "Program Files (x86)" },
    @{ Path = "C:\Users\$env:USERNAME\Downloads"; Name = "Downloads" },
    @{ Path = "C:\Users\$env:USERNAME\Documents"; Name = "Documents" }
)

$results = @()
foreach ($folder in $largeFolders) {
    if (Test-Path $folder.Path) {
        try {
            $size = (Get-ChildItem -Path $folder.Path -Recurse -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $sizeGB = [math]::Round($size / 1GB, 2)
            if ($sizeGB -gt 0.1) {
                $results += [PSCustomObject]@{
                    Name = $folder.Name
                    Path = $folder.Path
                    SizeGB = $sizeGB
                }
            }
        } catch {
            # Bo qua loi permission
        }
    }
}

# Sap xep theo kich thuoc
$results = $results | Sort-Object -Property SizeGB -Descending

foreach ($result in $results) {
    $color = if ($result.SizeGB -gt 10) { "Red" } elseif ($result.SizeGB -gt 5) { "Yellow" } else { "White" }
    Write-Host "   $($result.Name): $($result.SizeGB) GB" -ForegroundColor $color
    Write-Host "      Path: $($result.Path)" -ForegroundColor Gray
}

# Kiem tra npm cache
Write-Host ""
Write-Host "npm Cache:" -ForegroundColor Cyan
$npmCachePath = npm config get cache 2>$null
if ($npmCachePath -and $npmCachePath -ne "null") {
    $npmCachePath = $npmCachePath.Trim()
    if (Test-Path $npmCachePath) {
        $size = (Get-ChildItem -Path $npmCachePath -Recurse -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        $sizeGB = [math]::Round($size / 1GB, 2)
        $color = if ($sizeGB -gt 1) { "Yellow" } else { "Green" }
        Write-Host "   Dung luong: $sizeGB GB" -ForegroundColor $color
        Write-Host "   Path: $npmCachePath" -ForegroundColor Gray
    }
} else {
    Write-Host "   Khong tim thay npm cache" -ForegroundColor Gray
}

# Kiem tra Docker
Write-Host ""
Write-Host "Docker:" -ForegroundColor Cyan
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        $dockerInfo = docker system df 2>$null
        if ($dockerInfo) {
            $dockerInfo | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
        }
    } catch {
        Write-Host "   Docker khong chay hoac co loi" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Docker chua duoc cai dat" -ForegroundColor Gray
}

# Kiem tra Recycle Bin
Write-Host ""
Write-Host "Recycle Bin:" -ForegroundColor Cyan
try {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.NameSpace(0xA)
    $items = $recycleBin.Items()
    $size = 0
    foreach ($item in $items) {
        $size += $item.Size
    }
    $sizeGB = [math]::Round($size / 1GB, 2)
    if ($sizeGB -gt 0) {
        Write-Host "   Dung luong: $sizeGB GB" -ForegroundColor Yellow
    } else {
        Write-Host "   Da trong" -ForegroundColor Green
    }
} catch {
    Write-Host "   Khong the kiem tra" -ForegroundColor Gray
}

Write-Host ""
Write-Host "De don dep an toan, chay:" -ForegroundColor Yellow
Write-Host "   .\scripts\cleanup-c-drive-safe.ps1 -DryRun    # Xem truoc" -ForegroundColor Cyan
Write-Host "   .\scripts\cleanup-c-drive-safe.ps1            # Thuc hien" -ForegroundColor Cyan
Write-Host ""
