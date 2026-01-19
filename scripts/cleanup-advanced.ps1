# Script don dep nang cao - Tim va xoa cac thu muc lon trong AppData

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"
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
Write-Host "DON DEP NANG CAO - TIM CAC THU MUC LON" -ForegroundColor Magenta
Write-Host ""

# Tim cac thu muc lon trong AppData\Local
Write-Host "Tim cac thu muc lon trong AppData\Local..." -ForegroundColor Cyan
$appDataLocal = "$env:LOCALAPPDATA"
$largeFolders = @()

if (Test-Path $appDataLocal) {
    $folders = Get-ChildItem -Path $appDataLocal -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $folders) {
        $size = Get-FolderSize -Path $folder.FullName
        if ($size -gt 0.5) {  # Chi hien thi neu > 500MB
            $largeFolders += [PSCustomObject]@{
                Name = $folder.Name
                Path = $folder.FullName
                SizeGB = $size
            }
        }
    }
}

# Sap xep theo kich thuoc
$largeFolders = $largeFolders | Sort-Object -Property SizeGB -Descending

Write-Host ""
Write-Host "Cac thu muc lon (>500MB) trong AppData\Local:" -ForegroundColor Yellow
foreach ($folder in $largeFolders) {
    $color = if ($folder.SizeGB -gt 5) { "Red" } elseif ($folder.SizeGB -gt 2) { "Yellow" } else { "White" }
    Write-Host "  $($folder.Name): $($folder.SizeGB) GB" -ForegroundColor $color
    Write-Host "    Path: $($folder.Path)" -ForegroundColor Gray
}

# Cac thu muc an toan de xoa (cache, temp)
$safeToClean = @(
    "*cache*",
    "*temp*",
    "*tmp*",
    "*log*",
    "CrashDumps",
    "CrashReports"
)

Write-Host ""
Write-Host "Dang tim cac thu muc cache/temp co the xoa..." -ForegroundColor Cyan

foreach ($folder in $largeFolders) {
    $shouldClean = $false
    $reason = ""
    
    # Kiem tra ten thu muc
    foreach ($pattern in $safeToClean) {
        if ($folder.Name -like $pattern) {
            $shouldClean = $true
            $reason = "Match pattern: $pattern"
            break
        }
    }
    
    # Cac thu muc cu the an toan
    $knownSafe = @(
        "npm-cache",
        "pip",
        "yarn",
        "pnpm",
        "Docker",
        "Microsoft\Edge\Cache",
        "Google\Chrome\Cache",
        "Mozilla\Firefox\Profiles"
    )
    
    foreach ($safe in $knownSafe) {
        if ($folder.Path -like "*\$safe*") {
            $shouldClean = $true
            $reason = "Known safe: $safe"
            break
        }
    }
    
    if ($shouldClean) {
        Write-Host ""
        Write-Host "  [INFO] Tim thay: $($folder.Name) - $($folder.SizeGB) GB" -ForegroundColor Cyan
        Write-Host "    Ly do: $reason" -ForegroundColor Gray
        
        # Xoa cache con trong thu muc
        $cacheSubfolders = Get-ChildItem -Path $folder.Path -Directory -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "*cache*" -or $_.Name -like "*temp*" }
        
        foreach ($subfolder in $cacheSubfolders) {
            $subSize = Get-FolderSize -Path $subfolder.FullName
            if ($subSize -gt 0.1) {
                Write-Host "    Xoa: $($subfolder.Name) ($subSize GB)" -ForegroundColor Yellow
                try {
                    Remove-Item -Path $subfolder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "      [OK] Da xoa" -ForegroundColor Green
                    $totalFreed += $subSize
                } catch {
                    Write-Host "      [ERROR] Khong the xoa: $_" -ForegroundColor Red
                }
            }
        }
        
        # Neu toan bo thu muc la cache, xoa luon
        if ($folder.Name -like "*cache*" -and $folder.SizeGB -gt 0.5) {
            Write-Host "    Xoa toan bo thu muc cache: $($folder.Name)" -ForegroundColor Yellow
            try {
                Remove-Item -Path $folder.Path -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "      [OK] Da xoa toan bo" -ForegroundColor Green
                $totalFreed += $folder.SizeGB
            } catch {
                Write-Host "      [ERROR] Khong the xoa: $_" -ForegroundColor Red
            }
        }
    }
}

# Xoa cac file temp trong AppData
Write-Host ""
Write-Host "Xoa cac file temp trong AppData..." -ForegroundColor Cyan
$tempFiles = Get-ChildItem -Path $appDataLocal -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { 
        $_.Extension -in @(".tmp", ".temp", ".log", ".cache") -or 
        $_.Name -like "*.tmp" -or 
        $_.Name -like "*.temp"
    } |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

if ($tempFiles) {
    $tempSize = ($tempFiles | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "  Tim thay $($tempFiles.Count) file temp cu (>7 ngay): $([math]::Round($tempSize, 2)) GB" -ForegroundColor Yellow
    $tempFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Da xoa" -ForegroundColor Green
    $totalFreed += $tempSize
} else {
    Write-Host "  [OK] Khong co file temp cu" -ForegroundColor Green
}

# Xoa Windows Prefetch (neu co quyen)
Write-Host ""
Write-Host "Kiem tra Windows Prefetch..." -ForegroundColor Cyan
$prefetchPath = "C:\Windows\Prefetch"
if (Test-Path $prefetchPath) {
    try {
        $prefetchFiles = Get-ChildItem -Path $prefetchPath -File -ErrorAction SilentlyContinue
        if ($prefetchFiles) {
            $prefetchSize = ($prefetchFiles | Measure-Object -Property Length -Sum).Sum / 1GB
            Write-Host "  Prefetch: $([math]::Round($prefetchSize, 2)) GB" -ForegroundColor Yellow
            Write-Host "  [INFO] Prefetch files se tu dong xoa sau 3 ngay, khong can xoa thu cong" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [WARN] Can quyen admin de truy cap Prefetch" -ForegroundColor Yellow
    }
}

# Summary
Write-Host ""
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "TONG KET" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "Tong dung luong da giai phong: $([math]::Round($totalFreed, 2)) GB" -ForegroundColor Green
Write-Host ""






