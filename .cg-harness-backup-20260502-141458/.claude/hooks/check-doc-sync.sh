#!/bin/bash
# check-doc-sync.sh - PostToolUse Hook (Edit/Write/MultiEdit)
# 코드 파일 변경 시 매핑된 스펙 문서 위치를 안내하여 문서 동기화율을 높인다.
# CH03 "문서화 자동화 & 팀 단위 AI 코딩 에이전트 운영 규칙" 패턴 적용.
#
# 동작 원칙:
#   - stderr로만 경고를 내보낸다 (exit 0 유지, 편집은 막지 않음)
#   - 매핑된 스펙 문서가 실제로 존재할 때만 경고 (false-positive 억제)
#   - 코드와 문서를 함께 편집 중인 동일 세션에서는 경고 최소화 목적
#
# 매핑 정책은 문서에도 명시: .claude/rules/doc-sync.md

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

# 비어있으면 종료
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# 레포 루트 (lesson-app)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
SPECS_DIR="$DOCS_DIR/specs"

# 문서 파일 자체를 편집하는 경우는 제외 (자기 자신 경고 방지)
if [[ "$FILE_PATH" == *"/docs/"* ]]; then
    exit 0
fi

# 코드 파일이 아니면 스킵 (Dart/Swift/Python 만 대상)
case "$FILE_PATH" in
    *.dart|*.swift|*.py) ;;
    *) exit 0 ;;
esac

WARNINGS=()

# -- 1) frontend/lib/features/<domain>/  →  docs/specs/<mapped>/  --
if [[ "$FILE_PATH" == *"/frontend/lib/features/"* ]]; then
    # features/ 뒤 첫 세그먼트 추출
    FEATURE=$(echo "$FILE_PATH" | sed -E 's|.*/frontend/lib/features/([^/]+)/.*|\1|')

    # 복수→단수 매핑 (docs/specs/는 단수 폴더명 사용)
    case "$FEATURE" in
        lessons)       SPEC="lesson" ;;
        students)      SPEC="student" ;;
        notifications) SPEC="notification" ;;
        *)             SPEC="$FEATURE" ;;
    esac

    SPEC_PATH="$SPECS_DIR/$SPEC"
    if [[ -d "$SPEC_PATH" ]]; then
        WARNINGS+=("[doc-sync] features/$FEATURE 변경됨 → docs/specs/$SPEC/ 스펙도 확인/업데이트 필요")
    fi
fi

# -- 2) core/audio/<topic>* → docs/specs/<topic>/  --
if [[ "$FILE_PATH" == *"/frontend/lib/core/audio/"* ]]; then
    BASENAME=$(basename "$FILE_PATH")
    for TOPIC in metronome recording tuner; do
        if [[ "$BASENAME" == *"$TOPIC"* ]] && [[ -d "$SPECS_DIR/$TOPIC" ]]; then
            WARNINGS+=("[doc-sync] core/audio ($TOPIC) 변경됨 → docs/specs/$TOPIC/ 스펙도 확인/업데이트 필요")
        fi
    done
fi

# -- 3) iOS 메트로놈 네이티브 코드 → docs/specs/metronome/ --
if [[ "$FILE_PATH" == *"/ios/Runner/Metronome"* ]] || [[ "$FILE_PATH" == *"/ios/Runner/Audio/"*"Metronome"* ]]; then
    if [[ -d "$SPECS_DIR/metronome" ]]; then
        WARNINGS+=("[doc-sync] iOS Metronome 플러그인 변경됨 → docs/specs/metronome/ 스펙도 확인 필요")
    fi
fi

# -- 4) core/router/ → docs/architecture.md --
if [[ "$FILE_PATH" == *"/frontend/lib/core/router/"* ]]; then
    if [[ -f "$DOCS_DIR/architecture.md" ]]; then
        WARNINGS+=("[doc-sync] core/router 변경됨 → docs/architecture.md 구조 섹션 업데이트 필요")
    fi
fi

# -- 5) backend/ (FastAPI 라우트/모델) → docs/specs/backend/ --
if [[ "$FILE_PATH" == *"/backend/"* ]]; then
    BASENAME=$(basename "$FILE_PATH")
    case "$FILE_PATH" in
        *"/routes/"*|*"/routers/"*|*"/endpoints/"*|*"/api/"*)
            [[ -d "$SPECS_DIR/backend" ]] && WARNINGS+=("[doc-sync] backend API 경로 변경됨 → docs/specs/backend/ 스펙 업데이트 필요")
            ;;
        *"/models/"*|*"/schemas/"*|*"migration"*)
            [[ -d "$SPECS_DIR/backend" ]] && WARNINGS+=("[doc-sync] backend 모델/스키마 변경됨 → docs/specs/backend/ 데이터 스펙 업데이트 필요")
            ;;
    esac
fi

# 출력 (있을 때만)
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "" >&2
    echo "┌─ 문서 동기화 알림 ────────────────────────────" >&2
    for W in "${WARNINGS[@]}"; do
        echo "│ $W" >&2
    done
    echo "│ 규칙: .claude/rules/doc-sync.md" >&2
    echo "└───────────────────────────────────────────────" >&2
fi

exit 0
