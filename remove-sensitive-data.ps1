# Script to remove sensitive AWS credentials from DEMO_GUIDE.md in git history
# This script uses git filter-branch to rewrite history

Write-Host "Starting to remove sensitive data from git history..." -ForegroundColor Yellow
Write-Host "WARNING: This will rewrite git history. Make sure you have a backup!" -ForegroundColor Red

# Set environment variable to suppress warning
$env:FILTER_BRANCH_SQUELCH_WARNING = "1"

# Create a script that will replace sensitive content in DEMO_GUIDE.md
$scriptContent = @'
#!/bin/sh
if git ls-files --error-unmatch DEMO_GUIDE.md > /dev/null 2>&1; then
    # Check if file contains sensitive data
    if git show :DEMO_GUIDE.md | grep -q "644123626050\|cloud_user\|3ZJ7"; then
        # Get the file content
        git show :DEMO_GUIDE.md | \
        sed 's|https://644123626050\.signin\.aws\.amazon\.com/console?region=us-east-1|https://YOUR_ACCOUNT_ID.signin.aws.amazon.com/console?region=us-east-1|g' | \
        sed 's|cloud_user|your_username|g' | \
        sed 's|3ZJ7)y2GAjsk#P+^aD8y|your_password|g' | \
        git hash-object -w --stdin | \
        git update-index --cacheinfo 100644,$(git hash-object -w --stdin),DEMO_GUIDE.md
    fi
fi
'@

# For Windows, we'll use a different approach with PowerShell
# We'll use git filter-branch with a PowerShell command

Write-Host "Creating backup branch..." -ForegroundColor Yellow
git branch backup-before-cleanup

Write-Host "Removing sensitive data from all commits..." -ForegroundColor Yellow

# Use git filter-branch to rewrite history
# We'll use a script that checks out each commit and replaces the content
git filter-branch --force --tree-filter @'
if [ -f DEMO_GUIDE.md ]; then
    sed -i.bak "s|https://644123626050\.signin\.aws\.amazon\.com/console?region=us-east-1|https://YOUR_ACCOUNT_ID.signin.aws.amazon.com/console?region=us-east-1|g" DEMO_GUIDE.md
    sed -i.bak "s|cloud_user|your_username|g" DEMO_GUIDE.md
    sed -i.bak "s|3ZJ7)y2GAjsk#P+^aD8y|your_password|g" DEMO_GUIDE.md
    rm -f DEMO_GUIDE.md.bak 2>/dev/null || true
fi
'@ --prune-empty --tag-name-filter cat -- --all

Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the changes: git log --all"
Write-Host "2. Force push to remote: git push origin --force --all"
Write-Host "3. Force push tags: git push origin --force --tags"
Write-Host "4. WARNING: All collaborators need to re-clone the repository!"



