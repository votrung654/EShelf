# Script khôi phục Infrastructure sau khi bị destroy
# Tự động cập nhật cấu hình và tạo lại resources
# Usage: .\scripts\restore-infrastructure.ps1 [-Environment dev] [-Region ap-southeast-2] [-SkipK3s] [-SkipApps] [-AutoApprove]

param(
    [string]$Environment = "dev",
    [string]$Region = "ap-southeast-2",
    [switch]$SkipK3s,
    [switch]$SkipApps,
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Infrastructure Recovery Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host ""

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')

# Step 0: Prerequisites Check
Write-Host "[Step 0] Checking Prerequisites..." -ForegroundColor Yellow

# Check Terraform
$terraformFound = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $terraformFound) {
    Write-Host "  [ERROR] Terraform not found!" -ForegroundColor Red
    Write-Host "  Install: choco install terraform" -ForegroundColor Yellow
    exit 1
} else {
    $tfVersion = terraform version 2>&1 | Select-Object -First 1
    Write-Host "  [OK] Terraform: $tfVersion" -ForegroundColor Green
}

# Check AWS CLI - try multiple locations
$awsPath = $null
$awsPaths = @(
    "C:\Program Files\Amazon\AWSCLIV2\aws.exe",
    "D:\conda\Scripts\aws.exe",
    "D:\conda\Scripts\aws.cmd"
)

foreach ($path in $awsPaths) {
    if (Test-Path $path) {
        $awsPath = $path
        break
    }
}

# Also try to find via Get-Command
if (-not $awsPath) {
    $awsCmd = Get-Command aws -ErrorAction SilentlyContinue
    if ($awsCmd) {
        $awsPath = $awsCmd.Source
    }
}

if (-not $awsPath) {
    Write-Host "  [WARN] AWS CLI not found" -ForegroundColor Yellow
    Write-Host "  Install: winget install Amazon.AWSCLIV2" -ForegroundColor Yellow
    Write-Host "  Or install via conda: conda install -c conda-forge awscli" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] AWS CLI found at: $awsPath" -ForegroundColor Green
}

# Check AWS credentials
Write-Host "`n[Step 0.1] Checking AWS credentials..." -ForegroundColor Yellow
if (-not $awsPath) {
    Write-Host "  [ERROR] AWS CLI not found!" -ForegroundColor Red
    exit 1
}

# Run AWS command and capture output, ignoring stderr warnings
$ErrorActionPreference = "SilentlyContinue"
$identityOutput = & $awsPath sts get-caller-identity 2>$null
$ErrorActionPreference = "Stop"

# Try to extract JSON from output
$jsonText = $null
if ($identityOutput) {
    # If output is already an object (from ConvertFrom-Json in some cases)
    if ($identityOutput -is [PSCustomObject] -and $identityOutput.Account) {
        $identityObj = $identityOutput
        $jsonText = $identityOutput | ConvertTo-Json
    } else {
        # Try to find JSON in string output
        $jsonMatch = ($identityOutput | Out-String) | Select-String -Pattern '\{[\s\S]*"Account"[\s\S]*\}' -AllMatches
        if ($jsonMatch -and $jsonMatch.Matches.Count -gt 0) {
            $jsonText = $jsonMatch.Matches[0].Value
        } else {
            # Try direct conversion
            try {
                $identityObj = $identityOutput | ConvertFrom-Json
                if ($identityObj.Account) {
                    $jsonText = $identityOutput | ConvertTo-Json
                }
            } catch {
                # Ignore
            }
        }
    }
}

