# Add Terraform to PATH

$terraformPath = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe"

if (Test-Path "$terraformPath\terraform.exe") {
    Write-Host "Found Terraform at: $terraformPath" -ForegroundColor Green
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$terraformPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$terraformPath", "User")
        $env:Path += ";$terraformPath"
        Write-Host "Added Terraform to PATH" -ForegroundColor Green
    } else {
        Write-Host "Terraform already in PATH" -ForegroundColor Yellow
    }
    
    # Refresh PATH in current session
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
    
    # Test
    Write-Host ""
    Write-Host "Testing Terraform..." -ForegroundColor Cyan
    terraform version
} else {
    Write-Host "Terraform not found at expected location" -ForegroundColor Red
}



