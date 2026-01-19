# Script to automate rebase for changing commit messages
$env:GIT_SEQUENCE_EDITOR = "powershell -Command `"`$content = Get-Content `$args[0]; `$content = `$content -replace '^pick 8b3052a', 'reword 8b3052a' -replace '^pick e3f3fa0', 'reword e3f3fa0'; Set-Content `$args[0] `$content`""
$env:GIT_EDITOR = "powershell -Command `"Set-Content `$args[0] 'clean: cleanup documentation files'`""

git rebase -i 3350ec0






