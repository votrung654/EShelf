param([string]$file)

if ($file -match "COMMIT_EDITMSG") {
    # This is a commit message edit
    Set-Content -Path $file -Value "clean: cleanup documentation files"
} elseif ($file -match "git-rebase-todo") {
    # This is the rebase todo file
    $content = Get-Content -Path $file
    $newContent = $content -replace '^pick 8b3052a', 'reword 8b3052a' -replace '^pick e3f3fa0', 'reword e3f3fa0'
    Set-Content -Path $file -Value $newContent
} else {
    # Default: open in notepad
    notepad $file
}






