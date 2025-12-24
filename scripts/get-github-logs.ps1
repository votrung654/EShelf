# Script để lấy logs từ GitHub Actions
# Yêu cầu: GitHub CLI (gh) đã cài đặt và authenticated

param(
    [string]$Workflow = "",
    [string]$RunId = "",
    [string]$JobName = "",
    [string]$Status = "failure"
)

$GH_CLI = "D:\Downloads\gh_2.83.2_windows_amd64\bin\gh.exe"

Write-Host "GitHub Actions Logs Fetcher" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra GitHub CLI
if (-not (Test-Path $GH_CLI)) {
    Write-Host "ERROR: GitHub CLI (gh) chưa được cài đặt." -ForegroundColor Red
    Write-Host "Cài đặt: https://cli.github.com/" -ForegroundColor Yellow
    Write-Host "Hoặc: winget install GitHub.cli" -ForegroundColor Yellow
    exit 1
}

# Kiểm tra authentication
$authStatus = & $GH_CLI auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Chưa đăng nhập GitHub CLI." -ForegroundColor Red
    Write-Host "Chạy: gh auth login" -ForegroundColor Yellow
    exit 1
}

# Lấy repository name
$repo = & $GH_CLI repo view --json nameWithOwner -q .nameWithOwner
Write-Host "Repository: $repo" -ForegroundColor Green
Write-Host ""

# Nếu không có RunId, lấy danh sách run mới nhất
if ([string]::IsNullOrEmpty($RunId)) {
    Write-Host "Đang lấy workflow runs..." -ForegroundColor Yellow

    $runListArgs = @(
        "--limit", "10",
        "--json", "databaseId,status,conclusion,workflowName,createdAt,headBranch",
        "--jq", '.[] | [.databaseId, .status, .conclusion, .workflowName, .createdAt, .headBranch] | join("\"|\"")'
    )
    if ($Status -ne "all" -and $Status) { $runListArgs += @("--status", $Status) }
    if ($Workflow) { $runListArgs += @("--workflow", $Workflow) }

    $runs = & $GH_CLI run list @runListArgs

    if ([string]::IsNullOrEmpty($runs)) {
        Write-Host "Không tìm thấy runs nào." -ForegroundColor Red
        exit 1
    }

    Write-Host "`nDanh sách runs:" -ForegroundColor Cyan
    $runIds = @()
    $runs | ForEach-Object {
        $parts = $_ -split '\|'
        $id = $parts[0]
        $status = $parts[1]
        $conclusion = $parts[2]
        $wfName = $parts[3]
        $created = $parts[4]
        $branch = $parts[5]

        $runIds += $id

        $color = if ($conclusion -eq "failure") { "Red" } elseif ($conclusion -eq "success") { "Green" } else { "Yellow" }
        Write-Host "  [$id] $wfName - $branch - $conclusion ($created)" -ForegroundColor $color
    }
} else {
    $runIds = @($RunId)
}

# Tạo thư mục logs tổng
$logRootDir = "github-logs-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $logRootDir -Force | Out-Null

foreach ($runId in $runIds) {
    Write-Host "`nĐang lấy thông tin run $runId..." -ForegroundColor Yellow

    # Sửa jq: không join .steps
    $jobs = & $GH_CLI run view $runId --json jobs --jq '.jobs[] | [.databaseId, .name, .conclusion, .status, .startedAt, .completedAt] | join("\"|\"")'
    $jobsSteps = & $GH_CLI run view $runId --json jobs --jq '.jobs[].steps'

    if ([string]::IsNullOrEmpty($jobs)) {
        Write-Host "Không tìm thấy jobs nào." -ForegroundColor Red
        continue
    }

    Write-Host "`nDanh sách jobs:" -ForegroundColor Cyan
    $jobList = @()
    $stepIdx = 0
    $jobs | ForEach-Object {
        $parts = $_ -split '\|'
        $jobId = $parts[0]
        $jobName = $parts[1]
        $conclusion = $parts[2]
        $status = $parts[3]
        $startedAt = $parts[4]
        $completedAt = $parts[5]
        $steps = $jobsSteps[$stepIdx]
        $stepIdx++

        $jobList += @{
            Id = $jobId
            Name = $jobName
            Conclusion = $conclusion
            Status = $status
            StartedAt = $startedAt
            CompletedAt = $completedAt
            Steps = $steps
        }

        $color = if ($conclusion -eq "failure") { "Red" } elseif ($conclusion -eq "success") { "Green" } else { "Yellow" }
        Write-Host "  [$jobId] $jobName - $conclusion" -ForegroundColor $color
    }

    Write-Host "`nĐang lấy logs cho tất cả jobs..." -ForegroundColor Yellow

    # Tạo thư mục logs cho từng run
    $logDir = Join-Path $logRootDir "run-$runId"
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null

    foreach ($job in $jobList) {
        Write-Host "`nLấy logs cho job: $($job.Name)..." -ForegroundColor Cyan

        $logFile = Join-Path $logDir "$($job.Name -replace '[^\w\-]', '_')-$($job.Id).log"

        try {
            & $GH_CLI run view $runId --log --job $job.Id | Out-File -FilePath $logFile -Encoding UTF8
            Write-Host "  Đã lưu: $logFile" -ForegroundColor Green
        } catch {
            Write-Host "  Lỗi khi lấy logs: $_" -ForegroundColor Red
        }
    }

    # Lưu thông tin tổng hợp jobs ra file JSON cho từng run
    $jobList | ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path $logDir "jobs-summary.json") -Encoding UTF8
}

Write-Host "`nHoàn thành! Logs đã được lưu trong: $logRootDir" -ForegroundColor Green
Write-Host "`nĐể xem logs của job cụ thể:" -ForegroundColor Yellow
Write-Host "  gh run view <RUN_ID> --log --job <JOB_ID>" -ForegroundColor Cyan
Write-Host "`nĐể xem tất cả logs của run:" -ForegroundColor Yellow
Write-Host "  gh run view <RUN_ID> --log" -ForegroundColor Cyan