#!/bin/bash
# lore-context.sh - 경로별 Lore trailer 조회 CLI
#
# 정책: .claude/rules/lore-trailer-migration.md
# 글로벌: ~/.claude-forge/rules/lore-commit.md (3 공식 키)
#
# 사용법:
#   .claude/scripts/lore-context.sh <path>
#   .claude/scripts/lore-context.sh <path> --days 90
#   .claude/scripts/lore-context.sh <path> --key directive
#   .claude/scripts/lore-context.sh <path> --key rejected --days 180
#
# 출력: 해당 경로에 영향을 준 커밋의 Lore-* trailer 만 추출

set -euo pipefail

usage() {
    cat <<EOF
사용법: $0 <path> [--days N] [--key directive|constraint|rejected]

옵션:
  --days N       최근 N일만 (기본: 전체 history)
  --key KEY      특정 키만 (directive/constraint/rejected, 기본: 전체)
  -h, --help     이 도움말

예시:
  $0 docs/specs/design/notebook/
  $0 frontend/lib/features/students/ --days 90
  $0 . --key rejected
EOF
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

PATH_ARG=""
DAYS=""
KEY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --days)
            DAYS="$2"
            shift 2
            ;;
        --key)
            KEY="$2"
            shift 2
            ;;
        *)
            if [[ -z "$PATH_ARG" ]]; then
                PATH_ARG="$1"
            else
                echo "Error: 인자 과다 ($1)" >&2
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$PATH_ARG" ]]; then
    echo "Error: <path> 인자 필수" >&2
    usage
    exit 1
fi

if [[ -n "$KEY" ]]; then
    case "$KEY" in
        directive|constraint|rejected) ;;
        *)
            echo "Error: --key 는 directive/constraint/rejected 중 하나" >&2
            exit 1
            ;;
    esac
fi

GREP_PATTERN="^Lore-"
if [[ -n "$KEY" ]]; then
    GREP_PATTERN="^Lore-${KEY}:"
fi

GIT_ARGS=(log --grep="$GREP_PATTERN" --format='%h|%ai|%s%n%b%n---END---')
if [[ -n "$DAYS" ]]; then
    GIT_ARGS+=(--since="${DAYS} days ago")
fi
GIT_ARGS+=(-- "$PATH_ARG")

GIT_OUTPUT=$(git "${GIT_ARGS[@]}")

KEY_FILTER="$KEY" GIT_DATA="$GIT_OUTPUT" python3 <<'PY'
import os, re, sys

key_filter = os.environ.get('KEY_FILTER', '')
data = os.environ.get('GIT_DATA', '')

if not data.strip():
    print("(no Lore trailers found)")
    sys.exit(0)

LORE_RE = re.compile(r'^Lore-(directive|constraint|rejected):\s*(.+)$', re.MULTILINE | re.IGNORECASE)

records = data.split('---END---\n')
shown = 0
for rec in records:
    rec = rec.strip()
    if not rec:
        continue
    lines = rec.split('\n', 1)
    header = lines[0]
    body = lines[1] if len(lines) > 1 else ''

    matches = LORE_RE.findall(body)
    if key_filter:
        matches = [m for m in matches if m[0].lower() == key_filter.lower()]
    if not matches:
        continue

    parts = header.split('|', 2)
    if len(parts) != 3:
        continue
    sha, date, subject = parts
    print(f"\n{sha}  {date[:10]}  {subject}")
    for k, v in matches:
        print(f"  Lore-{k.lower():10s} {v.strip()}")
    shown += 1

if shown == 0:
    print("(no Lore trailers found)")
PY
