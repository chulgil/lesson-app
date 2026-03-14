#!/bin/bash
# PostToolUse hook: Edit/Write 후 코딩 규칙 검사
# stdin으로 JSON 입력을 받아 file_path 추출

# Read JSON from stdin
INPUT="$(cat)"

# Extract file_path from tool input using python3 (macOS built-in)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # Try tool_input.file_path first, then direct file_path
    ti = data.get('tool_input', data)
    print(ti.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Skip if no file path or not a dart file
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.dart ]]; then
  exit 0
fi

# Skip definition files and tests
BASENAME=$(basename "$FILE_PATH")
if [[ "$BASENAME" == "app_colors.dart" ]] || \
   [[ "$BASENAME" == "app_routes.dart" ]] || \
   [[ "$BASENAME" == *"_test.dart" ]] || \
   [[ "$FILE_PATH" == *"/router/"* ]] || \
   [[ "$FILE_PATH" == *"date_format_utils"* ]]; then
  exit 0
fi

ERRORS=""

# Check 1: Hardcoded colors — Color(0x...)
COLOR_MATCHES=$(grep -n 'Color(0x' "$FILE_PATH" 2>/dev/null)
if [[ -n "$COLOR_MATCHES" ]]; then
  ERRORS="${ERRORS}\n⚠️  하드코딩 색상 → AppColors 상수 사용:\n${COLOR_MATCHES}\n"
fi

# Check 2: Hardcoded routes — context.push('/...')
ROUTE_MATCHES=$(grep -nE "context\.(push|go)\s*\(\s*['\"]/" "$FILE_PATH" 2>/dev/null)
if [[ -n "$ROUTE_MATCHES" ]]; then
  ERRORS="${ERRORS}\n⚠️  하드코딩 라우트 → AppRoutes 상수 사용:\n${ROUTE_MATCHES}\n"
fi

# Check 3: Inline DateFormat (import 라인 제외)
DATE_MATCHES=$(grep -n 'DateFormat(' "$FILE_PATH" 2>/dev/null | grep -v 'import' | grep -v '//')
if [[ -n "$DATE_MATCHES" ]]; then
  ERRORS="${ERRORS}\n⚠️  인라인 DateFormat → formatDateYMD() 공통 유틸 사용:\n${DATE_MATCHES}\n"
fi

if [[ -n "$ERRORS" ]]; then
  echo ""
  echo "━━━ 코딩 규칙 위반 감지 ($BASENAME) ━━━"
  echo -e "$ERRORS"
  exit 2
fi

exit 0
