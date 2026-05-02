#!/bin/bash
# check-widget-smoke-test.sh - PostToolUse Hook (Edit/Write/MultiEdit)
# 패턴 감지: 신규 top-level 위젯 도입 시 widget smoke test 누락.
#
# 배경: 2026-04-29 §7.133 LikeStamp 도입에서 RenderMetaData 크래시 회귀 발생.
# `flutter analyze` 는 BoxConstraints/RenderBox 류 런타임 레이아웃 오류를 잡지 못함.
# ux-rules.md HARD-GATE: "탭/화면 레벨 위젯은 widget smoke test 필수".
#
# 동작:
#   - 편집 대상: features/*/presentation/screens/, features/*/presentation/widgets/,
#                core/widgets/ 하위의 .dart 파일
#   - 파일에 새로운 `class XxxScreen|XxxPage|XxxTab|XxxWidget|XxxStamp|XxxCard|XxxBar`
#     extends StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget 정의됨
#   - 그런데 동일 이름의 *_test.dart / *_layout_test.dart 파일이 test/ 하위에 없음
#   - 경고 (stderr, exit 0)

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

# 대상: .dart 파일만, test/ 자체는 제외
case "$FILE_PATH" in
    *.dart) ;;
    *) exit 0 ;;
esac

case "$FILE_PATH" in
    */test/*) exit 0 ;;
    *.g.dart) exit 0 ;;
    *.freezed.dart) exit 0 ;;
esac

# 대상 경로 화이트리스트 (top-level 위젯 영역)
case "$FILE_PATH" in
    */presentation/screens/*) ;;
    */presentation/widgets/*) ;;
    */core/widgets/*) ;;
    *) exit 0 ;;
esac

[[ ! -f "$FILE_PATH" ]] && exit 0

# 프로젝트 루트 추정 (파일 경로에서 frontend/ 위치 찾기)
PROJECT_ROOT=$(echo "$FILE_PATH" | sed 's|/lib/.*||')
TEST_ROOT="$PROJECT_ROOT/test"

[[ ! -d "$TEST_ROOT" ]] && exit 0

WARNINGS=$(python3 - "$FILE_PATH" "$TEST_ROOT" <<'PY'
import os
import re
import sys

src_path, test_root = sys.argv[1], sys.argv[2]

try:
    with open(src_path, encoding='utf-8') as f:
        content = f.read()
except Exception:
    sys.exit(0)

# top-level 위젯 클래스 패턴 — 화면/탭/스크린/커스텀 위젯 명명 컨벤션
WIDGET_RE = re.compile(
    r'^class\s+(\w+(?:Screen|Page|Tab|Widget|Stamp|Card|Bar|Sheet|Dialog|Masthead|Header|Section|View))\s+'
    r'extends\s+(StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget)\b',
    re.MULTILINE,
)

# 의도적 예외: '// ignore: widget-smoke-test' 주석이 클래스 직전에 있으면 스킵
SILENCE_RE = re.compile(r'//\s*ignore:\s*widget-smoke-test')

widgets = []
for m in WIDGET_RE.finditer(content):
    cls = m.group(1)
    # 클래스 정의 직전 3줄 안에 silence 주석이 있는지 확인
    start = m.start()
    pre = content[max(0, start - 200):start]
    if SILENCE_RE.search(pre):
        continue
    widgets.append(cls)

if not widgets:
    sys.exit(0)

# CamelCase → snake_case 변환
def camel_to_snake(name):
    s1 = re.sub(r'(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

issues = []
for cls in widgets:
    snake = camel_to_snake(cls)
    # 가능한 테스트 파일 이름들
    candidates = [
        f'{snake}_test.dart',
        f'{snake}_layout_test.dart',
        f'{snake}_smoke_test.dart',
        f'{snake}_widget_test.dart',
    ]
    found = False
    for root, _dirs, files in os.walk(test_root):
        for fn in files:
            if fn in candidates:
                found = True
                break
        if found:
            break
    if not found:
        issues.append(f"{cls} (예상: test/.../{snake}_test.dart)")

for it in issues:
    print(it)
PY
)

if [[ -n "$WARNINGS" ]]; then
    echo "" >&2
    echo "┌─ widget smoke test 누락 감지 (top-level 위젯 회귀 위험) ───────" >&2
    echo "│ 파일: $FILE_PATH" >&2
    while IFS= read -r W; do
        [[ -z "$W" ]] && continue
        echo "│ • $W" >&2
    done <<< "$WARNINGS"
    echo "│" >&2
    echo "│ 대응: testWidgets() smoke test 추가 (pumpWidget + pumpAndSettle + tester.takeException() isNull)" >&2
    echo "│ 근거: .claude/rules/ux-rules.md HARD-GATE — flutter analyze 는 RenderBox/BoxConstraints 크래시 미감지" >&2
    echo "│ 의도적 예외: 클래스 정의 위 줄에 '// ignore: widget-smoke-test' 주석." >&2
    echo "│ 사례: §7.133 LikeStamp RenderMetaData 회귀 (2026-04-29)" >&2
    echo "└───────────────────────────────────────────────" >&2
fi

exit 0
