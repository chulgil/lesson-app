#!/bin/bash
# check-button-compact-layout.sh - PostToolUse Hook (Edit/Write/MultiEdit)
# 패턴 감지: 테마 `FilledButton/ElevatedButton/OutlinedButton.minimumSize = Size(∞, h)`
# 전제 하에 컴팩트 배치 (Align / Row-mainAxisAlignment.end / Wrap)에 놓인 버튼이
# `minimumSize` override 없으면 BoxConstraints(w=Infinity) 크래시 위험.
#
# 배경: 2026-04-24 수강관리 탭 (students_tab.dart) BoxConstraints 크래시 재발 방지.
# 원인: app_theme.dart 의 FilledButtonTheme.minimumSize = Size(double.infinity, 48)
# 는 풀폭 CTA 전제인데, Row+end 단독 자식이나 Align 에 그냥 놓으면 invalid 제약.
#
# 동작:
#   - 편집한 .dart 파일에서 FilledButton|ElevatedButton|OutlinedButton 호출 지점 스캔
#   - 호출 주변 (-5 ~ +25 줄) 컨텍스트 내 Align( 또는 MainAxisAlignment.end 존재하고
#     minimumSize: override 가 없으면 stderr 경고 (exit 0)

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

# 테스트 코드는 의도적으로 RED 가드를 포함할 수 있으므로 스킵
case "$FILE_PATH" in
    */test/*) exit 0 ;;
esac

WARNINGS=$(python3 - "$FILE_PATH" <<'PY'
import re, sys

path = sys.argv[1]
try:
    with open(path, encoding='utf-8') as f:
        lines = f.readlines()
except Exception:
    sys.exit(0)

BUTTON_RE = re.compile(r'\b(FilledButton|ElevatedButton|OutlinedButton)(?:\.icon|\.tonal|\.tonalIcon)?\s*\(')
ALIGN_RE = re.compile(r'\bAlign\s*\(')
ROW_END_RE = re.compile(r'MainAxisAlignment\.end\b')
WRAP_RE = re.compile(r'\bWrap\s*\(')
MINSIZE_RE = re.compile(r'minimumSize\s*:')
# 폭 제약이 이미 bounded 인 래퍼: 크래시 위험 없음
EXPANDED_RE = re.compile(r'\bExpanded\s*\(')
FLEXIBLE_TIGHT_RE = re.compile(r'\bFlexible\s*\([^)]*FlexFit\.tight')
SIZEDBOX_WIDTH_RE = re.compile(r'\bSizedBox\s*\([^)]*width\s*:')
CONSTRAINED_RE = re.compile(r'\bConstrainedBox\s*\(')
# 힌트: 이미 트레일링/세컨더리/인라인 배치라고 명시된 버튼은 개발자가 인지한 것으로 간주
SILENCE_RE = re.compile(r'//\s*ignore:\s*button-compact-minsize')

issues = []
seen = set()

for i, line in enumerate(lines):
    m = BUTTON_RE.search(line)
    if not m:
        continue
    btn = m.group(1)
    # 버튼 선언 위치에서 위로 5줄, 아래로 25줄을 윈도우로 본다
    start = max(0, i - 5)
    end = min(len(lines), i + 25)
    ctx = ''.join(lines[start:end])

    if SILENCE_RE.search(ctx):
        continue

    # 위쪽 컨텍스트(-5)에 Expanded/Flexible.tight/SizedBox(width:)/ConstrainedBox 있으면
    # 폭이 이미 bounded 되어 theme minWidth=∞ 이 tight 제약을 못 만듦 → 안전
    above = ''.join(lines[start:i+1])
    has_bounded = bool(
        EXPANDED_RE.search(above)
        or FLEXIBLE_TIGHT_RE.search(above)
        or SIZEDBOX_WIDTH_RE.search(above)
        or CONSTRAINED_RE.search(above)
    )
    if has_bounded:
        continue

    has_compact = bool(ALIGN_RE.search(ctx) or ROW_END_RE.search(ctx) or WRAP_RE.search(ctx))
    has_minsize = bool(MINSIZE_RE.search(ctx))

    if has_compact and not has_minsize:
        key = (i, btn)
        if key in seen:
            continue
        seen.add(key)
        issues.append(f"{path}:{i+1}: {btn} (컴팩트 배치 Align/Row-end/Wrap 내부) — minimumSize override 부재")

for it in issues:
    print(it)
PY
)

if [[ -n "$WARNINGS" ]]; then
    echo "" >&2
    echo "┌─ FilledButton 컴팩트 배치 감지 (테마 minWidth=∞ 크래시 위험) ─────" >&2
    while IFS= read -r W; do
        [[ -z "$W" ]] && continue
        echo "│ $W" >&2
    done <<< "$WARNINGS"
    echo "│" >&2
    echo "│ 대응: FilledButton.styleFrom(minimumSize: Size(0, AppSpacing.buttonHeight)) 로 override." >&2
    echo "│ 근거: .claude/rules/tech-patterns.md (테마 minimumSize=Size(∞,h) 함정)" >&2
    echo "│ 의도적 예외: 버튼 블록 앞 줄에 '// ignore: button-compact-minsize' 주석." >&2
    echo "└───────────────────────────────────────────────" >&2
fi

exit 0
