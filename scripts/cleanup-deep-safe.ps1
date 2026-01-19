# Script don dep sau hon - An toan nhung triet de
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
        return 0
    }
    
    $size = Get-FolderSize -Path $Path
    if ($size -eq 0) {
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
        Write-Host "     [WARN] Khong the xoa: $_" -ForegroundColor Yellow
        return 0
    }
}

Write-Host ""
Write-Host "DON DEP SAU - TRIET DE NHUNG AN TOAN" -ForegroundColor Magenta
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

Write-Host "Bat dau don dep sau..." -ForegroundColor Cyan
Write-Host ""

# 1. Python Cache - Toan bo
Write-Host "1. Python Cache (Toan bo)" -ForegroundColor Magenta
$pythonCaches = @(
    "$env:LOCALAPPDATA\pip\Cache",
    "$env:APPDATA\pip\Cache",
    "$env:USERPROFILE\.cache\pip",
    "$env:LOCALAPPDATA\Python*",
    "$env:APPDATA\Python*"
)

# Tim tat ca thu muc Python cache
$pythonPaths = @()
foreach ($pattern in $pythonCaches) {
    if ($pattern -like "*\*") {
        $parent = Split-Path $pattern -Parent
        $filter = Split-Path $pattern -Leaf
        if (Test-Path $parent) {
            $found = Get-ChildItem -Path $parent -Directory -Filter $filter -ErrorAction SilentlyContinue
            $pythonPaths += $found
        }
    } elseif (Test-Path $pattern) {
        $pythonPaths += Get-Item $pattern
    }
}

foreach ($pyPath in $pythonPaths) {
    if ($pyPath) {
        $path = if ($pyPath -is [System.IO.DirectoryInfo]) { $pyPath.FullName } else { $pyPath }
        # Chi xoa cache, khong xoa Python installation
        if ($path -like "*\Cache" -or $path -like "*\cache" -or $path -like "*\__pycache__") {
            $totalFreed += Remove-SafeFolder -Path $path -Description "Python Cache"
        }
    }
}

# Xoa __pycache__ trong toan bo user profile (an toan)
$pycachePaths = @(
    "$env:USERPROFILE\__pycache__",
    "$env:LOCALAPPDATA\__pycache__",
    "$env:APPDATA\__pycache__"
)
foreach ($pycache in $pycachePaths) {
    $totalFreed += Remove-SafeFolder -Path $pycache -Description "Python __pycache__"
}

# 2. Node.js Cache va temp
Write-Host ""
Write-Host "2. Node.js Cache va Temp" -ForegroundColor Magenta
$nodeCaches = @(
    "$env:LOCALAPPDATA\npm-cache",
    "$env:APPDATA\npm",
    "$env:USERPROFILE\.npm",
    "$env:USERPROFILE\.node-gyp",
    "$env:USERPROFILE\.cache\node-gyp"
)
foreach ($cache in $nodeCaches) {
    $totalFreed += Remove-SafeFolder -Path $cache -Description "Node.js Cache"
}

# 3. Yarn va pnpm cache
Write-Host ""
Write-Host "3. Yarn va pnpm Cache" -ForegroundColor Magenta
$yarnCache = "$env:LOCALAPPDATA\Yarn"
if (Test-Path $yarnCache) {
    $yarnSubfolders = Get-ChildItem -Path $yarnCache -Directory -ErrorAction SilentlyContinue
    foreach ($sub in $yarnSubfolders) {
        if ($sub.Name -like "*cache*" -or $sub.Name -like "*Cache*") {
            $totalFreed += Remove-SafeFolder -Path $sub.FullName -Description "Yarn Cache"
        }
    }
}

$pnpmCache = "$env:LOCALAPPDATA\pnpm"
if (Test-Path $pnpmCache) {
    $pnpmSubfolders = Get-ChildItem -Path $pnpmCache -Directory -ErrorAction SilentlyContinue
    foreach ($sub in $pnpmSubfolders) {
        if ($sub.Name -like "*cache*" -or $sub.Name -like "*Cache*") {
            $totalFreed += Remove-SafeFolder -Path $sub.FullName -Description "pnpm Cache"
        }
    }
}

