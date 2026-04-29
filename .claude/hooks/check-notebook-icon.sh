#!/bin/bash
# check-notebook-icon.sh - PostToolUse Hook (Edit/Write/MultiEdit)
#
# Notebook × Score 시그니처 영역의 Material `Icons.*` 사용 감지 (§9 A2 정책).
#
# 정책:
#   - 시그니처 영역(스탬프·매스트헤드·EmptyState·notebook 위젯) 은 NotebookGlyph 사용
#   - 일반 navigation/utility (chevron_right, arrow_back, close, more_vert, search)
#     는 Material 허용 — 시스템 affordance 컨벤션 우선
#
# 적용 범위 (시그니처 영역):
#   - frontend/lib/core/widgets/notebook/**.dart       (notebook 프리미티브)
#   - frontend/lib/**/widgets/*_stamp.dart             (스탬프)
#   - frontend/lib/**/widgets/*_masthead.dart          (매스트헤드)
#   - frontend/lib/**/widgets/*empty_state*.dart       (빈 상태)
#   - frontend/lib/core/widgets/empty_state_widget.dart (공통 빈 상태)
#
# 옵트아웃: 위반 라인 위 또는 파일 상단에
#   `// ignore: notebook-icon` 주석 (사유 함께 기록 권장)
#
# 모든 출력은 advisory · stderr · exit 0.
#
# 스펙: docs/specs/design/notebook/README.md §9
# 도입: 2026-04-29 (Phase 1 § 9 정책 inception)

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

# 적용 범위: 시그니처 영역만
APPLY=0
case "$FILE_PATH" in
    */frontend/lib/core/widgets/notebook/*.dart) APPLY=1 ;;
    */frontend/lib/core/widgets/empty_state_widget.dart) APPLY=1 ;;
    */widgets/*_stamp.dart) APPLY=1 ;;
    */widgets/*_masthead.dart) APPLY=1 ;;
    */widgets/*empty_state*.dart) APPLY=1 ;;
esac

# notebook_glyph.dart 자체는 검사 제외 (구현체 자체)
case "$FILE_PATH" in
    */notebook_glyph.dart) exit 0 ;;
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
SILENCE_FILE = re.compile(r'//\s*ignore:\s*notebook-icon\s*$', re.MULTILINE)
if SILENCE_FILE.search(content):
    sys.exit(0)

ICONS_RE = re.compile(r'\bIcons\.[a-zA-Z_][a-zA-Z0-9_]*')
SILENCE_LINE = re.compile(r'//\s*ignore:\s*notebook-icon\b')

issues = []
for i, line in enumerate(lines):
    m = ICONS_RE.search(line)
    if not m:
        continue
    above = lines[i - 1] if i > 0 else ''
    if SILENCE_LINE.search(line) or SILENCE_LINE.search(above):
        continue
    issues.append(f"{path}:{i+1}: {m.group(0)} — 시그니처 영역, NotebookGlyph 사용 권장 (§9)")

for it in issues:
    print(it)
PY
)

if [[ -n "$WARNINGS" ]]; then
    echo "" >&2
    echo "┌─ Notebook × Score §9 아이콘 정책 점검 ─────────" >&2
    while IFS= read -r W; do
        [[ -z "$W" ]] && continue
        echo "│ $W" >&2
    done <<< "$WARNINGS"
    echo "│" >&2
    echo "│ A2 정책: 시그니처 영역(stamp/masthead/empty-state/notebook 프리미티브)" >&2
    echo "│         만 ASCII 강제. 일반 navigation/utility 는 Material 허용." >&2
    echo "│ 대안: NotebookGlyph (core/widgets/notebook/notebook_glyph.dart)" >&2
    echo "│ 의도적 예외: 위반 라인 위 또는 파일 상단에" >&2
    echo "│            '// ignore: notebook-icon' 주석 + 사유 기록" >&2
    echo "│ 근거: docs/specs/design/notebook/README.md §9" >&2
    echo "└───────────────────────────────────────────────" >&2
fi

exit 0
