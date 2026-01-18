# Script to safely clean up C: drive
# Run as Administrator for best results

Write-Host "=== C: Drive Cleanup Script ===" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Warning: Not running as Administrator. Some operations may fail." -ForegroundColor Yellow
    Write-Host ""
}

# 1. Clean Windows Temp folder
Write-Host "1. Cleaning Windows Temp folder..." -ForegroundColor Green
$tempPath = $env:TEMP
if (Test-Path $tempPath) {
    try {
        Get-ChildItem -Path $tempPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "   Cleaned Windows Temp folder" -ForegroundColor Green
    } catch {
        Write-Host "   Some files in Temp folder could not be deleted (may be in use)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Temp folder not found" -ForegroundColor Yellow
}

# 2. Clean user Temp folder
Write-Host "2. Cleaning User Temp folder..." -ForegroundColor Green
$userTempPath = "$env:USERPROFILE\AppData\Local\Temp"
if (Test-Path $userTempPath) {
    try {
        Get-ChildItem -Path $userTempPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "   Cleaned User Temp folder" -ForegroundColor Green
    } catch {
        Write-Host "   Some files in User Temp folder could not be deleted" -ForegroundColor Yellow
    }
} else {
    Write-Host "   User Temp folder not found" -ForegroundColor Yellow
}

# 3. Clean npm cache (if exists)
Write-Host "3. Cleaning npm cache..." -ForegroundColor Green
if (Get-Command npm -ErrorAction SilentlyContinue) {
    try {
        npm cache clean --force 2>&1 | Out-Null
        Write-Host "   Cleaned npm cache" -ForegroundColor Green
    } catch {
        Write-Host "   Could not clean npm cache" -ForegroundColor Yellow
    }
} else {
    Write-Host "   npm not found, skipping" -ForegroundColor Yellow
}

# 4. Clean Docker (if exists)
Write-Host "4. Cleaning Docker (if installed)..." -ForegroundColor Green
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        docker system prune -f 2>&1 | Out-Null
        Write-Host "   Cleaned Docker system" -ForegroundColor Green
    } catch {
        Write-Host "   Docker not running or not accessible" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Docker not found, skipping" -ForegroundColor Yellow
}

# 5. Clean Windows Update cache (requires admin)
Write-Host "5. Cleaning Windows Update cache..." -ForegroundColor Green
if ($isAdmin) {
    try {
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Write-Host "   Cleaned Windows Update cache" -ForegroundColor Green
    } catch {
        Write-Host "   Could not clean Windows Update cache" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Skipping (requires Administrator)" -ForegroundColor Yellow
}

# 6. Clean Recycle Bin
Write-Host "6. Cleaning Recycle Bin..." -ForegroundColor Green
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "   Cleaned Recycle Bin" -ForegroundColor Green
} catch {
    Write-Host "   Could not clean Recycle Bin" -ForegroundColor Yellow
}

# 7. Clean browser caches (Chrome, Edge)
Write-Host "7. Cleaning browser caches..." -ForegroundColor Green
$browserPaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
)
foreach ($path in $browserPaths) {
    if (Test-Path $path) {
        try {
            Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "   Cleaned browser cache: $(Split-Path $path -Leaf)" -ForegroundColor Green
        } catch {
            Write-Host "   Could not clean: $(Split-Path $path -Leaf)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=== Cleanup Complete ===" -ForegroundColor Cyan
Write-Host ""

# Show final disk space
$drive = Get-PSDrive C
$freePercent = [math]::Round(($drive.Free/($drive.Used+$drive.Free))*100,2)
$color = if ($freePercent -lt 10) { "Red" } else { "Green" }
Write-Host "C: Drive Status:" -ForegroundColor Cyan
Write-Host "  Used: $([math]::Round($drive.Used/1GB,2)) GB" -ForegroundColor White
Write-Host "  Free: $([math]::Round($drive.Free/1GB,2)) GB" -ForegroundColor White
$percentMsg = "  Free: " + $freePercent.ToString() + " percent"
Write-Host $percentMsg -ForegroundColor $color