# 4. Visual Studio Code - Xoa them cache
Write-Host ""
Write-Host "4. Visual Studio Code - Cache Bo Sung" -ForegroundColor Magenta
$vscodeMore = @(
    "$env:APPDATA\Code\logs",
    "$env:APPDATA\Code\GPUCache",
    "$env:APPDATA\Code\ShaderCache",
    "$env:APPDATA\Code\CachedExtensions",
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\logs",
    "$env:APPDATA\Code\User\History"
)
foreach ($cache in $vscodeMore) {
    $totalFreed += Remove-SafeFolder -Path $cache -Description "VS Code Cache"
}

# 5. Git Cache va temp
Write-Host ""
Write-Host "5. Git Cache" -ForegroundColor Magenta
$gitCaches = @(
    "$env:USERPROFILE\.gitconfig.backup",
    "$env:USERPROFILE\.git-credentials.backup"
)
foreach ($cache in $gitCaches) {
    if (Test-Path $cache) {
        $size = (Get-Item $cache).Length / 1GB
        Write-Host "  [INFO] Git backup: $([math]::Round($size, 4)) GB" -ForegroundColor Cyan
        if (-not $DryRun) {
            Remove-Item -Path $cache -Force -ErrorAction SilentlyContinue
            Write-Host "     [OK] Da xoa" -ForegroundColor Green
            $totalFreed += $size
        } else {
            $totalFreed += $size
        }
    }
}

# 6. Windows Error Reporting (Crash Dumps)
Write-Host ""
Write-Host "6. Windows Crash Dumps" -ForegroundColor Magenta
$crashDumps = @(
    "$env:LOCALAPPDATA\CrashDumps",
    "$env:LOCALAPPDATA\CrashReports",
    "$env:APPDATA\CrashDumps"
)
foreach ($dump in $crashDumps) {
    $totalFreed += Remove-SafeFolder -Path $dump -Description "Crash Dumps"
}

# 7. Windows Logs (User level)
Write-Host ""
Write-Host "7. Windows User Logs" -ForegroundColor Magenta
$logPaths = @(
    "$env:LOCALAPPDATA\Logs",
    "$env:APPDATA\Logs",
    "$env:USERPROFILE\AppData\Local\Logs"
)
foreach ($logPath in $logPaths) {
    if (Test-Path $logPath) {
        $logFiles = Get-ChildItem -Path $logPath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
        if ($logFiles) {
            $size = ($logFiles | Measure-Object -Property Length -Sum).Sum / 1GB
            Write-Host "  [INFO] Old logs: $([math]::Round($size, 2)) GB" -ForegroundColor Cyan
            if (-not $DryRun) {
                $logFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Host "     [OK] Da xoa log files cu" -ForegroundColor Green
                $totalFreed += $size
            } else {
                $totalFreed += $size
            }
        }
    }
}

# 8. Microsoft Office Cache
Write-Host ""
Write-Host "8. Microsoft Office Cache" -ForegroundColor Magenta
$officeCaches = @(
    "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache",
    "$env:LOCALAPPDATA\Microsoft\Office\UnsavedFiles",
    "$env:APPDATA\Microsoft\Office\Recent"
)
foreach ($cache in $officeCaches) {
    $totalFreed += Remove-SafeFolder -Path $cache -Description "Office Cache"
}

# 9. Teams Cache
Write-Host ""
Write-Host "9. Microsoft Teams Cache" -ForegroundColor Magenta
$teamsCaches = @(
    "$env:APPDATA\Microsoft\Teams\Cache",
    "$env:APPDATA\Microsoft\Teams\logs",
    "$env:APPDATA\Microsoft\Teams\Service Worker\Cache",
    "$env:APPDATA\Microsoft\Teams\blob_storage",
    "$env:APPDATA\Microsoft\Teams\IndexedDB"
)
foreach ($cache in $teamsCaches) {
    $totalFreed += Remove-SafeFolder -Path $cache -Description "Teams Cache"
}

# 10. Windows Store App Cache (chi tiet hon)
Write-Host ""
Write-Host "10. Windows Store App Cache (Chi Tiet)" -ForegroundColor Magenta
$storeApps = Get-ChildItem -Path "$env:LOCALAPPDATA\Packages" -Directory -ErrorAction SilentlyContinue
foreach ($app in $storeApps) {
    $cachePaths = @(
        "$($app.FullName)\TempState",
        "$($app.FullName)\AC\INetCache",
        "$($app.FullName)\AC\INetCookies",
        "$($app.FullName)\AC\Microsoft\CryptnetUrlCache"
    )
    foreach ($cachePath in $cachePaths) {
        if (Test-Path $cachePath) {
            $size = Get-FolderSize -Path $cachePath
            if ($size -gt 0.1) {
                Write-Host "  [INFO] $($app.Name) cache: $size GB" -ForegroundColor Cyan
                if (-not $DryRun) {
                    try {
                        Remove-Item -Path $cachePath -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "     [OK] Da xoa" -ForegroundColor Green
                        $totalFreed += $size
                    } catch {
                        Write-Host "     [WARN] Khong the xoa" -ForegroundColor Yellow
                    }
                } else {
                    $totalFreed += $size
                }
            }
        }
    }
}

