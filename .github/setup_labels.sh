#!/bin/bash
# GitHub Labels 설정 스크립트
# 사용법: cd lesson-app && ./.github/setup_labels.sh

echo "Setting up GitHub labels for lesson-app..."

# 기존 기본 라벨 삭제 (선택사항)
# gh label delete "bug" --yes 2>/dev/null
# gh label delete "enhancement" --yes 2>/dev/null

# === 타입 라벨 ===
gh label create "bug" --color "d73a4a" --description "버그 수정" --force
gh label create "feature" --color "0075ca" --description "새 기능" --force
gh label create "enhancement" --color "a2eeef" --description "기능 개선" --force
gh label create "refactor" --color "7057ff" --description "리팩토링" --force
gh label create "docs" --color "0075ca" --description "문서 작업" --force
gh label create "test" --color "bfd4f2" --description "테스트" --force
gh label create "claude" --color "6f42c1" --description "Claude 작업" --force

# === 우선순위 라벨 ===
gh label create "priority: critical" --color "b60205" --description "긴급 - 즉시 해결" --force
gh label create "priority: high" --color "d93f0b" --description "높음" --force
gh label create "priority: medium" --color "fbca04" --description "보통" --force
gh label create "priority: low" --color "0e8a16" --description "낮음" --force

# === 상태 라벨 ===
gh label create "status: todo" --color "ededed" --description "시작 전" --force
gh label create "status: in-progress" --color "0052cc" --description "진행 중" --force
gh label create "status: blocked" --color "b60205" --description "차단됨" --force
gh label create "status: review" --color "fbca04" --description "검토 중" --force
gh label create "status: done" --color "0e8a16" --description "완료" --force

# === 도메인 라벨 (lesson-app 전용) ===
gh label create "domain: lesson" --color "c5def5" --description "레슨 관리" --force
gh label create "domain: student" --color "c5def5" --description "학생 관리" --force
gh label create "domain: parent" --color "c5def5" --description "학부모 연동" --force
gh label create "domain: practice" --color "c5def5" --description "연습 기록" --force
gh label create "domain: payment" --color "c5def5" --description "결제/정산" --force
gh label create "domain: schedule" --color "c5def5" --description "스케줄/캘린더" --force
gh label create "domain: notification" --color "c5def5" --description "알림" --force
gh label create "domain: auth" --color "c5def5" --description "인증/로그인" --force
gh label create "domain: onboarding" --color "c5def5" --description "온보딩" --force

# === 플랫폼 라벨 ===
gh label create "platform: ios" --color "000000" --description "iOS 관련" --force
gh label create "platform: android" --color "3ddc84" --description "Android 관련" --force
gh label create "platform: macos" --color "999999" --description "macOS 관련" --force

echo "✅ Labels setup complete!"
echo ""
echo "Created labels:"
gh label list
