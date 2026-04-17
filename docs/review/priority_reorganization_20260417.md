# 우선순위 재조정 — 실제 구현 상태 검증 결과

> 작성일: 2026-04-17
> 배경: 리뷰 리포트의 "코드 0%" 주장 중 상당수가 실제로는 이미 구현되어 있음을 #222 검증 중 발견.
> 다음 Sprint 진행 전 **모든 open 이슈의 실제 구현률을 grep 증거 기반으로 재측정**한 결과.

---

## 검증 매트릭스

| # | 타이틀 | 리뷰 주장 | 실제 증거 | 실제 구현률 | 권장 조치 |
|---|--------|-----------|-----------|:-----------:|-----------|
| **222** | 뱃지 시스템 | 🔴 "설계 완료·코드 0%" | `features/gamification/` 전체 존재: `PracticeBadge`, `BadgeRarity`, `PointAwardNotifier`, `BadgeCollectionScreen`, `/gamification/badges` 라우트, 대시보드 진입점 | **~85%** | **스코프 축소** → 반자동 트리거 배선만 (awardStreakBonus 호출처 0, BadgeChecker 부재) |
| **224** | 취소 정책 + FifthWeekPolicy | 🟠 "스펙 모순 + FifthWeekPolicy 미구현" | `FifthWeekPolicy` enum **18+ 사용처** (mock_subscription_repository, subscription.dart), `cancelledByStudentLate` enum 존재, `lesson_policy_screen.dart` 존재 | **~70%** | **스코프 축소** → 스펙 모순 일원화만 (코드 구현은 충분) |
| **225** | 선생님 연습 현황 탭 | 🟠 "공유 녹음 수신부 없음" | `sharedAt` 필드는 있으나, 선생님 뷰에서 공유 녹음을 **수신·표시하는 탭/위젯 grep 0건** | **~10%** | **유지** — 유일하게 진짜 "0%"에 가까운 항목 |
| **226** | 레슨 장소 UI | 🟠 "설계 완료·UI 0%" | `location_travel_selector.dart`, `location_summary_card.dart`, `LessonLocationInfo`, `lesson_location_info_card.dart` 등 **다수 파일 존재** | **~60%** | **스코프 축소** → 스펙 갭 확인 후 누락분만 |
| **227** | 스케줄 확인 카드 | 🟡 "학생 UX 핵심 미구현" | `schedule_confirmation_card_providers.dart` 존재 + "Backend API 미구현" 주석 | **~40%** | **유지** — UI는 있으나 백엔드 연동 필요 |
| **228** | A/B 녹음 비교 재생 | 🟡 "Phase 2 미구현" | `recording_waveform.dart`에 **`ABLoop` 위젯 이미 구현** | **~80%** | **닫기 or 스코프 축소** — 기본 A/B 루프 완성, 동시 2트랙 비교만 추가 검토 |
| **229** | 노쇼 처리 정책 UI | 🟡 "UI + 분쟁 감소" | `NoShowPolicy` enum, `_buildNoShowPolicy()` in `lesson_policy_screen.dart`, group class `미참석 시` 분기 존재 | **~75%** | **스코프 축소** → "학생 미도착" 버튼만 (있으면 닫기) |
| **230** | 레퍼토리 히스토리 타임라인 | 🟡 "미구현" | `RepertoireHistoryScreen` + provider 이미 존재 | **~80%** | **닫기 or 스코프 축소** — UI 미세 조정만 |
| **231** | fontSize/EdgeInsets + v6 잔재 | 🟡 "일괄 마이그레이션" | `proposal_detail_screen.dart:263/395/401` fontSize 하드코딩 확정 | **리팩토링 작업** | **유지** — 범위 축소된 v6 제거만 |
| **232** | 입금 확인 플로우 UX | 🟠 "관리 앱 UX 간소화" | `paymentConfirmed`/`studentConfirmed` 플로우 `issue_subscription_actions.dart`에 존재 | **~60%** | **유지** — UX 간소화는 실제 과제 |

---

## 근본 원인 분석

**리뷰 리포트의 체계적 과대평가**:

1. **피처 디렉토리 미탐색**: 리뷰는 `docs/specs/` 체크박스 기반. 실제 `features/gamification/` 전체 모듈이 누락 판정됨.
2. **"정의만 있고 로직 없음" 오진단**: FifthWeekPolicy는 18+ 호출처가 있으나 "미사용"으로 기재.
3. **경쟁사 비교로부터 누락 추론**: 실제 코드 grep 없이 "다른 서비스에 있으니 우리도 없다"는 가정.

→ 새 훅(`check-spec-claim.sh`, `check-unused-enum.sh`)이 이 패턴을 잡도록 설계됨. **이번 리뷰는 훅 도입 전 생성된 인공물**.

---

## 재조정된 우선순위 (실제 갭 기준)

| 순위 | 이슈 | 실제 작업 | 소요 |
|:----:|------|-----------|:----:|
| 🥇 1 | **#225** 선생님 연습 현황 탭 | 공유 녹음 수신부 — 유일한 진짜 0% | 2-3일 |
| 🥈 2 | **#232** 입금 확인 플로우 UX 간소화 | 관리 앱 UX — paymentConfirmed 기반 원탭 | 2일 |
| 🥉 3 | **#222** 뱃지 시스템 자동 배선 | BadgeChecker + awardStreakBonus 호출처 연결 | **0.5-1일** (스코프 축소) |
| 4 | **#227** 스케줄 확인 카드 백엔드 연동 | 백엔드 API 구현 후 연결 | 1-2일 |
| 5 | **#231** v6 하드코딩 잔재 제거 | `proposal_detail_screen` 3개 라인 + fontSize 일괄 | 0.5일 |
| 6 | **#226** 레슨 장소 스펙 갭 | 존재하는 UI 확인 후 누락분만 | 1일 |
| 7 | **#224** 취소 정책 스펙 일원화 | 문서 작업 중심 (코드는 충분) | 0.5일 |

## 닫기 권장

| 이슈 | 이유 |
|------|------|
| **#228** A/B 비교 | `ABLoop` 이미 구현, 기본 기능 완성 |
| **#229** 노쇼 UI | `_buildNoShowPolicy()` 이미 존재, 스펙 모순만 정리 |
| **#230** 레퍼토리 히스토리 | `RepertoireHistoryScreen` 이미 존재 |

---

## 다음 액션

1. 각 이슈에 검증 결과 코멘트 + 라벨 조정 (close 3건, priority 재조정)
2. Sprint 순서: **#225 → #232 → #222 축소판**
3. 리뷰 문서(`review_mode_b_summary_20260417.md`)에 "실제 상태 검증 결과" 섹션 추가
