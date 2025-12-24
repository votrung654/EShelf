# Test Smart Build Logic
# Test các trường hợp comment vs code changes

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Smart Build Logic" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check script syntax
Write-Host "[Test] Checking script syntax..." -ForegroundColor Yellow

$scriptPath = "scripts/check-service-changes.sh"
if (Test-Path $scriptPath) {
    $content = Get-Content $scriptPath -Raw
    
    # Check for key functions
    $checks = @(
        @{ Pattern = 'CODE_EXTENSIONS'; Name = "Code extensions defined" },
        @{ Pattern = 'CONFIG_EXTENSIONS'; Name = "Config extensions defined" },
        @{ Pattern = 'git diff'; Name = "Git diff command" },
        @{ Pattern = 'grep -vE.*//'; Name = "Comment filtering" },
        @{ Pattern = 'exit.*HAS_REAL_CHANGES'; Name = "Exit code logic" }
    )
    
    $passed = 0
    foreach ($check in $checks) {
        if ($content -match $check.Pattern) {
            Write-Host "  [OK] $($check.Name)" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  [FAIL] $($check.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Script checks: $passed/$($checks.Count) passed" -ForegroundColor $(if ($passed -eq $checks.Count) { "Green" } else { "Yellow" })
} else {
    Write-Host "  [ERROR] Script not found: $scriptPath" -ForegroundColor Red
}

Write-Host ""

# Test 2: Verify workflow integration
Write-Host "[Test] Verifying workflow integration..." -ForegroundColor Yellow

$workflowPath = ".github/workflows/smart-build.yml"
if (Test-Path $workflowPath) {
    $content = Get-Content $workflowPath -Raw
    
    $workflowChecks = @(
        @{ Pattern = 'check-service-changes.sh'; Name = "Script referenced" },
        @{ Pattern = 'BASE_REF'; Name = "Base ref handling" },
        @{ Pattern = 'code-check'; Name = "Code check step" },
        @{ Pattern = 'fetch-depth: 2'; Name = "Fetch depth for diff" }
    )
    
    $passed = 0
    foreach ($check in $workflowChecks) {
        if ($content -match $check.Pattern) {
            Write-Host "  [OK] $($check.Name)" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  [FAIL] $($check.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Workflow checks: $passed/$($workflowChecks.Count) passed" -ForegroundColor $(if ($passed -eq $workflowChecks.Count) { "Green" } else { "Yellow" })
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Build Test Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

