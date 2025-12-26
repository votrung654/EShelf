# Script to remove emojis from files
# Simple approach: read files and remove emoji Unicode ranges

# Get all text files (markdown, scripts, etc.)
$files = Get-ChildItem -Path ".." -Recurse -Include *.md,*.ps1,*.sh,*.js,*.jsx,*.ts,*.tsx,*.yml,*.yaml -File | 
    Where-Object { $_.FullName -notmatch 'node_modules|\.git|dist|build|remove-emoji\.ps1' }

$count = 0
foreach ($file in $files) {
    try {
        # Read file with UTF8 encoding
        $encoding = [System.Text.Encoding]::UTF8
        $content = [System.IO.File]::ReadAllText($file.FullName, $encoding)
        $originalContent = $content
        
        # Remove emoji Unicode ranges using regex
        # This regex matches emoji ranges
        $emojiRegex = [regex]'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}]'
        $content = $emojiRegex.Replace($content, '')
        
        if ($content -ne $originalContent) {
            [System.IO.File]::WriteAllText($file.FullName, $content, $encoding)
            Write-Host "Removed emojis from: $($file.Name)"
            $count++
        }
    } catch {
        Write-Warning "Error processing $($file.FullName): $_"
    }
}

Write-Host "Processed $count files with emoji removal"
