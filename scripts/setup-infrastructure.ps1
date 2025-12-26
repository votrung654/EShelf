# Comprehensive Infrastructure Setup Script
# Automates steps from NEXT_STEPS.md
# Usage: .\scripts\setup-infrastructure.ps1 [-Environment dev] [-SkipTerraform] [-SkipK3s] [-SkipApps]

param(
    [string]$Environment = "dev",
    [switch]$SkipTerraform,
    [switch]$SkipK3s,
    [switch]$SkipApps,
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Infrastructure Setup Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

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

# Check AWS CLI (using safe method)
$awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
if (-not (Test-Path $awsPath)) {
    Write-Host "  [WARN] AWS CLI not found at default path" -ForegroundColor Yellow
    Write-Host "  Install: winget install Amazon.AWSCLIV2" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] AWS CLI found" -ForegroundColor Green
}

# Check kubectl
$kubectlFound = Get-Command kubectl -ErrorAction SilentlyContinue
if (-not $kubectlFound) {
    Write-Host "  [WARN] kubectl not found" -ForegroundColor Yellow
} else {
    $kubectlVersion = kubectl version --client 2>&1 | Select-Object -First 1
    Write-Host "  [OK] kubectl: $kubectlVersion" -ForegroundColor Green
}

# Check AWS credentials
Write-Host "`n[Step 0.1] Checking AWS credentials..." -ForegroundColor Yellow
try {
    # Use direct path to avoid hanging
    $identity = & $awsPath sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        $identityObj = $identity | ConvertFrom-Json
        Write-Host "  [OK] AWS credentials configured" -ForegroundColor Green
        Write-Host "    Account ID: $($identityObj.Account)" -ForegroundColor Gray
        Write-Host "    User ARN: $($identityObj.Arn)" -ForegroundColor Gray
    } else {
        throw "Credentials not configured"
    }
} catch {
    Write-Host "  [ERROR] AWS credentials not configured!" -ForegroundColor Red
    Write-Host "  Run: aws configure" -ForegroundColor Yellow
    Write-Host "  Or use: .\scripts\setup-aws-credentials.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 1: Terraform Setup
if (-not $SkipTerraform) {
    Write-Host "[Step 1] Setting up Terraform Infrastructure..." -ForegroundColor Yellow
    
    $terraformDir = "infrastructure\terraform\environments\$Environment"
    
    if (-not (Test-Path $terraformDir)) {
        Write-Host "  [ERROR] Terraform directory not found: $terraformDir" -ForegroundColor Red
        exit 1
    }
    
    Push-Location $terraformDir
    
    try {
        # 1.1 Validate Terraform files
        Write-Host "`n  [1.1] Validating Terraform configuration..." -ForegroundColor Cyan
        terraform init -backend=false
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
        
        terraform validate
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform validate failed"
        }
        
        Write-Host "  [OK] Terraform validation passed" -ForegroundColor Green
        
        # 1.2 Check for terraform.tfvars
        Write-Host "`n  [1.2] Checking terraform.tfvars..." -ForegroundColor Cyan
        if (-not (Test-Path "terraform.tfvars")) {
            if (Test-Path "terraform.tfvars.example") {
                Write-Host "  [INFO] Creating terraform.tfvars from example..." -ForegroundColor Yellow
                Copy-Item "terraform.tfvars.example" "terraform.tfvars"
                Write-Host "  [OK] Created terraform.tfvars" -ForegroundColor Green
                Write-Host "  [WARN] Please review and edit terraform.tfvars if needed" -ForegroundColor Yellow
            } else {
                Write-Host "  [WARN] terraform.tfvars not found and no example available" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [OK] terraform.tfvars exists" -ForegroundColor Green
        }
        
        # 1.3 Terraform Init
        Write-Host "`n  [1.3] Initializing Terraform..." -ForegroundColor Cyan
        terraform init
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
        Write-Host "  [OK] Terraform initialized" -ForegroundColor Green
        
        # 1.4 Terraform Plan
        Write-Host "`n  [1.4] Running Terraform plan..." -ForegroundColor Cyan
        terraform plan -out=tfplan
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform plan failed"
        }
        Write-Host "  [OK] Terraform plan completed" -ForegroundColor Green
        
        # 1.5 Terraform Apply
        Write-Host "`n  [1.5] Applying Terraform configuration..." -ForegroundColor Cyan
        Write-Host "  [WARN] This will create AWS resources and may incur costs!" -ForegroundColor Yellow
        
        if ($AutoApprove) {
            terraform apply -auto-approve tfplan
        } else {
            $confirm = Read-Host "  Do you want to proceed with terraform apply? (yes/no)"
            if ($confirm -eq "yes") {
                terraform apply tfplan
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
        
        # 1.6 Get Terraform Outputs
        Write-Host "`n  [1.6] Getting Terraform outputs..." -ForegroundColor Cyan
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
} else {
    Write-Host "[Step 1] Skipping Terraform (--SkipTerraform specified)" -ForegroundColor Yellow
}

# Step 2: Update Ansible Inventory
if (-not $SkipK3s) {
    Write-Host "`n[Step 2] Updating Ansible Inventory..." -ForegroundColor Yellow
    
    $terraformDir = "infrastructure\terraform\environments\$Environment"
    $ansibleDir = "infrastructure\ansible"
    
    if (Test-Path "$terraformDir\terraform-outputs.json") {
        Write-Host "  [INFO] Terraform outputs found, updating Ansible inventory..." -ForegroundColor Cyan
        
        if (Test-Path "scripts\update-ansible-inventory.ps1") {
            & "scripts\update-ansible-inventory.ps1" -Environment $Environment
            Write-Host "  [OK] Ansible inventory updated" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] update-ansible-inventory.ps1 not found, skipping..." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] terraform-outputs.json not found, skipping inventory update" -ForegroundColor Yellow
    }
}

# Step 3: Deploy K3s Cluster
if (-not $SkipK3s) {
    Write-Host "`n[Step 3] Deploying K3s Cluster..." -ForegroundColor Yellow
    
    $ansibleDir = "infrastructure\ansible"
    
    if (-not (Test-Path $ansibleDir)) {
        Write-Host "  [ERROR] Ansible directory not found: $ansibleDir" -ForegroundColor Red
        exit 1
    }
    
    $ansibleFound = Get-Command ansible-playbook -ErrorAction SilentlyContinue
    if (-not $ansibleFound) {
        Write-Host "  [ERROR] Ansible not found!" -ForegroundColor Red
        Write-Host "  Install: pip install ansible" -ForegroundColor Yellow
        exit 1
    }
    
    Push-Location $ansibleDir
    
    try {
        Write-Host "  [INFO] Running Ansible playbook to deploy K3s..." -ForegroundColor Cyan
        
        if ($AutoApprove) {
            ansible-playbook -i inventory/hosts.ini playbooks/k3s-cluster.yml
        } else {
            $confirm = Read-Host "  Do you want to deploy K3s cluster? (yes/no)"
            if ($confirm -eq "yes") {
                ansible-playbook -i inventory/hosts.ini playbooks/k3s-cluster.yml
            } else {
                Write-Host "  [INFO] K3s deployment cancelled by user" -ForegroundColor Yellow
                Pop-Location
                exit 0
            }
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Ansible playbook failed"
        }
        
        Write-Host "  [OK] K3s cluster deployed" -ForegroundColor Green
        
        # Verify cluster
        Write-Host "`n  [INFO] Verifying cluster..." -ForegroundColor Cyan
        if (Test-Path "scripts\verify-k3s-cluster.ps1") {
            & "scripts\verify-k3s-cluster.ps1"
        } else {
            Write-Host "  [INFO] Run: kubectl get nodes" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  [ERROR] K3s deployment failed: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    } finally {
        Pop-Location
    }
} else {
    Write-Host "[Step 3] Skipping K3s deployment (--SkipK3s specified)" -ForegroundColor Yellow
}

# Step 4: Deploy Applications
if (-not $SkipApps) {
    Write-Host "`n[Step 4] Deploying Applications..." -ForegroundColor Yellow
    
    $kubectlFound = Get-Command kubectl -ErrorAction SilentlyContinue
    if (-not $kubectlFound) {
        Write-Host "  [ERROR] kubectl not found!" -ForegroundColor Red
        exit 1
    }
    
    # Check if cluster is accessible
    try {
        $nodes = kubectl get nodes 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot connect to cluster"
        }
        Write-Host "  [OK] Cluster is accessible" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Cannot connect to Kubernetes cluster!" -ForegroundColor Red
        Write-Host "  Make sure kubeconfig is set up correctly" -ForegroundColor Yellow
        exit 1
    }
    
    # Deploy ArgoCD
    Write-Host "`n  [4.1] Deploying ArgoCD..." -ForegroundColor Cyan
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n argocd -f infrastructure/kubernetes/argocd/ 2>&1 | Out-Null
    
    Write-Host "  [OK] ArgoCD deployment initiated" -ForegroundColor Green
    Write-Host "  [INFO] Waiting for ArgoCD to be ready..." -ForegroundColor Gray
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s 2>&1 | Out-Null
    
    # Deploy Monitoring
    Write-Host "`n  [4.2] Deploying Monitoring Stack..." -ForegroundColor Cyan
    if (Test-Path "infrastructure/kubernetes/monitoring") {
        kubectl apply -f infrastructure/kubernetes/monitoring/ 2>&1 | Out-Null
        Write-Host "  [OK] Monitoring stack deployed" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Monitoring directory not found, skipping..." -ForegroundColor Yellow
    }
    
    # Deploy Harbor
    Write-Host "`n  [4.3] Deploying Harbor Registry..." -ForegroundColor Cyan
    if (Test-Path "infrastructure/kubernetes/harbor") {
        kubectl apply -f infrastructure/kubernetes/harbor/ 2>&1 | Out-Null
        Write-Host "  [OK] Harbor deployed" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Harbor directory not found, skipping..." -ForegroundColor Yellow
    }
    
} else {
    Write-Host "[Step 4] Skipping application deployment (--SkipApps specified)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Verify cluster: kubectl get nodes" -ForegroundColor Cyan
Write-Host "  2. Get ArgoCD password:" -ForegroundColor Cyan
Write-Host "     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(`$_)) }" -ForegroundColor Gray
Write-Host "  3. Port-forward ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor Cyan
Write-Host "  4. Access ArgoCD UI: https://localhost:8080" -ForegroundColor Cyan
Write-Host ""

