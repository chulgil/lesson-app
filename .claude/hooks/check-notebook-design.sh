#!/bin/bash
# check-notebook-design.sh - PostToolUse Hook (Edit/Write)
#
# Notebook × Score 디자인 게이트 — 신규/수정 화면에서 디자인 위반 감지.
#
# 감지 패턴 (모두 advisory · stderr 경고 · exit 0):
#   1. Scaffold( 직접 사용 (NotebookScreenScaffold 미사용)
#   2. AppBar( 직접 사용 (NotebookDetailAppBar/NotebookMasthead 미사용)
#   3. borderRadius 사용 (직선 모서리 위반)
#   4. Colors.white 사용 (paper 미사용)
#   5. Theme.of(context).textTheme 사용 (AppTypography 미사용)
#   6. showModalBottomSheet 직접 사용
#
# 적용 범위: features/*/presentation/{screens,widgets}/*.dart
#
# 옵트아웃: `// ignore: notebook-design` 주석
#
# 규칙: .claude/rules/notebook-design-gate.md

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', d.get('tool_input', {}).get('filePath', '')))
except:
    print('')
" 2>/dev/null)

# Only check dart files in presentation layer
case "$FILE_PATH" in
  *features/*/presentation/screens/*.dart|*features/*/presentation/widgets/*.dart) ;;
  *) exit 0 ;;
esac

# Skip if opt-out comment exists
if grep -q "// ignore: notebook-design" "$FILE_PATH" 2>/dev/null; then
  exit 0
fi

WARNINGS=""

# 1. Scaffold( direct use
if grep -n "return Scaffold(" "$FILE_PATH" 2>/dev/null | grep -v "NotebookScreenScaffold" | grep -qv "// ignore"; then
  WARNINGS="${WARNINGS}\n  ⚠ Scaffold 직접 사용 → NotebookScreenScaffold 권장"
fi

# 2. AppBar( direct use
if grep -n "AppBar(" "$FILE_PATH" 2>/dev/null | grep -v "NotebookDetailAppBar\|NotebookMasthead\|DetailAppBar" | grep -qv "// ignore"; then
  WARNINGS="${WARNINGS}\n  ⚠ AppBar 직접 사용 → NotebookDetailAppBar 또는 NotebookMasthead 권장"
fi

# 3. borderRadius (non-zero)
if grep -n "borderRadius:" "$FILE_PATH" 2>/dev/null | grep -v "BorderRadius.zero\|RoundedRectangleBorder()" | grep -qv "// ignore"; then
  WARNINGS="${WARNINGS}\n  ⚠ borderRadius 사용 → 직선 모서리(BorderRadius.zero) 권장"
fi

# 4. Colors.white
if grep -qn "Colors.white" "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}\n  ⚠ Colors.white → AppColors.paper 사용 권장"
fi

# 5. Theme.of(context).textTheme
if grep -qn "Theme.of(context).textTheme" "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}\n  ⚠ Theme.of(context).textTheme → AppTypography.* 사용 권장"
fi

# 6. showModalBottomSheet direct use
if grep -n "showModalBottomSheet" "$FILE_PATH" 2>/dev/null | grep -v "showNotebookModalBottomSheet" | grep -qv "// ignore"; then
  WARNINGS="${WARNINGS}\n  ⚠ showModalBottomSheet → showNotebookModalBottomSheet 권장"
fi

if [ -n "$WARNINGS" ]; then
  echo "[notebook-design] $FILE_PATH:$WARNINGS" >&2
fi

exit 0
