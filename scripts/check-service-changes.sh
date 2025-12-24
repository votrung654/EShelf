#!/bin/bash
# Script để kiểm tra service có thay đổi code thực sự không (bỏ qua comment)
# Sử dụng: ./scripts/check-service-changes.sh <service_path1> [service_path2] ... [base_ref]
# Return: 0 nếu có code changes, 1 nếu chỉ là comment hoặc không có changes

set -e

# Lấy tất cả arguments trừ argument cuối (có thể là base_ref)
ARGS=("$@")
BASE_REF="${ARGS[-1]}"

# Nếu argument cuối không phải là ref (không có /), thì đó là path
if [[ "$BASE_REF" =~ ^[a-f0-9]+$ ]] || [[ "$BASE_REF" =~ HEAD ]] || [[ "$BASE_REF" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
    # Là ref, lấy paths trước đó
    SERVICE_PATHS=("${ARGS[@]:0:${#ARGS[@]}-1}")
    BASE_REF="${BASE_REF:-HEAD~1}"
else
    # Không có ref, tất cả là paths
    SERVICE_PATHS=("${ARGS[@]}")
    BASE_REF="HEAD~1"
fi

if [ ${#SERVICE_PATHS[@]} -eq 0 ]; then
    echo "Usage: $0 <service_path1> [service_path2] ... [base_ref]"
    exit 1
fi

# Các extension cần check code changes
CODE_EXTENSIONS="\.(js|jsx|ts|tsx|py|java|go|rs|cpp|c|h|hpp)$"
CONFIG_EXTENSIONS="\.(json|yaml|yml|toml|ini|conf|env|properties|lock)$"
BUILD_EXTENSIONS="\.(Dockerfile|dockerfile|docker-compose|Makefile|makefile)$"

HAS_REAL_CHANGES=1

# Check từng service path
for SERVICE_PATH in "${SERVICE_PATHS[@]}"; do
    # Lấy danh sách files đã thay đổi
    CHANGED_FILES=$(git diff --name-only "$BASE_REF" HEAD -- "$SERVICE_PATH" 2>/dev/null || echo "")
    
    if [ -z "$CHANGED_FILES" ]; then
        continue
    fi
    
    # Check từng file
    while IFS= read -r file; do
        if [ -z "$file" ] || [ ! -f "$file" ]; then
            continue
        fi
        
        # File config hoặc build files luôn cần build nếu thay đổi
        if echo "$file" | grep -qE "($CONFIG_EXTENSIONS|$BUILD_EXTENSIONS)"; then
            echo "Config/build file changed: $file (requires build)"
            HAS_REAL_CHANGES=0
            continue
        fi
        
        # Check code files
        if echo "$file" | grep -qE "$CODE_EXTENSIONS"; then
            # Lấy diff
            DIFF=$(git diff "$BASE_REF" HEAD -- "$file" 2>/dev/null || echo "")
            
            if [ -n "$DIFF" ]; then
                # Loại bỏ các dòng chỉ là comment và whitespace
                # Lấy các dòng được thêm (+)
                CODE_CHANGES=$(echo "$DIFF" | grep -E '^\+' | grep -vE '^\+{3}' | \
                    sed 's/^+//' | \
                    # Loại bỏ dòng trống
                    sed '/^[[:space:]]*$/d' | \
                    # Loại bỏ dòng chỉ có comment (single line)
                    grep -vE '^[[:space:]]*//' | \
                    grep -vE '^[[:space:]]*#' | \
                    grep -vE '^[[:space:]]*<!--' | \
                    # Loại bỏ comment ở cuối dòng (giữ lại code trước comment)
                    sed 's/[[:space:]]*\/\/.*$//' | \
                    sed 's/[[:space:]]*#.*$//' | \
                    sed 's/[[:space:]]*<!--.*-->[[:space:]]*$//' | \
                    # Loại bỏ dòng trống sau khi xóa comment
                    sed '/^[[:space:]]*$/d')
                
                if [ -n "$CODE_CHANGES" ]; then
                    echo "Real code changes in: $file"
                    HAS_REAL_CHANGES=0
                fi
            fi
        fi
    done <<< "$CHANGED_FILES"
done

exit $HAS_REAL_CHANGES

