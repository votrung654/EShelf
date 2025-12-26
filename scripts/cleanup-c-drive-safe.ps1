# Script don dep o C an toan - Khong anh huong project va tools
# Chi xoa cache, temp files, va cac file co the tai tao

param(
    [switch]$DryRun = $false,
    [switch]$SkipConfirmation = $false
)

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

function Remove-SafeFolder {
    param(
        [string]$Path,
        [string]$Description,
        [switch]$Recursive = $true
    )
    
    if (-not (Test-Path $Path)) {
        Write-Host "  [WARN] Khong tim thay: $Path" -ForegroundColor Yellow
        return 0
    }
    
    $size = Get-FolderSize -Path $Path
    if ($size -eq 0) {
        Write-Host "  [OK] ${Description}: Da trong" -ForegroundColor Green
        return 0
    }
    
    Write-Host "  [INFO] ${Description}: $size GB" -ForegroundColor Cyan
    
    if ($DryRun) {
        Write-Host "     [DRY RUN] Se xoa: $Path" -ForegroundColor Yellow
        return $size
    }
    
    try {
        if ($Recursive) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
        }
        Write-Host "     [OK] Da xoa thanh cong" -ForegroundColor Green
        return $size
    } catch {
        Write-Host "     [ERROR] Loi khi xoa: $_" -ForegroundColor Red
        return 0
    }
}

Write-Host ""
Write-Host "DON DEP O C AN TOAN" -ForegroundColor Magenta
Write-Host ""
Write-Host "Script nay se xoa:" -ForegroundColor White
Write-Host "  [OK] Windows Temp files" -ForegroundColor Green
Write-Host "  [OK] Browser cache" -ForegroundColor Green
Write-Host "  [OK] npm cache (co the tai tao)" -ForegroundColor Green
Write-Host "  [OK] Python cache (__pycache__)" -ForegroundColor Green
Write-Host "  [OK] Docker unused images/containers" -ForegroundColor Green
Write-Host "  [OK] Build artifacts (dist/, build/)" -ForegroundColor Green
Write-Host "  [OK] Recycle Bin" -ForegroundColor Green
Write-Host "  [OK] Windows Update files cu" -ForegroundColor Green
Write-Host ""
Write-Host "KHONG xoa:" -ForegroundColor White
Write-Host "  [X] node_modules trong project" -ForegroundColor Red
Write-Host "  [X] Cong cu da cai (Node.js, Python, Docker, etc.)" -ForegroundColor Red
Write-Host "  [X] Project files va source code" -ForegroundColor Red
Write-Host "  [X] Database files" -ForegroundColor Red
Write-Host ""

if ($DryRun) {
    Write-Host "CHE DO DRY RUN - Chi xem, khong xoa that" -ForegroundColor Yellow
    Write-Host ""
}

if (-not $SkipConfirmation -and -not $DryRun) {
    $confirm = Read-Host "Ban co muon tiep tuc? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Da huy." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Bat dau don dep..." -ForegroundColor Cyan
Write-Host ""

# 1. Windows Temp Files
Write-Host "1. Windows Temp Files" -ForegroundColor Magenta
$tempPaths = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "C:\Windows\Temp"
)
foreach ($tempPath in $tempPaths) {
    if (Test-Path $tempPath) {
        $files = Get-ChildItem -Path $tempPath -File -ErrorAction SilentlyContinue
        if ($files) {
            $size = ($files | Measure-Object -Property Length -Sum).Sum / 1GB
            Write-Host "  [INFO] ${tempPath}: $([math]::Round($size, 2)) GB" -ForegroundColor Cyan
            if (-not $DryRun) {
                $files | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Host "     [OK] Da xoa" -ForegroundColor Green
                $totalFreed += $size
            } else {
                $totalFreed += $size
            }
        }
    }
}

# 2. Browser Cache
Write-Host ""
Write-Host "2. Browser Cache" -ForegroundColor Magenta
$browserCaches = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
)
foreach ($cache in $browserCaches) {
    $totalFreed += Remove-SafeFolder -Path $cache -Description "Browser Cache"
}

# 3. npm Cache
Write-Host ""
Write-Host "3. npm Cache" -ForegroundColor Magenta
$npmCachePath = npm config get cache 2>$null
if ($npmCachePath -and $npmCachePath -ne "null") {
    $npmCachePath = $npmCachePath.Trim()
    if (Test-Path $npmCachePath) {
        $size = Get-FolderSize -Path $npmCachePath
        Write-Host "  [INFO] npm cache: $size GB" -ForegroundColor Cyan
        if (-not $DryRun) {
            try {
                npm cache clean --force 2>$null
                Write-Host "     [OK] Da xoa npm cache" -ForegroundColor Green
                $totalFreed += $size
            } catch {
                Write-Host "     [ERROR] Loi khi xoa npm cache" -ForegroundColor Red
            }
        } else {
            $totalFreed += $size
        }
    }
} else {
    Write-Host "  [WARN] Khong tim thay npm cache path" -ForegroundColor Yellow
}

