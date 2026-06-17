#!/bin/bash
# check-ui-emoji.sh - PostToolUse Hook (Edit/Write/MultiEdit)
#
# 앱 전체 UI 문자열에서 이모지/유니코드 픽토그램 사용 감지.
#
# 정책 (2026-06-17):
#   - UI 텍스트(AppStrings 값, Text(), label/hint, snackbar 등)에 이모지/픽토그램 금지
#   - 아이콘이 필요하면 Material `Icons.*` 벡터 아이콘 사용
#   - 예외: NotebookGlyph 시그니처 글리프(★ ♩ ♥ ♡ ✓ ✗ → 등 text-presentation)
#           및 → ← 같은 타이포그래피 화살표는 이모지가 아니므로 감지 대상 아님
#
# 감지 대상 (emoji-presentation 코드포인트만):
#   - U+1F000–U+1FAFF (Misc/Emoticons/Transport/Pictographs) — 🎵🔥🎁📋🎻 등
#   - U+FE0F (emoji variation selector) — ℹ️ ⚠️ 등
#   - 명시 BMP 이모지: ✅ ❌ ⭐ ⚠ ⏰ ⏳ ℹ ⁉ ‼ ✨ ⭕ ❗ ❓ ❔
#   → NotebookGlyph(★2605 ♩2669 ♥2665 ♡2661 ✓2713 ✗2717)·화살표(→2192 ←2190)는 제외
#
# 옵트아웃: 위반 라인 위 또는 같은 라인에 `// ignore: ui-emoji` 주석 (사유 권장)
#
# 모든 출력은 advisory · stderr · exit 0.
#
# 룰: .claude/rules/ux-rules.md (UI 이모지 금지)
# 도입: 2026-06-17

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    pass
" 2>/dev/null)

[[ -z "$FILE_PATH" ]] && exit 0

case "$FILE_PATH" in
    *.dart) ;;
    *) exit 0 ;;
esac

[[ ! -f "$FILE_PATH" ]] && exit 0

# 테스트·생성 파일·NotebookGlyph 구현체 제외
case "$FILE_PATH" in
    */test/*|*.g.dart|*.freezed.dart|*.mocks.dart) exit 0 ;;
    */notebook_glyph.dart) exit 0 ;;
esac

WARNINGS=$(python3 - "$FILE_PATH" <<'PY'
import re, sys

path = sys.argv[1]
try:
    with open(path, encoding='utf-8') as f:
        lines = f.read().splitlines()
except Exception:
    sys.exit(0)

# emoji-presentation 코드포인트만 (NotebookGlyph BMP 글리프·화살표 제외)
EMOJI = re.compile(
    '['
    '\U0001F000-\U0001FAFF'   # pictographs / emoticons / transport / symbols-ext
    '️'                  # emoji variation selector (ℹ️ ⚠️ ...)
    '✅❌⭐⚠⏰⏳ℹ'  # ✅ ❌ ⭐ ⚠ ⏰ ⏳ ℹ
    '⁉‼✨⭕❗❓❔'   # ⁉ ‼ ✨ ⭕ ❗ ❓ ❔
    ']'
)
SILENCE = re.compile(r'//\s*ignore:\s*ui-emoji\b')

issues = []
for i, line in enumerate(lines):
    m = EMOJI.search(line)
    if not m:
        continue
    above = lines[i - 1] if i > 0 else ''
    if SILENCE.search(line) or SILENCE.search(above):
        continue
    issues.append(f"{path}:{i+1}: {m.group(0)!r} — UI 문자열 이모지 금지")

for it in issues:
    print(it)
PY
)

if [[ -n "$WARNINGS" ]]; then
    echo "" >&2
    echo "┌─ UI 이모지 정책 점검 ──────────────────────────" >&2
    while IFS= read -r W; do
        [[ -z "$W" ]] && continue
        echo "│ $W" >&2
    done <<< "$WARNINGS"
    echo "│" >&2
    echo "│ 정책: UI 텍스트에 이모지/픽토그램 금지 — Material Icons.* 사용." >&2
    echo "│ 예외: NotebookGlyph 시그니처 글리프(★ ♩ ✓)·화살표(→)는 허용." >&2
    echo "│ 의도적 예외: 위반 라인 위/같은 라인에 '// ignore: ui-emoji' + 사유." >&2
    echo "│ 룰: .claude/rules/ux-rules.md" >&2
    echo "└────────────────────────────────────────────────" >&2
fi

exit 0
