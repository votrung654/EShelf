#!/bin/bash
# Script để kiểm tra xem thay đổi có phải chỉ là comment hay có code thực sự
# Sử dụng: ./scripts/check-code-changes.sh <file_path>
# Return: 0 nếu có code changes, 1 nếu chỉ là comment hoặc không có changes

set -e

FILE_PATH="$1"
BASE_REF="${2:-HEAD~1}"  # Default so sánh với commit trước

if [ -z "$FILE_PATH" ]; then
    echo "Usage: $0 <file_path> [base_ref]"
    exit 1
fi

# Kiểm tra file có tồn tại không
if [ ! -f "$FILE_PATH" ]; then
    echo "File not found: $FILE_PATH"
    exit 1
fi

# Lấy diff của file
DIFF=$(git diff "$BASE_REF" HEAD -- "$FILE_PATH" 2>/dev/null || echo "")

if [ -z "$DIFF" ]; then
    # Không có thay đổi
    exit 1
fi

# Loại bỏ các dòng chỉ là comment và whitespace
# Chỉ giữ lại các dòng có code thực sự
CODE_CHANGES=$(echo "$DIFF" | grep -E '^\+' | grep -vE '^\+{3}' | \
    sed 's/^+//' | \
    # Loại bỏ dòng chỉ có whitespace
    sed '/^[[:space:]]*$/d' | \
    # Loại bỏ dòng chỉ có comment (JavaScript/TypeScript)
    grep -vE '^[[:space:]]*//' | \
    # Loại bỏ dòng chỉ có comment (Python)
    grep -vE '^[[:space:]]*#' | \
    # Loại bỏ dòng chỉ có comment block start/end (JS/TS/CSS)
    grep -vE '^[[:space:]]*/\*' | \
    grep -vE '^[[:space:]]*\*/' | \
    # Loại bỏ dòng chỉ có comment (HTML)
    grep -vE '^[[:space:]]*<!--' | \
    grep -vE '^[[:space:]]*-->' | \
    # Loại bỏ dòng chỉ có comment và whitespace
    sed 's/[[:space:]]*\/\/.*$//' | \
    sed 's/[[:space:]]*#.*$//' | \
    sed 's/[[:space:]]*\/\*.*\*\/[[:space:]]*$//' | \
    # Loại bỏ dòng trống sau khi xóa comment
    sed '/^[[:space:]]*$/d')

# Nếu còn lại code thực sự sau khi loại bỏ comment
if [ -n "$CODE_CHANGES" ]; then
    echo "Real code changes detected in $FILE_PATH"
    exit 0
else
    echo "Only comment/whitespace changes in $FILE_PATH"
    exit 1
fi