if ($jsonText) {
    try {
        if (-not $identityObj) {
            $identityObj = $jsonText | ConvertFrom-Json
        }
        if ($identityObj.Account) {
            Write-Host "  [OK] AWS credentials configured" -ForegroundColor Green
            Write-Host "    Account ID: $($identityObj.Account)" -ForegroundColor Gray
            Write-Host "    User ARN: $($identityObj.Arn)" -ForegroundColor Gray
        } else {
            throw "Invalid credentials response"
        }
    } catch {
        Write-Host "  [ERROR] Could not parse AWS credentials!" -ForegroundColor Red
        Write-Host "  Run: aws configure" -ForegroundColor Yellow
        Write-Host "  Or use: .\scripts\setup-aws-credentials.ps1" -ForegroundColor Yellow
        exit 1
    }
} else {
    # Try one more time with direct command
    try {
        $testOutput = aws sts get-caller-identity 2>$null | ConvertFrom-Json
        if ($testOutput.Account) {
            Write-Host "  [OK] AWS credentials configured" -ForegroundColor Green
            Write-Host "    Account ID: $($testOutput.Account)" -ForegroundColor Gray
            Write-Host "    User ARN: $($testOutput.Arn)" -ForegroundColor Gray
        } else {
            throw "Invalid response"
        }
    } catch {
        Write-Host "  [ERROR] AWS credentials not configured!" -ForegroundColor Red
        Write-Host "  Run: aws configure" -ForegroundColor Yellow
        Write-Host "  Or use: .\scripts\setup-aws-credentials.ps1" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""

# Step 1: Auto-update Terraform Configuration
Write-Host "[Step 1] Auto-updating Terraform Configuration..." -ForegroundColor Yellow

$terraformDir = "infrastructure\terraform\environments\$Environment"

if (-not (Test-Path $terraformDir)) {
    Write-Host "  [ERROR] Terraform directory not found: $terraformDir" -ForegroundColor Red
    exit 1
}

# Check if auto-update script exists
if (Test-Path "scripts\auto-update-terraform-config.ps1") {
    Write-Host "  [INFO] Running auto-update-terraform-config.ps1..." -ForegroundColor Cyan
    try {
        & "scripts\auto-update-terraform-config.ps1" -Region $Region -TerraformDir $terraformDir
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Terraform configuration updated" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Auto-update script had issues, continuing with existing config..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [WARN] Auto-update failed: $_. Continuing with existing config..." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] auto-update-terraform-config.ps1 not found, skipping..." -ForegroundColor Yellow
}

# Step 2: Terraform Init, Plan, and Apply
Write-Host "`n[Step 2] Running Terraform..." -ForegroundColor Yellow

Push-Location $terraformDir

try {
    # 2.1 Terraform Init
    Write-Host "`n  [2.1] Initializing Terraform..." -ForegroundColor Cyan
    terraform init -upgrade
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed"
    }
    Write-Host "  [OK] Terraform initialized" -ForegroundColor Green
    
    # 2.2 Terraform Validate
    Write-Host "`n  [2.2] Validating Terraform configuration..." -ForegroundColor Cyan
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform validate failed"
    }
    Write-Host "  [OK] Terraform validation passed" -ForegroundColor Green
    
    # 2.3 Try to force unlock if locked (optional, may fail if lock is valid)
    Write-Host "`n  [2.3] Checking for state lock..." -ForegroundColor Cyan
    try {
        $lockInfo = terraform force-unlock -force 2>&1 | Out-String
        if ($lockInfo -match "Lock ID") {
            Write-Host "  [INFO] Attempting to unlock state..." -ForegroundColor Yellow
            # Extract lock ID if possible
            if ($lockInfo -match 'ID:\s*([a-f0-9-]+)') {
                $lockId = $matches[1]
                terraform force-unlock -force $lockId 2>&1 | Out-Null
                Write-Host "  [INFO] State unlock attempted" -ForegroundColor Yellow
            }
        }
    } catch {
        # Ignore unlock errors
        Write-Host "  [INFO] No lock to unlock or unlock failed (continuing...)" -ForegroundColor Yellow
    }
    
    # 2.4 Terraform Plan (with -lock=false to avoid lock issues)
    Write-Host "`n  [2.4] Running Terraform plan..." -ForegroundColor Cyan
    terraform plan -out=tfplan -lock=false
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed"
    }
    Write-Host "  [OK] Terraform plan completed" -ForegroundColor Green
    
    # 2.5 Terraform Apply
    Write-Host "`n  [2.5] Applying Terraform configuration..." -ForegroundColor Cyan
    Write-Host "  [WARN] This will create AWS resources and may incur costs!" -ForegroundColor Yellow
    
    if ($AutoApprove) {
        terraform apply -auto-approve -lock=false tfplan
    } else {
        $confirm = Read-Host "  Do you want to proceed with terraform apply? (yes/no)"
        if ($confirm -eq "yes") {
            terraform apply -lock=false tfplan
        } else {
            Write-Host "  [INFO] Terraform apply cancelled by user" -ForegroundColor Yellow
            Pop-Location
            exit 0
        }
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed"
    }
    Write-Host "  [OK] Terraform apply completed" -ForegroundColor Green
    
    # 2.6 Get Terraform Outputs
    Write-Host "`n  [2.6] Getting Terraform outputs..." -ForegroundColor Cyan
    terraform output -json | Out-File -FilePath "terraform-outputs.json" -Encoding UTF8
    Write-Host "  [OK] Terraform outputs saved to terraform-outputs.json" -ForegroundColor Green
    
    # Display key outputs
    $outputs = terraform output
    Write-Host "`n  Key Infrastructure Resources:" -ForegroundColor Cyan
    Write-Host $outputs -ForegroundColor Gray
    
} catch {
    Write-Host "  [ERROR] Terraform step failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

# Step 3: Update Ansible Inventory
if (-not $SkipK3s) {
    Write-Host "`n[Step 3] Updating Ansible Inventory..." -ForegroundColor Yellow
    
    if (Test-Path "scripts\update-ansible-inventory.ps1") {
        Write-Host "  [INFO] Running update-ansible-inventory.ps1..." -ForegroundColor Cyan
        try {
            & "scripts\update-ansible-inventory.ps1" -Environment $Environment
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Ansible inventory updated" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] Ansible inventory update had issues" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  [WARN] Ansible inventory update failed: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] update-ansible-inventory.ps1 not found, skipping..." -ForegroundColor Yellow
    }
}

# Step 4: Deploy K3s Cluster (optional)
if (-not $SkipK3s) {
    Write-Host "`n[Step 4] Deploying K3s Cluster..." -ForegroundColor Yellow
    
    $ansibleDir = "infrastructure\ansible"
    
    if (-not (Test-Path $ansibleDir)) {
        Write-Host "  [WARN] Ansible directory not found: $ansibleDir" -ForegroundColor Yellow
        Write-Host "  [INFO] Skipping K3s deployment" -ForegroundColor Yellow
    } else {
        $ansibleFound = Get-Command ansible-playbook -ErrorAction SilentlyContinue
        if (-not $ansibleFound) {
            Write-Host "  [WARN] Ansible not found!" -ForegroundColor Yellow
            Write-Host "  [INFO] Install: pip install ansible" -ForegroundColor Yellow
            Write-Host "  [INFO] Skipping K3s deployment" -ForegroundColor Yellow
        } else {
            Push-Location $ansibleDir
            
            try {
                Write-Host "  [INFO] Running Ansible playbook to deploy K3s..." -ForegroundColor Cyan
                
                if ($AutoApprove) {
                    ansible-playbook -i inventory/$Environment.ini playbooks/k3s-cluster.yml
                } else {
                    $confirm = Read-Host "  Do you want to deploy K3s cluster? (yes/no)"
                    if ($confirm -eq "yes") {
                        ansible-playbook -i inventory/$Environment.ini playbooks/k3s-cluster.yml
                    } else {
                        Write-Host "  [INFO] K3s deployment cancelled by user" -ForegroundColor Yellow
                        Pop-Location
                    }
                }
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  [OK] K3s cluster deployed" -ForegroundColor Green
                } else {
                    Write-Host "  [WARN] K3s deployment had issues" -ForegroundColor Yellow
                }
                
            } catch {
                Write-Host "  [WARN] K3s deployment failed: $_" -ForegroundColor Yellow
            } finally {
                Pop-Location
            }
        }
    }
} else {
    Write-Host "`n[Step 4] Skipping K3s deployment (--SkipK3s specified)" -ForegroundColor Yellow
}

