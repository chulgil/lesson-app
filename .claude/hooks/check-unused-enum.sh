#!/bin/bash
# check-unused-enum.sh - PostToolUse Hook (Edit/Write/MultiEdit)
# 패턴 2 감지: enum/entity 정의만 있고 실제 로직에서 미사용인 경우 경고.
#
# 배경: design-principles.md "설정 필드 = 로직 사용" 원칙.
# FifthWeekPolicy, SubscriptionPaymentMethod 등 "정의만 있고 미사용" 반복 이슈 재발 방지.
#
# 동작:
#   - 편집한 파일에 `enum Xxx {` 또는 `class Xxx extends HiveObject` 정의가 있으면 추출
#   - 전체 features/, core/ 에서 `Xxx.` 사용처 grep
#   - 사용처 0이면 stderr로 경고 (exit 0 유지)

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

# .dart 파일만 대상
case "$FILE_PATH" in
    *.dart) ;;
    *) exit 0 ;;
esac

# entities/ 또는 models/ 경로만 검사 (다른 파일의 enum은 내부용일 가능성)
if [[ "$FILE_PATH" != *"/entities/"* ]] && [[ "$FILE_PATH" != *"/models/"* ]]; then
    exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SEARCH_ROOT="$REPO_ROOT/frontend/lib"

if [[ ! -d "$SEARCH_ROOT" ]]; then
    exit 0
fi

# 편집 파일에서 enum 이름들 추출
ENUMS=$(grep -E "^enum [A-Z][a-zA-Z0-9]+ " "$FILE_PATH" 2>/dev/null | awk '{print $2}')

if [[ -z "$ENUMS" ]]; then
    exit 0
fi

WARNINGS=()

while IFS= read -r ENUM_NAME; do
    [[ -z "$ENUM_NAME" ]] && continue

    # 자기 자신 파일 제외한 사용 카운트
    USAGE=$(grep -rn --include="*.dart" -E "\\b${ENUM_NAME}\\." "$SEARCH_ROOT" 2>/dev/null | grep -v "$FILE_PATH" | wc -l | tr -d ' ')

    if [[ "$USAGE" == "0" ]]; then
        WARNINGS+=("[unused-enum] enum $ENUM_NAME: 정의만 있고 외부 사용처 0건. 로직 구현 누락 가능")
    fi
done <<< "$ENUMS"

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "" >&2
    echo "┌─ 미사용 enum 감지 (설정만 있고 로직 미반영?) ─────" >&2
    for W in "${WARNINGS[@]}"; do
        echo "│ $W" >&2
    done
    echo "│ 원칙: .claude/rules/design-principles.md (설정 필드 = 로직 사용)" >&2
    echo "└───────────────────────────────────────────────" >&2
fi

exit 0
