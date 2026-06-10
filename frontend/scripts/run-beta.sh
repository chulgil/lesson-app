#!/bin/bash
# ============================================================
# Lessonaza Frontend — Beta 환경 실행
# ============================================================
# Usage: ./scripts/run-beta.sh [device_id]
#
# Google SSO + Beta API 연동
# ============================================================

set -e

DEVICE=${1:-""}
DEVICE_FLAG=""
if [ -n "$DEVICE" ]; then
  DEVICE_FLAG="-d $DEVICE"
fi

echo "[run-beta] device='$DEVICE' flag='$DEVICE_FLAG'"
echo "[run-beta] flutter run command:"
set -x
flutter run $DEVICE_FLAG \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://api-beta.lessonaza.app/api/v1 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=312292843644-5u5rl9uupa80pgi5vt69tj9lj1u6e9d5.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=312292843644-4i6n21tp6vagfltl2p1i7jlvk1avh0n7.apps.googleusercontent.com
