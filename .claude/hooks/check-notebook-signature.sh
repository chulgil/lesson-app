#!/bin/bash
# check-notebook-signature.sh - PostToolUse Hook (Edit/Write/MultiEdit)
#
# Notebook × Score 6대 시그니처 (§1.2) 누락 감지.
#   - 정체성 4대: Playfair · Roman numerals · Vermillion · Gaegu
#   - 구조 2대:   NotebookMasthead · "Fine."
#
# 스펙: docs/specs/design/notebook/README.md §1.2
# 적용 범위: tier-1 진입 화면 (탭 + 메인 라우트)
#   - frontend/lib/features/*/presentation/screens/*_tab.dart       (탭 레벨)
#   - frontend/lib/features/*/presentation/widgets/*_tab.dart       (홈 탭)
#   - frontend/lib/features/home/presentation/screens/home_screen.dart 류
#
# 감지 패턴 (모두 advisory · stderr 경고 · exit 0):
#   1. AppBar( 직접 사용         → §1.2 #5 NotebookMasthead 사용 권장
#   2. NotebookTypography import 부재 → §1.2 #1·#2·#4 시그니처 진입 부재
#
# 옵트아웃: 파일 상단 또는 위반 라인 위에
#   `// ignore: notebook-signature` 주석 (사유 함께 기록 권장)
#
# 배경: 2026-04-27 Wave 3 도입. tier-1 화면이 시그니처 미적용으로 도입되면
#       감사 점수 BLOCK 게이트가 사후에 크게 발생 (§7.67·§7.69 의 NotebookMasthead
#       탭 승격이 사후 대규모 배치였던 이유) → 신규 화면 시점에 알림 전환.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    inp = d.get('tool_input', {})
    print(inp.get('file_path', ''))
except Exception:
    pass
" 2>/dev/null)

if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

case "$FILE_PATH" in
    *.dart) ;;
    *) exit 0 ;;
esac

[[ ! -f "$FILE_PATH" ]] && exit 0

# 테스트·생성 파일 제외
case "$FILE_PATH" in
    */test/*|*.g.dart|*.freezed.dart|*.mocks.dart) exit 0 ;;
esac

# 적용 범위: tier-1 진입 화면만
APPLY=0
case "$FILE_PATH" in
    */features/*/presentation/screens/*_tab.dart) APPLY=1 ;;
    */features/*/presentation/widgets/*_tab.dart) APPLY=1 ;;
    */features/home/presentation/screens/home_screen.dart) APPLY=1 ;;
    */features/student_home/presentation/screens/student_home_screen.dart) APPLY=1 ;;
    */features/parent_home/presentation/screens/parent_home_screen.dart) APPLY=1 ;;
esac

[[ "$APPLY" -eq 0 ]] && exit 0

WARNINGS=$(python3 - "$FILE_PATH" <<'PY'
import re, sys

path = sys.argv[1]
try:
    with open(path, encoding='utf-8') as f:
        content = f.read()
        lines = content.splitlines()
except Exception:
    sys.exit(0)

# 옵트아웃: 파일 어디에든 ignore 주석 있으면 전체 스킵
SILENCE_FILE = re.compile(r'//\s*ignore:\s*notebook-signature\s*$', re.MULTILINE)
if SILENCE_FILE.search(content):
    sys.exit(0)

issues = []

# 시그니처 진입 점검 — NotebookTypography 또는 NotebookMasthead import 부재
HAS_TYPOGRAPHY = 'notebook_typography.dart' in content or 'NotebookTypography' in content
HAS_MASTHEAD = 'notebook_masthead.dart' in content or 'NotebookMasthead' in content
HAS_PAPER_SCAFFOLD = 'paper_scaffold.dart' in content or 'PaperScaffold' in content

if not (HAS_TYPOGRAPHY or HAS_MASTHEAD or HAS_PAPER_SCAFFOLD):
    issues.append(
        f"{path}:1: 시그니처 진입 부재 — "
        f"NotebookTypography/NotebookMasthead/PaperScaffold 중 1개 import 권장 (§1.2 정체성)"
    )

# AppBar 직접 사용 감지 (tier-1 화면에서)
APPBAR_RE = re.compile(r'\bAppBar\s*\(')
SILENCE_LINE = re.compile(r'//\s*ignore:\s*notebook-signature\b')

for i, line in enumerate(lines):
    if not APPBAR_RE.search(line):
        continue
    # 해당 라인 또는 직전 라인에 ignore 있으면 스킵
    above = lines[i - 1] if i > 0 else ''
    if SILENCE_LINE.search(line) or SILENCE_LINE.search(above):
        continue
    issues.append(
        f"{path}:{i+1}: AppBar 직접 사용 — tier-1 진입 화면은 NotebookMasthead 권장 (§1.2 #5)"
    )

for it in issues:
    print(it)
PY
)

if [[ -n "$WARNINGS" ]]; then
    echo "" >&2
    echo "┌─ Notebook × Score 시그니처 점검 (§1.2 6대) ─────" >&2
    while IFS= read -r W; do
        [[ -z "$W" ]] && continue
        echo "│ $W" >&2
    done <<< "$WARNINGS"
    echo "│" >&2
    echo "│ 정체성 4대: Playfair · Roman · Vermillion · Gaegu (NotebookTypography)" >&2
    echo "│ 구조 2대:   NotebookMasthead · \"Fine.\" 종지부" >&2
    echo "│ 의도적 예외: 위반 라인 또는 파일 상단에 '// ignore: notebook-signature' 주석" >&2
    echo "│ 근거: docs/specs/design/notebook/README.md §1.2" >&2
    echo "└───────────────────────────────────────────────" >&2
fi

exit 0
