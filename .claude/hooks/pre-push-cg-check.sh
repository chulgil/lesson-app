#!/usr/bin/env bash
# pre-push 게이트 — cg check --strict 로 spec 드리프트 차단.
#
# 설치 (한 번만):
#   ln -s ../../.claude/hooks/pre-push-cg-check.sh .git/hooks/pre-push
#   chmod +x .claude/hooks/pre-push-cg-check.sh
#
# 동작:
#   docs/specs/ 의 SHA1 스냅샷이 .claude/harness-signals/drift.json 과
#   다르면 (스펙 변경 + 마지막 cg check 미실행) 푸시 차단. 사용자가
#   `cg check` 를 실행해 의도된 변경임을 명시적으로 확인해야 통과.
#
# 우회:
#   git push --no-verify   # 비상시만. 일상적 사용 금지.

set -e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

if [ ! -d "docs/specs" ]; then
  exit 0
fi

# v0.7.0+ 가 필요 (--strict 옵션). 우선순위:
#   1. ~/.local/bin/cg (uv tool install 결과 — 가장 최신)
#   2. PATH 의 cg (pyenv shim 등 시스템 설치)
#   3. uvx 로 최신 cg-harness 임시 실행
resolve_cg() {
  if [ -x "$HOME/.local/bin/cg" ]; then
    if "$HOME/.local/bin/cg" check --help 2>&1 | grep -q "\-\-strict"; then
      echo "$HOME/.local/bin/cg"
      return 0
    fi
  fi
  if command -v cg >/dev/null 2>&1; then
    if cg check --help 2>&1 | grep -q "\-\-strict"; then
      echo "cg"
      return 0
    fi
  fi
  if command -v uvx >/dev/null 2>&1; then
    echo "uvx --from cg-harness cg"
    return 0
  fi
  return 1
}

CG_CMD=$(resolve_cg) || {
  echo "[pre-push] cg-harness CLI 미설치 — 게이트 통과 (설치: uv tool install cg-harness)" >&2
  exit 0
}

JSON=$($CG_CMD check --path "$ROOT" --no-save --json 2>/dev/null) || {
  echo "[pre-push] cg check 실행 실패 — 게이트 통과 (사후 점검 권장)" >&2
  exit 0
}

CHANGED=$(echo "$JSON" | python3 -c "import json,sys;d=json.load(sys.stdin);s=d.get('summary',{});print(s.get('changed_total',0)+s.get('added',0)+s.get('removed',0))")

if [ "${CHANGED:-0}" -gt 0 ]; then
  echo "" >&2
  echo "[pre-push] ❌ spec 드리프트 감지 — drift.json 미동기화." >&2
  echo "" >&2
  $CG_CMD check --path "$ROOT" --no-save >&2 || true
  echo "" >&2
  echo "  대처:" >&2
  echo "    1) cg check          # 의도된 변경이면 drift.json 갱신 후 재시도" >&2
  echo "    2) git push --no-verify  # 비상 우회 (일상 사용 금지)" >&2
  exit 1
fi

exit 0
