#!/bin/bash
# Script để lấy logs từ GitHub Actions
# Yêu cầu: GitHub CLI (gh) đã cài đặt và authenticated

WORKFLOW=""
RUN_ID=""
JOB_NAME=""
STATUS="failure"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--workflow)
            WORKFLOW="$2"
            shift 2
            ;;
        -r|--run-id)
            RUN_ID="$2"
            shift 2
            ;;
        -j|--job)
            JOB_NAME="$2"
            shift 2
            ;;
        -s|--status)
            STATUS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "GitHub Actions Logs Fetcher"
echo "============================"
echo ""

# Kiểm tra GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI (gh) chưa được cài đặt."
    echo "Cài đặt: https://cli.github.com/"
    exit 1
fi

# Kiểm tra authentication
if ! gh auth status &> /dev/null; then
    echo "ERROR: Chưa đăng nhập GitHub CLI."
    echo "Chạy: gh auth login"
    exit 1
fi

# Lấy repository name
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "Repository: $REPO"
echo ""

# Nếu không có RunId, lấy run mới nhất
if [ -z "$RUN_ID" ]; then
    echo "Đang lấy workflow runs..."
    
    FILTER=""
    if [ "$STATUS" != "all" ]; then
        FILTER="--status $STATUS"
    fi
    
    if [ -n "$WORKFLOW" ]; then
        FILTER="$FILTER --workflow $WORKFLOW"
    fi
    
    RUNS=$(gh run list --limit 10 $FILTER --json databaseId,status,conclusion,workflowName,createdAt,headBranch --jq '.[] | "\(.databaseId)|\(.status)|\(.conclusion)|\(.workflowName)|\(.createdAt)|\(.headBranch)"')
    
    if [ -z "$RUNS" ]; then
        echo "Không tìm thấy runs nào."
        exit 1
    fi
    
    echo ""
    echo "Danh sách runs:"
    echo "$RUNS" | while IFS='|' read -r id status conclusion wf_name created branch; do
        if [ "$conclusion" = "failure" ]; then
            echo "  [$id] $wf_name - $branch - $conclusion ($created)"
        elif [ "$conclusion" = "success" ]; then
            echo "  [$id] $wf_name - $branch - $conclusion ($created)"
        else
            echo "  [$id] $wf_name - $branch - $conclusion ($created)"
        fi
    done
    
    echo ""
    read -p "Nhập Run ID (hoặc Enter để chọn run đầu tiên): " INPUT
    RUN_ID=${INPUT:-$(echo "$RUNS" | head -n1 | cut -d'|' -f1)}
fi

echo ""
echo "Đang lấy thông tin run $RUN_ID..."

# Lấy danh sách jobs
JOBS=$(gh run view $RUN_ID --json jobs --jq '.jobs[] | "\(.databaseId)|\(.name)|\(.conclusion)|\(.status)"')

if [ -z "$JOBS" ]; then
    echo "Không tìm thấy jobs nào."
    exit 1
fi

echo ""
echo "Danh sách jobs:"
echo "$JOBS" | while IFS='|' read -r job_id job_name conclusion status; do
    if [ "$conclusion" = "failure" ]; then
        echo "  [$job_id] $job_name - $conclusion"
    elif [ "$conclusion" = "success" ]; then
        echo "  [$job_id] $job_name - $conclusion"
    else
        echo "  [$job_id] $job_name - $conclusion"
    fi
done

# Lọc jobs failed
FAILED_JOBS=$(echo "$JOBS" | grep "|failure|" || true)

if [ -z "$FAILED_JOBS" ]; then
    echo ""
    echo "Không có job nào failed."
    exit 0
fi

echo ""
echo "Đang lấy logs cho các jobs failed..."

# Tạo thư mục logs
LOG_DIR="github-logs-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"

echo "$FAILED_JOBS" | while IFS='|' read -r job_id job_name conclusion status; do
    echo ""
    echo "Lấy logs cho job: $job_name..."
    
    LOG_FILE="$LOG_DIR/$(echo "$job_name" | tr '[:space:]' '_' | tr -cd '[:alnum:]_')-$job_id.log"
    
    if gh run view $RUN_ID --log --job $job_id > "$LOG_FILE" 2>&1; then
        echo "  Đã lưu: $LOG_FILE"
    else
        echo "  Lỗi khi lấy logs"
    fi
done

echo ""
echo "Hoàn thành! Logs đã được lưu trong: $LOG_DIR"
echo ""
echo "Để xem logs của job cụ thể:"
echo "  gh run view $RUN_ID --log --job <JOB_ID>"
echo ""
echo "Để xem tất cả logs của run:"
echo "  gh run view $RUN_ID --log"

