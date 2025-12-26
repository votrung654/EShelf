# Script to find Terraform and AWS CLI, then add to PATH

Write-Host "Finding Terraform and AWS CLI..." -ForegroundColor Cyan
Write-Host ""

$terraformFound = $false
$awsFound = $false

# Common installation paths
$terraformPaths = @(
    "C:\Program Files\Terraform\terraform.exe",
    "C:\HashiCorp\Terraform\terraform.exe",
    "C:\Program Files\HashiCorp\Terraform\terraform.exe",
    "$env:USERPROFILE\AppData\Local\Programs\Terraform\terraform.exe",
    "$env:LOCALAPPDATA\Programs\Terraform\terraform.exe"
)

$awsPaths = @(
    "C:\Program Files\Amazon\AWSCLIV2\aws.exe",
    "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe",
    "$env:USERPROFILE\AppData\Local\Programs\Amazon\AWSCLIV2\aws.exe",
    "$env:LOCALAPPDATA\Programs\Amazon\AWSCLIV2\aws.exe"
)

# Find Terraform
Write-Host "Searching for Terraform..." -ForegroundColor Yellow
foreach ($path in $terraformPaths) {
    if (Test-Path $path) {
        $terraformDir = Split-Path $path -Parent
        Write-Host "  Found: $path" -ForegroundColor Green
        $terraformFound = $true
        break
    }
}

# Also check in PATH
if (-not $terraformFound) {
    $terraformInPath = Get-Command terraform -ErrorAction SilentlyContinue
    if ($terraformInPath) {
        Write-Host "  Found in PATH: $($terraformInPath.Source)" -ForegroundColor Green
        $terraformFound = $true
    }
}

# Find AWS CLI
Write-Host "Searching for AWS CLI..." -ForegroundColor Yellow
foreach ($path in $awsPaths) {
    if (Test-Path $path) {
        $awsDir = Split-Path $path -Parent
        Write-Host "  Found: $path" -ForegroundColor Green
        $awsFound = $true
        break
    }
}

# Also check in PATH
if (-not $awsFound) {
    $awsInPath = Get-Command aws -ErrorAction SilentlyContinue
    if ($awsInPath) {
        Write-Host "  Found in PATH: $($awsInPath.Source)" -ForegroundColor Green
        $awsFound = $true
    }
}

Write-Host ""

# Add to PATH if found
$pathsToAdd = @()

if ($terraformFound -and -not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    $terraformDir = Split-Path (Get-ChildItem -Path $terraformPaths -ErrorAction SilentlyContinue | Where-Object { Test-Path $_.FullName } | Select-Object -First 1 -ExpandProperty FullName) -Parent
    if ($terraformDir) {
        $pathsToAdd += $terraformDir
        Write-Host "Will add Terraform to PATH: $terraformDir" -ForegroundColor Yellow
    }
}

if ($awsFound -and -not (Get-Command aws -ErrorAction SilentlyContinue)) {
    $awsDir = Split-Path (Get-ChildItem -Path $awsPaths -ErrorAction SilentlyContinue | Where-Object { Test-Path $_.FullName } | Select-Object -First 1 -ExpandProperty FullName) -Parent
    if ($awsDir) {
        $pathsToAdd += $awsDir
        Write-Host "Will add AWS CLI to PATH: $awsDir" -ForegroundColor Yellow
    }
}

# If found but not in PATH, add them
if ($pathsToAdd.Count -gt 0) {
    Write-Host ""
    Write-Host "Adding to PATH..." -ForegroundColor Cyan
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    foreach ($path in $pathsToAdd) {
        if ($currentPath -notlike "*$path*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$path", "User")
            $env:Path += ";$path"
            Write-Host "  Added: $path" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "PATH updated! Please restart PowerShell or run:" -ForegroundColor Yellow
    Write-Host "  `$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Checking versions..." -ForegroundColor Cyan
Write-Host ""

# Check Terraform version
if ($terraformFound -or (Get-Command terraform -ErrorAction SilentlyContinue)) {
    try {
        $tfVersion = terraform version 2>&1 | Select-Object -First 1
        Write-Host "Terraform: $tfVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "Terraform: Cannot get version" -ForegroundColor Red
    }
}
else {
    Write-Host "Terraform: Not found" -ForegroundColor Red
}

# Check AWS CLI version
if ($awsFound -or (Get-Command aws -ErrorAction SilentlyContinue)) {
    try {
        $awsVersion = aws --version 2>&1
        Write-Host "AWS CLI: $awsVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "AWS CLI: Cannot get version" -ForegroundColor Red
    }
}
else {
    Write-Host "AWS CLI: Not found" -ForegroundColor Red
}

Write-Host ""



