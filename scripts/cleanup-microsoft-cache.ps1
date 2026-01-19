# Script don dep cache trong Microsoft folders
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
Write-Host "DON DEP MICROSOFT CACHE" -ForegroundColor Magenta
Write-Host ""

# Microsoft Office cache
Write-Host "1. Microsoft Office Cache" -ForegroundColor Cyan
$officeCaches = @(
    "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache",
    "$env:LOCALAPPDATA\Microsoft\Office\UnsavedFiles",
    "$env:APPDATA\Microsoft\Office\Recent",
    "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache\*"
)

foreach ($cache in $officeCaches) {
    if ($cache -like "*\*") {
        $parent = Split-Path $cache -Parent
        if (Test-Path $parent) {
            $items = Get-ChildItem -Path $parent -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                $size = Get-FolderSize -Path $item.FullName
                if ($size -gt 0.1) {
                    Write-Host "  [INFO] $($item.Name): ${size} GB" -ForegroundColor Cyan
                    try {
                        Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "    [OK] Da xoa" -ForegroundColor Green
                        $totalFreed += $size
                    } catch {
                        Write-Host "    [WARN] Khong the xoa" -ForegroundColor Yellow
                    }
                }
            }
        }
    } else {
        $size = Get-FolderSize -Path $cache
        if ($size -gt 0.1) {
            Write-Host "  [INFO] ${cache}: ${size} GB" -ForegroundColor Cyan
            try {
                Remove-Item -Path $cache -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "    [OK] Da xoa" -ForegroundColor Green
                $totalFreed += $size
            } catch {
                Write-Host "    [WARN] Khong the xoa" -ForegroundColor Yellow
            }
        }
    }
}

# Microsoft Edge cache (neu chua xoa)
Write-Host ""
Write-Host "2. Microsoft Edge Cache" -ForegroundColor Cyan
$edgeCaches = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\ShaderCache"
)
foreach ($cache in $edgeCaches) {
    $size = Get-FolderSize -Path $cache
    if ($size -gt 0.1) {
        Write-Host "  [INFO] ${cache}: ${size} GB" -ForegroundColor Cyan
        try {
            Remove-Item -Path $cache -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    [OK] Da xoa" -ForegroundColor Green
            $totalFreed += $size
        } catch {
            Write-Host "    [WARN] Khong the xoa" -ForegroundColor Yellow
        }
    }
}

# Windows Defender cache
Write-Host ""
Write-Host "3. Windows Defender Cache" -ForegroundColor Cyan
$defenderCache = "$env:PROGRAMDATA\Microsoft\Windows Defender\Quarantine"
if (Test-Path $defenderCache) {
    $size = Get-FolderSize -Path $defenderCache
    if ($size -gt 0.1) {
        Write-Host "  [INFO] Defender Quarantine: $size GB" -ForegroundColor Cyan
        Write-Host "    [INFO] Can quyen admin de xoa" -ForegroundColor Yellow
        try {
            Remove-Item -Path $defenderCache -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    [OK] Da xoa (neu co quyen)" -ForegroundColor Green
            $totalFreed += $size
        } catch {
            Write-Host "    [WARN] Can quyen admin" -ForegroundColor Yellow
        }
    }
}

# Microsoft Visual Studio cache
Write-Host ""
Write-Host "4. Visual Studio Cache" -ForegroundColor Cyan
$vsCaches = @(
    "$env:LOCALAPPDATA\Microsoft\VisualStudio\*\ComponentModelCache",
    "$env:LOCALAPPDATA\Microsoft\VisualStudio\*\Extensions",
    "$env:APPDATA\Microsoft\VisualStudio\*\Extensions"
)
foreach ($cachePattern in $vsCaches) {
    $parent = Split-Path $cachePattern -Parent
    $filter = Split-Path $cachePattern -Leaf
    if (Test-Path $parent) {
        $folders = Get-ChildItem -Path $parent -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $folders) {
            $targetPath = Join-Path $folder.FullName $filter
            if (Test-Path $targetPath) {
                $size = Get-FolderSize -Path $targetPath
                if ($size -gt 0.5) {
                    Write-Host "  [INFO] ${targetPath}: ${size} GB" -ForegroundColor Cyan
                    try {
                        Remove-Item -Path $targetPath -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "    [OK] Da xoa" -ForegroundColor Green
                        $totalFreed += $size
                    } catch {
                        Write-Host "    [WARN] Khong the xoa" -ForegroundColor Yellow
                    }
                }
            }
        }
    }
}

# Microsoft Teams cache (bo sung)
Write-Host ""
Write-Host "5. Microsoft Teams Cache (Bo Sung)" -ForegroundColor Cyan
$teamsMore = @(
    "$env:APPDATA\Microsoft\Teams\IndexedDB",
    "$env:APPDATA\Microsoft\Teams\Local Storage",
    "$env:APPDATA\Microsoft\Teams\Session Storage",
    "$env:APPDATA\Microsoft\Teams\GPUCache"
)
foreach ($cache in $teamsMore) {
    $size = Get-FolderSize -Path $cache
    if ($size -gt 0.1) {
        Write-Host "  [INFO] ${cache}: ${size} GB" -ForegroundColor Cyan
        try {
            Remove-Item -Path $cache -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    [OK] Da xoa" -ForegroundColor Green
            $totalFreed += $size
        } catch {
            Write-Host "    [WARN] Khong the xoa" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "TONG KET" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "Tong dung luong da giai phong: $([math]::Round($totalFreed, 2)) GB" -ForegroundColor Green
Write-Host ""

