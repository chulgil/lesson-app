#!/bin/bash
# check-spec-claim.sh - PostToolUse Hook (Edit/Write/MultiEdit)
# 패턴 1 감지: 스펙 문서에서 "구현 완료" 체크박스(- [x])를 표시했으나
# 실제 코드에 키워드가 없는 경우 경고.
#
# 배경: "Phase 1-2 구현 완료" 주장 vs 실제 Phase 1만 완료 (practice_master.md) 유형 반복.
# "설계 완료·코드 0%" 재발 방지.
#
# 동작 (경량):
#   - 편집 대상이 docs/specs/*.md 일 때만 동작
#   - 해당 파일에서 새로 체크된 줄(- [x])의 키워드를 추출
#   - 추출된 키워드 중 Flutter 식별자 후보(CamelCase, snake_case 파일명)가 있으면
#     frontend/lib/ 전체에서 grep
#   - 매칭 0건이면 stderr로 경고 (exit 0 유지)

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

# docs/specs/*.md 만 대상
case "$FILE_PATH" in
    *"/docs/specs/"*.md) ;;
    *) exit 0 ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SEARCH_ROOT="$REPO_ROOT/frontend/lib"

if [[ ! -d "$SEARCH_ROOT" ]]; then
    exit 0
fi

# 체크된 줄에서 백틱으로 감싼 식별자(`XxxYyy`, `xxx_yyy.dart`) 추출
IDENTIFIERS=$(grep -E "^\s*- \[x\]" "$FILE_PATH" 2>/dev/null \
    | grep -oE '`[A-Za-z_][A-Za-z0-9_]+(\.dart)?`' \
    | tr -d '`' \
    | sort -u)

if [[ -z "$IDENTIFIERS" ]]; then
    exit 0
fi

WARNINGS=()

while IFS= read -r IDENT; do
    [[ -z "$IDENT" ]] && continue

    # 파일명 (xxx.dart) 이면 Glob, 아니면 심볼 grep
    if [[ "$IDENT" == *.dart ]]; then
        FOUND=$(find "$SEARCH_ROOT" -name "$IDENT" 2>/dev/null | head -1)
        if [[ -z "$FOUND" ]]; then
            WARNINGS+=("[spec-claim] '완료' 체크된 \`$IDENT\` 파일이 frontend/lib/에 없음")
        fi
    else
        COUNT=$(grep -rn --include="*.dart" -E "\\b${IDENT}\\b" "$SEARCH_ROOT" 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$COUNT" == "0" ]]; then
            WARNINGS+=("[spec-claim] '완료' 체크된 \`$IDENT\` 심볼이 코드에 없음 — 설계만 완료 가능성")
        fi
    fi
done <<< "$IDENTIFIERS"

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "" >&2
    echo "┌─ 스펙-코드 괴리 감지 (체크박스 vs 실제 코드) ─────" >&2
    for W in "${WARNINGS[@]}"; do
        echo "│ $W" >&2
    done
    echo "│ 권장: 스펙에서 - [x]로 표시하기 전 실제 코드 확인" >&2
    echo "└───────────────────────────────────────────────" >&2
fi

exit 0
