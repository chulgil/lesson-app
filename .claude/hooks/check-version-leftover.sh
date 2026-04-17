#!/bin/bash
# check-version-leftover.sh - PostToolUse Hook (Edit/Write/MultiEdit)
# 패턴 3 감지: 스펙 버전 업(v6→v7) 후 이전 버전 문자열이 코드에 잔존하면 경고.
#
# 배경:
#   - subscription: v6 `proposal_detail_screen` 잔재 (fontSize 하드코딩)
#   - lesson: 통합 플로우 v2 설계 ↔ 구현은 v1 구조
#   - practice: "Phase 1-2 구현 완료" 주장 vs 실제 Phase 1만
#
# 동작:
#   - 편집한 스펙 파일의 frontmatter `version:` 또는 본문 내 `v[0-9]+` 스캔
#   - 현재 버전보다 낮은 vN 문자열이 코드 또는 다른 스펙에 남아있는지 확인
#   - 최신 버전 - 1 이상 낮은 잔재가 발견되면 경고

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

# docs/specs/*.md 또는 .dart 둘 다 대상
case "$FILE_PATH" in
    *"/docs/specs/"*.md|*.dart) ;;
    *) exit 0 ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SEARCH_ROOT="$REPO_ROOT/frontend/lib"
SPECS_ROOT="$REPO_ROOT/docs/specs"

# 파일에서 "v2 →", "v6 → v7", "v7 구조" 등 버전 전환 패턴 추출
TRANSITIONS=$(grep -oE "v[0-9]+\s*→\s*v[0-9]+|v[0-9]+에서 v[0-9]+" "$FILE_PATH" 2>/dev/null | head -3)

if [[ -z "$TRANSITIONS" ]]; then
    exit 0
fi

WARNINGS=()

while IFS= read -r TRANS; do
    [[ -z "$TRANS" ]] && continue

    # 이전 버전(낮은 숫자) 추출
    OLD_VER=$(echo "$TRANS" | grep -oE "v[0-9]+" | head -1)
    NEW_VER=$(echo "$TRANS" | grep -oE "v[0-9]+" | tail -1)

    [[ -z "$OLD_VER" || "$OLD_VER" == "$NEW_VER" ]] && continue

    # 코드에서 이전 버전 문자열 잔존 여부 확인
    CODE_COUNT=$(grep -rn --include="*.dart" -oE "['\"][^'\"]*${OLD_VER}[^'\"]*['\"]" "$SEARCH_ROOT" 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$CODE_COUNT" -gt 0 ]]; then
        WARNINGS+=("[version-leftover] ${OLD_VER} → ${NEW_VER} 전환 중, 이전 버전 문자열 ${CODE_COUNT}건 코드에 잔존")
    fi
done <<< "$TRANSITIONS"

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "" >&2
    echo "┌─ 버전 전환 잔재 감지 ─────────────────────────────" >&2
    for W in "${WARNINGS[@]}"; do
        echo "│ $W" >&2
    done
    echo "│ 권장: grep으로 이전 버전 잔재 확인 후 제거" >&2
    echo "└───────────────────────────────────────────────" >&2
fi

exit 0