# 11. Chocolatey Cache (neu co)
Write-Host ""
Write-Host "11. Chocolatey Cache" -ForegroundColor Magenta
$chocoCache = "$env:ChocolateyInstall\lib-bad"
if (Test-Path $chocoCache) {
    $totalFreed += Remove-SafeFolder -Path $chocoCache -Description "Chocolatey Bad Libs"
}

# 12. Windows Update Download Cache (neu co quyen)
Write-Host ""
Write-Host "12. Windows Update Download Cache" -ForegroundColor Magenta
$wuCache = "C:\Windows\SoftwareDistribution\Download"
if (Test-Path $wuCache) {
    $wuFiles = Get-ChildItem -Path $wuCache -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
    if ($wuFiles) {
        $size = ($wuFiles | Measure-Object -Property Length -Sum).Sum / 1GB
        Write-Host "  [INFO] Old Windows Update files (>30 days): $([math]::Round($size, 2)) GB" -ForegroundColor Cyan
        Write-Host "     [INFO] Can quyen admin de xoa Windows Update cache" -ForegroundColor Yellow
        if (-not $DryRun) {
            try {
                $wuFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Host "     [OK] Da xoa (neu co quyen)" -ForegroundColor Green
                $totalFreed += $size
            } catch {
                Write-Host "     [WARN] Can quyen admin" -ForegroundColor Yellow
            }
        } else {
            $totalFreed += $size
        }
    }
}

# 13. Xoa cac file .tmp, .temp, .log cu trong AppData
Write-Host ""
Write-Host "13. File Temp/Log Cu Trong AppData" -ForegroundColor Magenta
$appDataPaths = @(
    "$env:LOCALAPPDATA",
    "$env:APPDATA"
)
foreach ($appDataPath in $appDataPaths) {
    if (Test-Path $appDataPath) {
        $tempFiles = Get-ChildItem -Path $appDataPath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { 
                ($_.Extension -in @(".tmp", ".temp", ".log", ".cache", ".bak", ".old")) -and
                $_.LastWriteTime -lt (Get-Date).AddDays(-14)
            }
        if ($tempFiles) {
            $size = ($tempFiles | Measure-Object -Property Length -Sum).Sum / 1GB
            Write-Host "  [INFO] Old temp/log files (>14 days): $([math]::Round($size, 2)) GB" -ForegroundColor Cyan
            if (-not $DryRun) {
                $tempFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Host "     [OK] Da xoa" -ForegroundColor Green
                $totalFreed += $size
            } else {
                $totalFreed += $size
            }
        }
    }
}

# 14. Xoa cac thu muc rong
Write-Host ""
Write-Host "14. Xoa Thu Muc Rong" -ForegroundColor Magenta
$emptyDirs = @()
$searchPaths = @(
    "$env:LOCALAPPDATA\Temp",
    "$env:TEMP"
)
foreach ($searchPath in $searchPaths) {
    if (Test-Path $searchPath) {
        $dirs = Get-ChildItem -Path $searchPath -Directory -Recurse -ErrorAction SilentlyContinue
        foreach ($dir in $dirs) {
            $items = Get-ChildItem -Path $dir.FullName -ErrorAction SilentlyContinue
            if ($items.Count -eq 0) {
                $emptyDirs += $dir
            }
        }
    }
}
if ($emptyDirs.Count -gt 0) {
    Write-Host "  [INFO] Tim thay $($emptyDirs.Count) thu muc rong" -ForegroundColor Cyan
    if (-not $DryRun) {
        $emptyDirs | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "     [OK] Da xoa thu muc rong" -ForegroundColor Green
    }
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
    Write-Host "   .\scripts\cleanup-deep-safe.ps1" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Hoan thanh don dep sau!" -ForegroundColor Green
}

Write-Host ""