# Step 5: Deploy Applications (optional)
if (-not $SkipApps) {
    Write-Host "`n[Step 5] Deploying Applications..." -ForegroundColor Yellow
    
    $kubectlFound = Get-Command kubectl -ErrorAction SilentlyContinue
    if (-not $kubectlFound) {
        Write-Host "  [WARN] kubectl not found!" -ForegroundColor Yellow
        Write-Host "  [INFO] Skipping application deployment" -ForegroundColor Yellow
    } else {
        # Check if cluster is accessible
        try {
            $nodes = kubectl get nodes 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  [WARN] Cannot connect to cluster" -ForegroundColor Yellow
                Write-Host "  [INFO] Make sure kubeconfig is set up correctly" -ForegroundColor Yellow
                Write-Host "  [INFO] Skipping application deployment" -ForegroundColor Yellow
            } else {
                Write-Host "  [OK] Cluster is accessible" -ForegroundColor Green
                
                # Deploy ArgoCD
                Write-Host "`n  [5.1] Deploying ArgoCD..." -ForegroundColor Cyan
                kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - 2>&1 | Out-Null
                kubectl apply -n argocd -f infrastructure/kubernetes/argocd/ 2>&1 | Out-Null
                Write-Host "  [OK] ArgoCD deployment initiated" -ForegroundColor Green
                
                # Deploy Monitoring
                Write-Host "`n  [5.2] Deploying Monitoring Stack..." -ForegroundColor Cyan
                if (Test-Path "infrastructure/kubernetes/monitoring") {
                    kubectl apply -f infrastructure/kubernetes/monitoring/ 2>&1 | Out-Null
                    Write-Host "  [OK] Monitoring stack deployed" -ForegroundColor Green
                } else {
                    Write-Host "  [WARN] Monitoring directory not found, skipping..." -ForegroundColor Yellow
                }
                
                # Deploy Harbor
                Write-Host "`n  [5.3] Deploying Harbor Registry..." -ForegroundColor Cyan
                if (Test-Path "infrastructure/kubernetes/harbor") {
                    kubectl apply -f infrastructure/kubernetes/harbor/ 2>&1 | Out-Null
                    Write-Host "  [OK] Harbor deployed" -ForegroundColor Green
                } else {
                    Write-Host "  [WARN] Harbor directory not found, skipping..." -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "  [WARN] Application deployment failed: $_" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "`n[Step 5] Skipping application deployment (--SkipApps specified)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Recovery Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  ✅ Terraform configuration updated" -ForegroundColor Green
Write-Host "  ✅ Infrastructure resources created" -ForegroundColor Green
if (-not $SkipK3s) {
    Write-Host "  ✅ Ansible inventory updated" -ForegroundColor Green
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Verify infrastructure: cd infrastructure\terraform\environments\$Environment && terraform output" -ForegroundColor White
if (-not $SkipK3s) {
    Write-Host "  2. Verify K3s cluster: kubectl get nodes" -ForegroundColor White
    Write-Host "  3. Get ArgoCD password:" -ForegroundColor White
    Write-Host "     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(`$_)) }" -ForegroundColor Gray
    Write-Host "  4. Port-forward ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor White
}
Write-Host ""

