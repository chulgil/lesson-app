#!/bin/bash
# ============================================================
# Lessonaza Frontend — Beta 환경 실행
# ============================================================
# Usage: ./scripts/run-beta.sh [device_id] [--iphone] [--release] [...flutter flags]
#
#   device_id   flutter 디바이스 ID/이름 (예: macos, chrome, <시뮬레이터 UDID>)
#   --iphone    USB/무선 연결된 실제 iPhone 자동 선택 (시뮬레이터·iPad 제외)
#   --release   release 모드로 실행 (그 외 모든 --플래그는 flutter run 으로 전달)
#
# Google SSO + Beta API 연동
# ============================================================

set -e

DEVICE=""
USE_IPHONE=false
EXTRA_FLAGS=()

# 인자 파싱: 위치 인자=device_id, --iphone=실기기 자동선택, 그 외 --플래그=flutter 전달
for arg in "$@"; do
  case "$arg" in
    --iphone)
      USE_IPHONE=true
      ;;
    --*)
      EXTRA_FLAGS+=("$arg")
      ;;
    *)
      DEVICE="$arg"
      ;;
  esac
done

# --iphone: 연결된 실제 iPhone(시뮬레이터·iPad 제외)을 자동 탐색
if [ "$USE_IPHONE" = true ]; then
  DEVICE=$(flutter devices --machine 2>/dev/null | python3 -c '
import json, sys
try:
    devices = json.load(sys.stdin)
except Exception:
    devices = []
phones = [d for d in devices
          if str(d.get("targetPlatform", "")).startswith("ios")
          and not d.get("emulator", False)
          and "ipad" not in str(d.get("name", "")).lower()]
print(phones[0]["id"] if phones else "")
') || DEVICE=""
  if [ -z "$DEVICE" ]; then
    echo "연결된 실제 iPhone을 찾을 수 없습니다. 기기 연결·신뢰(Trust)·잠금 해제 상태를 확인하세요." >&2
    echo "현재 인식된 기기 목록:" >&2
    flutter devices >&2 || true
    exit 1
  fi
  echo "선택된 iPhone: $DEVICE"
fi

DEVICE_FLAG=()
if [ -n "$DEVICE" ]; then
  DEVICE_FLAG=(-d "$DEVICE")
fi

flutter run "${DEVICE_FLAG[@]}" "${EXTRA_FLAGS[@]}" \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://api-beta.lessonaza.app/api/v1 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=312292843644-5u5rl9uupa80pgi5vt69tj9lj1u6e9d5.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=312292843644-4i6n21tp6vagfltl2p1i7jlvk1avh0n7.apps.googleusercontent.com
