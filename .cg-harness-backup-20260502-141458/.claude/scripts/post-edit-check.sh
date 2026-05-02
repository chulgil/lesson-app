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
   [[ "$BASENAME" == "app_typography.dart" ]] || \
   [[ "$BASENAME" == "app_spacing.dart" ]] || \
   [[ "$BASENAME" == *"_test.dart" ]] || \
   [[ "$FILE_PATH" == *"/router/"* ]] || \
   [[ "$FILE_PATH" == *"/core/theme/"* ]] || \
   [[ "$FILE_PATH" == *"date_format_utils"* ]]; then
  exit 0
fi

ERRORS=""    # exit 2 — 차단 피드백 (재발 잦고 자동 수정 쉬움)
WARNINGS=""  # exit 0 — 경고만 (기존 코드 위반 다수, 점진 정리 대상)

# ── ERRORS (exit 2) ──────────────────────────────────────────────

# Check 1: Hardcoded colors — Color(0x...) (주석 제외)
COLOR_MATCHES=$(grep -n 'Color(0x' "$FILE_PATH" 2>/dev/null | grep -vE '^\s*[0-9]+:\s*//')
if [[ -n "$COLOR_MATCHES" ]]; then
  ERRORS="${ERRORS}\n⚠️  하드코딩 색상 → AppColors 상수 사용:\n${COLOR_MATCHES}\n"
fi

# Check 2: Hardcoded routes — context.push('/...') (주석 제외)
ROUTE_MATCHES=$(grep -nE "context\.(push|go)\s*\(\s*['\"]/" "$FILE_PATH" 2>/dev/null | grep -vE '^\s*[0-9]+:\s*//')
if [[ -n "$ROUTE_MATCHES" ]]; then
  ERRORS="${ERRORS}\n⚠️  하드코딩 라우트 → AppRoutes 상수 사용:\n${ROUTE_MATCHES}\n"
fi

# Check 3: Inline DateFormat (import/주석 제외)
DATE_MATCHES=$(grep -n 'DateFormat(' "$FILE_PATH" 2>/dev/null | grep -v 'import' | grep -vE '^\s*[0-9]+:\s*//')
if [[ -n "$DATE_MATCHES" ]]; then
  ERRORS="${ERRORS}\n⚠️  인라인 DateFormat → formatDateYMD() 공통 유틸 사용:\n${DATE_MATCHES}\n"
fi

# ── WARNINGS (exit 0) ────────────────────────────────────────────
# features/ 하위에만 적용. 기존 코드에 위반이 많아 경고만 내고 점진 정리한다.
if [[ "$FILE_PATH" == *"/features/"* ]]; then

  # Check 4: fontSize 직접 사용 (AppTypography 미사용)
  FONT_MATCHES=$(grep -n 'fontSize:' "$FILE_PATH" 2>/dev/null | grep -v 'AppTypography' | grep -v '//')
  if [[ -n "$FONT_MATCHES" ]]; then
    WARNINGS="${WARNINGS}\nℹ️  fontSize 직접 사용 → AppTypography 상수 권장:\n${FONT_MATCHES}\n"
  fi

  # Check 5: EdgeInsets 직접 숫자 (AppSpacing 미사용)
  EDGE_MATCHES=$(grep -nE 'EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*[0-9]' "$FILE_PATH" 2>/dev/null | grep -v 'AppSpacing' | grep -v '//')
  if [[ -n "$EDGE_MATCHES" ]]; then
    WARNINGS="${WARNINGS}\nℹ️  EdgeInsets 직접 숫자 → AppSpacing 상수 권장:\n${EDGE_MATCHES}\n"
  fi

  # Check 6: NO-OP onTap
  NOOP_TAP=$(grep -nE 'onTap:\s*\(\s*\)\s*\{\s*\}' "$FILE_PATH" 2>/dev/null | grep -v '//')
  if [[ -n "$NOOP_TAP" ]]; then
    WARNINGS="${WARNINGS}\nℹ️  NO-OP onTap → 실제 액션 구현 또는 버튼 제거:\n${NOOP_TAP}\n"
  fi

  # Check 7: NO-OP onPressed
  NOOP_PRESS=$(grep -nE 'onPressed:\s*null' "$FILE_PATH" 2>/dev/null | grep -v '//' | grep -v 'isEnabled' | grep -v 'disabled')
  if [[ -n "$NOOP_PRESS" ]]; then
    WARNINGS="${WARNINGS}\nℹ️  onPressed: null → 실제 핸들러 연결 또는 disabled 상태 명시:\n${NOOP_PRESS}\n"
  fi

fi

# ── 출력 ─────────────────────────────────────────────────────────
if [[ -n "$ERRORS" || -n "$WARNINGS" ]]; then
  echo ""
  echo "━━━ 코딩 규칙 위반 감지 ($BASENAME) ━━━"
  [[ -n "$ERRORS" ]] && echo -e "$ERRORS"
  [[ -n "$WARNINGS" ]] && echo -e "$WARNINGS"
fi

# ERRORS가 있으면 차단(2), WARNINGS만 있으면 통과(0)
if [[ -n "$ERRORS" ]]; then
  exit 2
fi

exit 0
