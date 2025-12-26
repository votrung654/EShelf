# Script to remove all emojis from files
# This script processes files and removes emoji characters

$files = @(
    "backend\SERVICES_DATABASE_SYNC.md",
    "docs\CLEANUP_C_DRIVE_GUIDE.md",
    "scripts\verify-aws-setup.ps1",
    "SECURITY_ANSWERS.md",
    "backend\FRESH_CLONE_TEST.md",
    "backend\DATABASE_FIX.md",
    "backend\TROUBLESHOOTING.md",
    "SECURITY_AUDIT_REPORT.md",
    "scripts\get-kubeconfig-simple.ps1",
    "scripts\deploy-k3s-simple.ps1",
    "scripts\get-kubeconfig.ps1",
    "scripts\deploy-k3s-via-ssm.ps1",
    "scripts\wait-and-deploy-apps.ps1",
    "docs\AWS_ACCOUNT_EXPIRED_GUIDE.md",
    "docs\AWS_FREE_TIER_SETUP_GUIDE.md",
    "scripts\wait-and-deploy.ps1",
    "scripts\verify-k3s-cluster.ps1",
    "scripts\setup-terraform-for-region.ps1",
    "scripts\setup-ssh-for-ansible.ps1",
    "scripts\setup-new-aws-account.ps1",
    "scripts\get-ami-id.ps1",
    "scripts\deploy-applications.ps1",
    "scripts\create-fresh-terraform-tfvars.ps1",
    "DEMO_GUIDE.md",
    "docs\AWS_ACADEMY_SSO_GUIDE.md",
    "docs\BROWSER_TESTING_GUIDE.md",
    "QUICK_START_AWS.md",
    "infrastructure\terraform\environments\dev\NO_KEY_PAIR_SOLUTIONS.md",
    "PHASE2_DEPLOYMENT_GUIDE.md",
    "PHASE1_AND_PHASE2_GUIDE.md",
    "docs\AUTOMATION_GUIDE.md",
    "scripts\update-ansible-inventory.ps1",
    "scripts\auto-update-terraform-config.ps1",
    "TERRAFORM_AMI_FIX.md",
    "infrastructure\terraform\environments\dev\TERRAFORM_FIX_GUIDE.md",
    "SETUP_WITHOUT_AWS.md",
    "ENV_SETUP_GUIDE.md"
)

$count = 0
foreach ($filePath in $files) {
    $fullPath = Join-Path ".." $filePath
    if (Test-Path $fullPath) {
        try {
            $content = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
            $originalContent = $content
            
            # Remove common emoji patterns using simple string replacement
            $emojiPatterns = @(
                '🎉', '🚀', '✨', '💡', '📝', '🔧', '⚡', '🔥', '💻', '📦',
                '🎯', '✅', '❌', '⚠️', '🔒', '🔐', '🛡️', '📊', '📈', '📉'
            )
            
            foreach ($emoji in $emojiPatterns) {
                $content = $content.Replace($emoji, '')
            }
            
            if ($content -ne $originalContent) {
                [System.IO.File]::WriteAllText($fullPath, $content, [System.Text.Encoding]::UTF8)
                Write-Host "Removed emojis from: $filePath"
                $count++
            }
        } catch {
            Write-Warning "Error processing $filePath : $_"
        }
    }
}

Write-Host "Processed $count files"

