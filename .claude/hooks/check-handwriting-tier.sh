#!/bin/bash
# check-handwriting-tier.sh - PostToolUse Hook (Edit/Write/MultiEdit)
#
# Notebook × Score Gaegu 손글씨 4계층 위반 감지 (advisory).
#
# §1.1.1 결정 트리: "이 텍스트의 작성 주체는 누구인가?"
#   - 사람       → Tier 1·2 (hand / handEmphasis / handOk / Gaegu)
#   - 시스템     → Tier 4 (indicatorLabel / Pretendard 기본)
#
# 감지: Tier 4 키워드(시스템 자동 인디케이터)와 자필 스타일 조합.
#
# Tier 4 키워드 (시스템 자동 생성):
#   - 시간 라벨:  오늘 / 내일 / D-[0-9]+
#   - 상태 뱃지:  미결제 / 필수 / 진행 중 / 대기 / 완료
#
# 자필 스타일 (적용 대상):
#   - NotebookTypography.hand
#   - NotebookTypography.handEmphasis
#   - NotebookTypography.handOk
#   - GoogleFonts.gaegu
#
# 동일 위젯/Container 블록(±10 라인) 내 Tier 4 키워드 + 자필 스타일 동시 등장 → 경고.
#
# 옵트아웃: 위반 라인 위 또는 같은 라인에
#   `// ignore: handwriting-tier`  (사유 명시 권장)
#
# 스펙: docs/specs/design/notebook/README.md §1.1.1 + phase-log.md §7.127

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
    */notebook_typography.dart) exit 0 ;;
esac

WARNINGS=$(python3 - "$FILE_PATH" <<'PY'
import re, sys

path = sys.argv[1]
try:
    with open(path, encoding='utf-8') as f:
        lines = f.read().splitlines()
except Exception:
    sys.exit(0)

# Tier 4 시스템 자동 인디케이터 키워드
TIER4 = re.compile(
    r"['\"](오늘|내일|D-?\d+|미결제|필수|진행\s*중|대기|완료)['\"]"
)

# 자필 스타일 토큰
HAND = re.compile(
    r'\b(NotebookTypography\.(hand|handEmphasis|handOk)|GoogleFonts\.gaegu)\b'
)

SILENCE = re.compile(r'//\s*ignore:\s*handwriting-tier\b')

issues = []

# Tier 4 키워드가 있는 라인 위치 모두 수집
tier4_lines = []
for i, line in enumerate(lines):
    if TIER4.search(line):
        tier4_lines.append(i)

if not tier4_lines:
    sys.exit(0)

# 각 Tier 4 라인의 ±10 윈도우 안에 자필 스타일 토큰이 있으면 위반
WINDOW = 10
for ti in tier4_lines:
    start = max(0, ti - WINDOW)
    end = min(len(lines), ti + WINDOW + 1)
    for j in range(start, end):
        line = lines[j]
        if not HAND.search(line):
            continue
        # 옵트아웃 점검 (해당 라인 또는 위/아래 1라인)
        opted_out = SILENCE.search(line)
        if not opted_out and j > 0:
            opted_out = SILENCE.search(lines[j - 1])
        if not opted_out and j + 1 < len(lines):
            opted_out = SILENCE.search(lines[j + 1])
        if opted_out:
            continue
        # 키워드 추출
        m = TIER4.search(lines[ti])
        kw = m.group(1) if m else '?'
        issues.append(
            f"{path}:{j+1}: Tier 4 키워드 '{kw}' (line {ti+1}) 와 "
            f"자필 스타일 동시 사용 — §1.1.1 위반. "
            f"`indicatorLabel` 권장"
        )
        break  # 같은 Tier 4 라인 당 1회만

for it in issues:
    print(it)
PY
)

if [[ -n "$WARNINGS" ]]; then
    echo "" >&2
    echo "┌─ Notebook × Score 손글씨 4계층 점검 (§1.1.1) ──" >&2
    while IFS= read -r W; do
        [[ -z "$W" ]] && continue
        echo "│ $W" >&2
    done <<< "$WARNINGS"
    echo "│" >&2
    echo "│ 결정 트리: 작성 주체 사람 → Tier 1·2 (hand*) / 시스템 → Tier 4 (indicatorLabel)" >&2
    echo "│ Tier 4 키워드: 오늘 · 내일 · D-N · 미결제 · 필수 · 진행 중 · 대기 · 완료" >&2
    echo "│ 의도적 예외: 위반 라인에 '// ignore: handwriting-tier' 주석 (사유 명시)" >&2
    echo "│ 근거: docs/specs/design/notebook/README.md §1.1.1 + phase-log §7.127" >&2
    echo "└────────────────────────────────────────────────" >&2
fi

exit 0
