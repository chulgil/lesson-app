# 모드 B 통합 요약 — Lesson / Practice / Subscription

> 작성일: 2026-04-17
> 상세 리포트: [lesson](domain_lesson_20260417.md) · [practice](domain_practice_20260417.md) · [subscription](domain_subscription_20260417.md)
> 상위 리포트: [review_overview_20260417.md](review_overview_20260417.md)

---

## 도메인 비교 매트릭스

> **스코프 정정 (2026-04-17)**: 본 앱은 **결제 관리(Payment Management) 앱**. PG 연동·결제 SDK는 범위 밖. subscription 관련 "간편결제" 문구는 "입금 확인 UX 간소화"로 대체됨.

| 차원 | lesson | practice | subscription |
|------|:------:|:--------:|:------------:|
| **구현율** | 64% (27/42) | 56% | Phase 1 대부분 ✅ |
| **핵심 누락** | FifthWeekPolicy, 통합 플로우, 보강 추적 | 뱃지, A/B 비교, 히스토리 | 입금 확인 UX, 스케줄 확인 카드, 갱신 자동화 |
| **스펙 모순 개수** | 3 | 5 | 3 |
| **하드코딩 (Color) 0건** | ✅ | ✅ | ✅ |
| **fontSize 직접** | 12건 | 2-3건 | 4건 |
| **EdgeInsets 직접** | 18건 | 5-7건 | 다수 |
| **한글 Text 직접** | 5건 | (샘플만 확인) | (샘플만 확인) |
| **상세화면 일관성** | ⚠️ 액션바 2가지 | ⚠️ 진입 UX 3가지 | ✅ 양호 |

---

## 공통 패턴 (3개 도메인에서 반복 관찰)

### 패턴 1: "설계 완료 · 코드 0%" 기능 다수
- **lesson**: 빠른 레슨 등록, 레슨 장소 UI, 5주차 정책
- **practice**: 뱃지, A/B 비교, 히스토리 타임라인
- **subscription**: 스케줄 확인 카드, 학부모-자녀 결제 기록 분리

→ **원인 가설**: 스펙 작성 → 구현으로 넘어가는 체계가 약함. TODO/Issue 자동 생성 훅 필요.

### 패턴 2: enum/엔티티 정의만, 로직 미반영
- `FifthWeekPolicy` (lesson)
- `Recording.sharedAt` (practice — 선생님 뷰 없음)
- `SubscriptionPaymentMethod` (subscription — 관리 UX 연결 미완)

→ **원인 가설**: "데이터 구조는 설계 우선" 원칙이 UI 구현으로 닿지 않음. `.claude/rules/design-principles.md`의 "설정 필드 = 로직 사용" 원칙 위반 패턴.

### 패턴 3: 버전 전환 잔재 (v7 → v6, Phase 2 → Phase 1)
- `subscription`: v6 `proposal_detail_screen` fontSize 하드코딩 잔재
- `practice`: "Phase 1-2 구현 완료" 주장 vs 실제 Phase 1만 완료
- `lesson`: 통합 플로우 v2 설계 ↔ 구현은 v1 구조

→ **원인 가설**: 스펙 버전 업 시 이전 버전 마킹/제거 프로세스 부재.

---

## 통합 Top 10 우선순위 (모드 B 심층 기준)

| # | 도메인 | 심각도 | 이슈 | 소요 |
|---|--------|:------:|------|:----:|
| 1 | practice | 🔴 CRIT | 뱃지 시스템 (설계 완료, 코드 0%) | 2-3일 |
| 2 | subscription | 🟠 HIGH | 입금 확인 플로우 UX 간소화 (관리 앱 #232) | 3-5일 |
| 3 | lesson | 🟠 HIGH | 취소 정책 스펙 모순 일원화 + FifthWeekPolicy 구현 | 3-5일 |
| 4 | practice | 🟠 HIGH | 선생님 연습 현황 탭 (공유 녹음 수신부) | 3일 |
| 5 | lesson | 🟠 HIGH | 레슨 장소 UI (설계 완료, UI 0%) | 2-3일 |
| 6 | subscription | 🟡 MED | 스케줄 확인 카드 (학생 UX 핵심, §1138) | 2일 |
| 7 | practice | 🟡 MED | A/B 비교 재생 (경쟁사 차별화 -1 Phase) | 3일 |
| 8 | lesson | 🟡 MED | 노쇼 처리 정책 UI + 분쟁 감소 | 2-3일 |
| 9 | practice | 🟡 MED | 레퍼토리 히스토리 타임라인 | 2일 |
| 10 | 전체 | 🟡 MED | v6→v7 잔재 정리 + fontSize/EdgeInsets 일괄 마이그레이션 | 1주 (배치) |

---

## 하네스(시스템)가 잡아냈어야 할 패턴

> 이 섹션은 사용자가 다른 곳에서 진행 중인 "하네스 점검"과 연관. 이번 분석에서 관찰된 **반복 이슈 유형**을 기록해 둠.

| 관찰된 이슈 패턴 | 하네스가 감지할 수단 (제안) |
|------------------|--------------------------|
| enum/엔티티 정의 후 로직 미반영 | `grep` 훅: `enum X` 정의 → `X\.` 사용처 스캔, 0이면 경고 |
| 스펙 버전 업 후 이전 UI 잔재 | 스펙 frontmatter `version:` + 버전 변경 시 관련 코드 자동 탐색 |
| "설계 완료" vs 실제 코드 괴리 | `docs/specs/*.md` 내 체크리스트 `- [x]` vs 실제 grep 결과 대조 |
| 하드코딩 역주입 (신규 PR) | `pre-commit` 훅: `Text('[가-힣]'` 추가 감지 시 경고 |
| detail 화면 패턴 불일치 | `detail_screen_template.md` 체크리스트 자동화 (커밋 훅) |

이 5개 패턴은 **단발성 수정이 아닌, 하네스(룰+훅+스킬)로 구조화해야 재발 방지 가능**.

---

## 다음 액션 제안

**즉시 (이번 주)**:
1. 이 리포트를 기반으로 Issue 생성 (#1 뱃지, #3 취소 정책 모순 우선)
2. `/ralph-loop`으로 Top 10 중 단순 이슈(fontSize/EdgeInsets) 일괄 마이그레이션

**다음 세션 추천**:
- `/auto --mode refactor docs/review/review_overview_20260417.md 의 #1 AppStrings 마이그레이션 schedule 도메인`
- 또는 모드 C (UX 일관성 전 도메인) — 이번에 확인 안 한 student_home/profile/schedule 포함