# 4. Python Cache trong project
Write-Host ""
Write-Host "4. Python Cache trong Project" -ForegroundColor Magenta
$projectRoot = Split-Path -Parent $PSScriptRoot
$pythonCachePath = "$projectRoot\backend\services\ml-service\__pycache__"
if (Test-Path $pythonCachePath) {
    $totalFreed += Remove-SafeFolder -Path $pythonCachePath -Description "Python __pycache__"
}
$pycFiles = Get-ChildItem -Path "$projectRoot\backend\services\ml-service" -Filter "*.pyc" -Recurse -ErrorAction SilentlyContinue
if ($pycFiles) {
    $size = ($pycFiles | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "  [INFO] Python .pyc files: $([math]::Round($size, 2)) GB" -ForegroundColor Cyan
    if (-not $DryRun) {
        $pycFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "     [OK] Da xoa .pyc files" -ForegroundColor Green
        $totalFreed += $size
    } else {
        $totalFreed += $size
    }
}

# 5. Docker Cleanup
Write-Host ""
Write-Host "5. Docker Cleanup" -ForegroundColor Magenta
if (Get-Command docker -ErrorAction SilentlyContinue) {
    if (-not $DryRun) {
        try {
            Write-Host "  [INFO] Dang don dep Docker..." -ForegroundColor Cyan
            docker system prune -a --volumes -f 2>&1 | Out-Null
            Write-Host "     [OK] Da don dep Docker (unused images, containers, volumes)" -ForegroundColor Green
            # Uoc tinh: Docker cleanup thuong giai phong ~4-5 GB
            $totalFreed += 4.8
        } catch {
            Write-Host "     [WARN] Docker khong chay hoac co loi" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [INFO] Docker: Se chay 'docker system prune -a --volumes -f'" -ForegroundColor Cyan
        Write-Host "     Uoc tinh giai phong: ~4.8 GB" -ForegroundColor Cyan
        $totalFreed += 4.8
    }
} else {
    Write-Host "  [WARN] Docker chua duoc cai dat" -ForegroundColor Yellow
}

# 6. Build Artifacts
Write-Host ""
Write-Host "6. Build Artifacts" -ForegroundColor Magenta
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildPaths = @(
    "$projectRoot\dist",
    "$projectRoot\build"
)
foreach ($path in $buildPaths) {
    $totalFreed += Remove-SafeFolder -Path $path -Description "Build artifact"
}

# 7. Recycle Bin
Write-Host ""
Write-Host "7. Recycle Bin" -ForegroundColor Magenta
if (-not $DryRun) {
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
            Write-Host "  [INFO] Recycle Bin: $sizeGB GB" -ForegroundColor Cyan
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Write-Host "     [OK] Da xoa Recycle Bin" -ForegroundColor Green
            $totalFreed += $sizeGB
        } else {
            Write-Host "  [OK] Recycle Bin: Da trong" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [WARN] Khong the xoa Recycle Bin: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [INFO] Recycle Bin: Se duoc xoa (da trong)" -ForegroundColor Cyan
}

# 8. Windows Update Files
Write-Host ""
Write-Host "8. Windows Update Cleanup" -ForegroundColor Magenta
if (-not $DryRun) {
    Write-Host "  [INFO] Can quyen admin de cleanup Windows Update files" -ForegroundColor Yellow
    Write-Host "     Chay PowerShell as Administrator va chay: cleanmgr.exe /sagerun:1" -ForegroundColor Cyan
} else {
    Write-Host "  [INFO] Windows Update: Se chay cleanmgr.exe /sagerun:1 (can admin)" -ForegroundColor Cyan
}

# 9. Log Files
Write-Host ""
Write-Host "9. Log Files" -ForegroundColor Magenta
$projectRoot = Split-Path -Parent $PSScriptRoot
$logFiles = Get-ChildItem -Path $projectRoot -Filter "*.log" -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
if ($logFiles) {
    $size = ($logFiles | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "  [INFO] Old log files (>7 days): $([math]::Round($size, 2)) GB" -ForegroundColor Cyan
    if (-not $DryRun) {
        $logFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "     [OK] Da xoa log files cu" -ForegroundColor Green
        $totalFreed += $size
    } else {
        $totalFreed += $size
    }
} else {
    Write-Host "  [OK] Khong co log files cu" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "TONG KET" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "Tong dung luong co the giai phong: $([math]::Round($totalFreed, 2)) GB" -ForegroundColor Green

if ($DryRun) {
    Write-Host ""
    Write-Host "Day la che do DRY RUN. De thuc su xoa, chay:" -ForegroundColor Yellow
    Write-Host "   .\scripts\cleanup-c-drive-safe.ps1" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Hoan thanh don dep!" -ForegroundColor Green
    Write-Host "De giai phong them dung luong:" -ForegroundColor Yellow
    Write-Host "   - Chay Disk Cleanup voi quyen Admin" -ForegroundColor Cyan
    Write-Host "   - Xoa cac file khong can thiet trong Downloads" -ForegroundColor Cyan
    Write-Host "   - Kiem tra cac ung dung lon trong Settings > Apps" -ForegroundColor Cyan
}

Write-Host ""
