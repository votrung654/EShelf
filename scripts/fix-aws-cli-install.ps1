# Script để gỡ bỏ AWS CLI cũ và cài đặt lại bằng cách ít lỗi nhất
# Sử dụng conda Python thay vì Python bị lỗi

Write-Host "=== Bắt đầu quá trình gỡ bỏ và cài đặt lại AWS CLI ===" -ForegroundColor Cyan

# Bước 1: Gỡ bỏ AWS CLI cài đặt qua pip
Write-Host "`n[1/4] Đang gỡ bỏ AWS CLI cài đặt qua pip..." -ForegroundColor Yellow
$pythonPath = "C:\Users\ADMIN\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.11_qbz5n2kfra8p0\LocalCache\local-packages\Python311\Scripts"
if (Test-Path $pythonPath) {
    $awsCmd = Join-Path $pythonPath "aws.cmd"
    $awsExe = Join-Path $pythonPath "aws"
    if (Test-Path $awsCmd) {
        Write-Host "  Tìm thấy aws.cmd, đang xóa..." -ForegroundColor Gray
        Remove-Item $awsCmd -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $awsExe) {
        Write-Host "  Tìm thấy aws, đang xóa..." -ForegroundColor Gray
        Remove-Item $awsExe -Force -ErrorAction SilentlyContinue
    }
    # Xóa thư mục awscli nếu có
    $awsCliDir = Join-Path $pythonPath "awscli"
    if (Test-Path $awsCliDir) {
        Write-Host "  Tìm thấy thư mục awscli, đang xóa..." -ForegroundColor Gray
        Remove-Item $awsCliDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Bước 2: Gỡ bỏ AWS CLI cài đặt qua MSI (nếu có)
Write-Host "`n[2/4] Đang kiểm tra và gỡ bỏ AWS CLI MSI installer..." -ForegroundColor Yellow
$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
if (Test-Path $awsCliPath) {
    Write-Host "  Tìm thấy thư mục AWSCLIV2, đang xóa..." -ForegroundColor Gray
    Remove-Item $awsCliPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Kiểm tra và gỡ bỏ qua winget hoặc uninstaller
$uninstaller = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*AWS CLI*" }
if ($uninstaller) {
    Write-Host "  Tìm thấy AWS CLI trong danh sách cài đặt, đang gỡ bỏ..." -ForegroundColor Gray
    if ($uninstaller.UninstallString) {
        $uninstallCmd = $uninstaller.UninstallString
        if ($uninstallCmd -match 'msiexec') {
            $productCode = $uninstaller.PSChildName
            Start-Process msiexec.exe -ArgumentList "/x $productCode /quiet /norestart" -Wait -NoNewWindow
        }
    }
}

# Bước 3: Cập nhật PATH để sử dụng conda Python
Write-Host "`n[3/4] Đang cập nhật PATH để sử dụng conda Python..." -ForegroundColor Yellow
$condaPython = "D:\conda\python.exe"
if (Test-Path $condaPython) {
    Write-Host "  Conda Python được tìm thấy tại: $condaPython" -ForegroundColor Green
    
    # Lấy PATH hiện tại từ User và System
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    
    # Loại bỏ các đường dẫn Python bị lỗi
    $pathsToRemove = @(
        "*PythonSoftwareFoundation*",
        "*WindowsApps\python.exe*",
        "*AppData\Local\Microsoft\WindowsApps*"
    )
    
    $userPathArray = $userPath -split ';' | Where-Object { 
        $path = $_
        $shouldKeep = $true
        foreach ($pattern in $pathsToRemove) {
            if ($path -like $pattern) {
                $shouldKeep = $false
                break
            }
        }
        $shouldKeep
    }
    
    # Thêm conda Python vào đầu PATH nếu chưa có
    $condaDir = "D:\conda"
    $condaScripts = "D:\conda\Scripts"
    $condaLibrary = "D:\conda\Library\bin"
    
    $newUserPath = @()
    if ($userPathArray -notcontains $condaDir) {
        $newUserPath += $condaDir
    }
    if ($userPathArray -notcontains $condaScripts) {
        $newUserPath += $condaScripts
    }
    if ($userPathArray -notcontains $condaLibrary) {
        $newUserPath += $condaLibrary
    }
    $newUserPath += $userPathArray
    
    $updatedPath = $newUserPath -join ';'
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
    Write-Host "  Đã cập nhật PATH người dùng" -ForegroundColor Green
    
    # Cập nhật PATH trong session hiện tại
    $env:Path = $updatedPath + ';' + $systemPath
    Write-Host "  Đã cập nhật PATH trong session hiện tại" -ForegroundColor Green
} else {
    Write-Host "  CẢNH BÁO: Không tìm thấy conda Python tại $condaPython" -ForegroundColor Red
}

# Bước 4: Cài đặt AWS CLI bằng winget (cách ít lỗi nhất)
Write-Host "`n[4/4] Đang cài đặt AWS CLI bằng winget (cách ít lỗi nhất)..." -ForegroundColor Yellow

$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
$installed = $false

# Kiểm tra xem winget có sẵn không
$wingetAvailable = $false
try {
    $wingetVersion = winget --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $wingetAvailable = $true
        Write-Host "  Tìm thấy winget, đang sử dụng để cài đặt..." -ForegroundColor Gray
    }
} catch {
    Write-Host "  winget không khả dụng, sẽ thử phương pháp khác..." -ForegroundColor Yellow
}

if ($wingetAvailable) {
    try {
        Write-Host "  Đang cài đặt AWS CLI (có thể mất vài phút)..." -ForegroundColor Gray
        Write-Host "  Lưu ý: Có thể xuất hiện hộp thoại UAC, vui lòng chấp nhận." -ForegroundColor Yellow
        
        # Cài đặt bằng winget
        winget install --id Amazon.AWSCLI --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            $installed = $true
            Write-Host "  AWS CLI đã được cài đặt thành công bằng winget!" -ForegroundColor Green
        } else {
            Write-Host "  winget cài đặt không thành công, thử phương pháp MSI..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Lỗi khi sử dụng winget: $_" -ForegroundColor Yellow
    }
}

# Nếu winget không thành công, thử MSI
if (-not $installed) {
    Write-Host "  Đang thử cài đặt bằng MSI installer..." -ForegroundColor Gray
    $awsCliInstallerUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"
    $installerPath = "$env:TEMP\AWSCLIV2.msi"
    
    try {
        Write-Host "  Đang tải AWS CLI installer..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $awsCliInstallerUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Host "  Đang cài đặt AWS CLI với quyền Administrator..." -ForegroundColor Gray
        Write-Host "  Lưu ý: Có thể xuất hiện hộp thoại UAC, vui lòng chấp nhận." -ForegroundColor Yellow
        
        # Chạy với quyền Administrator
        $installArgs = "/i `"$installerPath`" /quiet /norestart"
        $process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru -Verb RunAs -NoNewWindow
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            $installed = $true
            Write-Host "  AWS CLI đã được cài đặt thành công bằng MSI!" -ForegroundColor Green
        } else {
            Write-Host "  Cảnh báo: Exit code = $($process.ExitCode)" -ForegroundColor Yellow
        }
        
        # Xóa file installer
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  Lỗi khi cài đặt bằng MSI: $_" -ForegroundColor Red
    }
}

# Cập nhật PATH để bao gồm AWS CLI
if (Test-Path $awsCliPath) {
    $currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentUserPath -notlike "*$awsCliPath*") {
        $newUserPath = "$awsCliPath;$currentUserPath"
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        Write-Host "  Đã thêm AWS CLI vào PATH người dùng" -ForegroundColor Green
    }
    $env:Path = "$awsCliPath;$env:Path"
}

# Kiểm tra cài đặt
if ($installed -or (Test-Path $awsCliPath)) {
    Start-Sleep -Seconds 3
    $awsExePath = Join-Path $awsCliPath "aws.exe"
    if (Test-Path $awsExePath) {
        $awsVersion = & $awsExePath --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n=== HOÀN TẤT ===" -ForegroundColor Green
            Write-Host "AWS CLI đã được cài đặt thành công!" -ForegroundColor Green
            Write-Host "Phiên bản: $awsVersion" -ForegroundColor Cyan
        } else {
            Write-Host "`n=== CẢNH BÁO ===" -ForegroundColor Yellow
            Write-Host "AWS CLI đã được cài đặt nhưng cần khởi động lại terminal để sử dụng." -ForegroundColor Yellow
            Write-Host "Vui lòng đóng và mở lại PowerShell/terminal." -ForegroundColor Yellow
        }
    } else {
        Write-Host "`n=== CẢNH BÁO ===" -ForegroundColor Yellow
        Write-Host "AWS CLI có thể chưa được cài đặt hoàn toàn." -ForegroundColor Yellow
        Write-Host "Vui lòng khởi động lại terminal và chạy: aws --version" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n=== LỖI ===" -ForegroundColor Red
    Write-Host "Không thể cài đặt AWS CLI tự động." -ForegroundColor Red
    Write-Host "`nVui lòng cài đặt thủ công bằng một trong các cách sau:" -ForegroundColor Yellow
    Write-Host "1. Chạy: winget install Amazon.AWSCLI" -ForegroundColor Cyan
    Write-Host "2. Tải và chạy MSI từ: https://awscli.amazonaws.com/AWSCLIV2.msi" -ForegroundColor Cyan
}

Write-Host "`nLưu ý: Nếu AWS CLI chưa hoạt động, vui lòng khởi động lại terminal/PowerShell." -ForegroundColor Yellow

