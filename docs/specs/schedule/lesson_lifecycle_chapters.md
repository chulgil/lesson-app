# Lesson Lifecycle — Chapter Model Design

> 2026-03-29 | Status: APPROVED (구현 대기)

## Overview

레슨 요청(UnifiedLessonRequest)의 전체 라이프사이클을 **하나의 채팅 스레드**에서 관리하되,
완료된 단계는 **접힌 요약**으로 표시하는 챕터 모델.

## Lifecycle Phases

```
Phase 1: 레슨 신청 (CURRENT — 구현 완료)
  레슨신청 → 시간협상 → 스케줄확정 → 수강권제안 → 결제

Phase 2: 수강권 & 입금 (NEW — v2 설계 완료 2026-03-30)
  3가지 경로: 무료발급(체험) / 선불(기본) / 후불
  → 상세: "Phase 2 결제 플로우 설계" 섹션 참조

Phase 3: 레슨 진행 (NEW)
  레슨 1회차 완료 → 2회차 완료 → ... → 수강 완료
  (중간에 스케줄 변경, 취소, 연장 가능)
```

## UI Layout — Chapter Model

```
┌─────────────────────────────────────┐
│  ← 김민지 · 바이올린               │  AppBar
│  Progress: ●──●──●──○──○           │  Phase indicator
│           신청 확정 결제 진행 완료    │
├─────────────────────────────────────┤
│                                     │
│  ┌ 📋 레슨 신청 — 4/1 완료    [▼]  │  Chapter 1 (collapsed)
│  └ 4/5 토 14:00 확정                │  One-line summary
│                                     │
│  ┌ 💳 수강권 — 4/2 완료       [▼]  │  Chapter 2 (collapsed)
│  └ 정규 10회 · 월 4회 · 60분        │  One-line summary
│                                     │
│  🎵 레슨 진행 (3/10회)              │  Chapter 3 (expanded)
│    ✅ 1회차 4/5 완료                 │
│    ✅ 2회차 4/12 완료                │
│    ✅ 3회차 4/19 완료                │
│    📅 4회차 4/26 예정                │
│                                     │
├─────────────────────────────────────┤
│  [레슨 완료] [시간 변경] [메모 추가]  │  Action box (phase-aware)
└─────────────────────────────────────┘
```

## Chapter States

| Chapter | Collapsed (완료) | Expanded (활성) |
|---------|------------------|-----------------|
| 레슨 신청 | 아이콘 + 한 줄 요약 + 확정 일시 | 전체 채팅 이벤트 (기존 UI) |
| 수강권 | 아이콘 + 수강권 타입 + 회차 | 제안/수락/결제 이벤트 |
| 레슨 진행 | - (항상 확장) | 회차별 완료/예정 리스트 |

- 탭하면 접기/펼치기 토글
- 현재 활성 챕터만 기본 펼침
- 완료된 챕터는 기본 접힘

## Event Types Extension

```dart
enum RequestEventType {
  // Chapter 1: 레슨 신청 (기존)
  initialRequest,
  approve,
  reject,
  proposeAlternative,
  counterPropose,
  acceptAlternative,
  withdrawApproval,

  // Chapter 1→2 전환: 수강권 제안 (기존)
  subscriptionProposed,

  // Chapter 2: 수강권 & 입금 (NEW)
  paymentRequested,      // 선생님 → 학생: 입금 안내
  paymentConfirmed,      // 학생/학부모: 입금 완료 알림
  subscriptionIssued,    // 시스템: 수강권 발행 완료

  // Chapter 3: 레슨 진행 (NEW)
  lessonCompleted,       // 선생님: N회차 레슨 완료
  lessonCancelled,       // 양측: N회차 레슨 취소
  scheduleChanged,       // 양측: 스케줄 변경 합의
  lessonNoteAdded,       // 선생님: 레슨 노트 추가
  subscriptionRenewed,   // 수강권 연장/갱신
  subscriptionCompleted, // 전체 회차 완료
}
```

## Status Extension

```dart
enum UnifiedRequestStatus {
  // Phase 1 (기존)
  pending,
  negotiating,
  approved,
  timeConfirmed,
  proposalSent,
  proposalAccepted,
  paymentNotified,

  // Phase 2 (NEW)
  subscriptionIssued,    // 수강권 발행됨

  // Phase 3 (NEW)
  inProgress,            // 레슨 진행 중 (1회차 이상 완료)
  completed,             // 전체 회차 완료

  // Terminal (기존)
  rejected,
  cancelled,
  expired,
}
```

## Phase Detection Logic

```dart
RequestPhase get currentPhase {
  return switch (status) {
    // Phase 1: 신청~결제
    pending || negotiating || approved || timeConfirmed
        || proposalSent || proposalAccepted || paymentNotified
        => RequestPhase.request,

    // Phase 2: 수강권 발행
    subscriptionIssued => RequestPhase.subscription,

    // Phase 3: 레슨 진행
    inProgress => RequestPhase.lessons,

    // Terminal
    completed => RequestPhase.completed,
    rejected || cancelled || expired => RequestPhase.terminal,
  };
}
```

## Action Box by Phase

| Phase | Teacher Actions | Student Actions |
|-------|----------------|-----------------|
| 신청 | 수락/거절/역제안 | 대기/역제안 |
| 수강권 | 결제 경로 선택 (아래 상세) | 입금 완료 알림 |
| 레슨 진행 | 레슨 완료/취소/시간변경/메모 | 시간 변경 요청 |
| 완료 | 연장 제안 | 재수강 신청 |

## Phase 2 결제 플로우 설계 (v2, 2026-03-30)

> Phase 1 완료(timeConfirmed) → Phase 2 진입 시, 레슨 타입과 입금 확인 방식에 따라 3가지 경로로 분기.

### 결제 경로 3가지

```
timeConfirmed (시간 확정됨)
    │
    │  선생님이 3가지 발급 방법 중 선택 (카드형 UI)
    │
    ├─ 경로 A: 입금 확인 후 발급 (선불, 기본)
    │   UI: "입금 확인 후 발급 (선불)" 카드
    │   흐름: timeConfirmed → proposalSent → proposalAccepted
    │         → paymentNotified → (학생 입금) → (선생님 확인)
    │         → subscriptionIssued
    │   결제: 수강권 발급 전 완료
    │
    ├─ 경로 B: 먼저 발급 (후불)
    │   UI: "먼저 발급 (후불)" 카드
    │   흐름: timeConfirmed → subscriptionIssued (paymentConfirmed=false)
    │         → (레슨 진행 중) → paymentRequested → paymentConfirmed
    │   결제: 수강권 발급 후 나중에 안내
    │   ⚠️ 미수금으로 관리 (대시보드 미수금 목록 표시)
    │
    └─ 경로 C: 무료 발급
        UI: "무료 발급" 카드
        조건: 모든 레슨 타입에서 선택 가능 (체험/정규/회차)
        흐름: timeConfirmed → subscriptionIssued (amount=0, paymentConfirmed=true)
        결제: 없음. 즉시 수강권 발급
```

> **v2 변경 (2026-04-01)**: 무료 발급이 체험레슨에만 한정되지 않고, 모든 레슨 타입에서
> 선생님이 선택할 수 있도록 변경. 3가지 경로를 설명 카드형 UI로 통합 제공.

### 경로별 상태 전이 테이블

| From | Action | To | 조건 | 결제 상태 |
|------|--------|----|------|----------|
| timeConfirmed | 무료 수강권 발급 | subscriptionIssued | trial + 무료 | N/A |
| timeConfirmed | 선불 입금 안내 | proposalSent | 기본 경로 | 대기 |
| timeConfirmed | 후불 수강권 발급 | subscriptionIssued | 후불 선택 | 미수금 |
| proposalSent | 학생 수락 | proposalAccepted | - | 대기 |
| proposalAccepted | 학생 입금 완료 | paymentNotified | - | 입금 알림 |
| paymentNotified | 선생님 입금 확인 | subscriptionIssued | - | 완료 |

### Phase 2 선생님 액션 박스 UI

#### 시간 확정 직후 (timeConfirmed) — 결제 경로 선택

```
┌──────────────────────────────────────────────┐
│ 💳 수강권 & 입금                              │
│                                              │
│ 시간이 확정되었습니다. 수강권을 발급해주세요.    │
│                                              │
│  [입금 안내 보내기]    ← 선불 (기본, primary)   │
│  [수강권 먼저 발급]    ← 후불 (secondary)       │
└──────────────────────────────────────────────┘

※ 체험레슨(무료)인 경우:
┌──────────────────────────────────────────────┐
│ 🎁 체험 수강권                                │
│                                              │
│ 체험레슨이 확정되었습니다.                      │
│                                              │
│  [무료 수강권 발급]    ← 즉시 발급, 결제 없음    │
└──────────────────────────────────────────────┘
```

#### 입금 안내 BottomSheet (선불 선택 시)

```
┌──────────────────────────────────────────────┐
│ 입금 안내 보내기                 [✕]          │
│                                              │
│ 수강권 종류                                   │
│  ○ 월정액 (월 N회, 기간제)                    │
│  ● 회차권 (N회, 횟수제)                       │
│                                              │
│ 총 회차    [ 10 ] 회                         │
│ 금액       [ 400,000 ] 원                    │
│                                              │
│ 입금 안내 메시지 (선택)                        │
│ ┌──────────────────────────────────────┐     │
│ │ 입금 안내 메시지를 입력하세요...       │     │
│ └──────────────────────────────────────┘     │
│                                              │
│            [안내 보내기]                       │
└──────────────────────────────────────────────┘
```

#### 입금 대기 중 (paymentNotified) — 선생님 확인

```
┌──────────────────────────────────────────────┐
│ 💰 입금 확인 대기                             │
│                                              │
│ 학생이 입금 완료를 알렸습니다.                  │
│                                              │
│  [입금 확인 → 수강권 발급]    ← primary       │
│  [반려 (미확인)]              ← destructive    │
└──────────────────────────────────────────────┘
```

### Phase 2 학생 액션 박스 UI

#### 입금 안내 수신 (proposalSent)

```
┌──────────────────────────────────────────────┐
│ 💳 입금 안내                                  │
│                                              │
│ 회차권 10회 · 400,000원                       │
│ 계좌: [선생님 계좌 정보]                       │
│                                              │
│  [수락]              ← proposalAccepted       │
│  [거절]              ← rejected               │
└──────────────────────────────────────────────┘
```

#### 입금 완료 알림 (proposalAccepted)

```
┌──────────────────────────────────────────────┐
│ 💳 결제하기                                   │
│                                              │
│ 아래 계좌로 입금 후 버튼을 눌러주세요.          │
│ 계좌: [선생님 계좌 정보]                       │
│ 금액: 400,000원                               │
│                                              │
│  [입금 완료]          ← paymentNotified        │
└──────────────────────────────────────────────┘
```

### 후불 입금 확인 대기 관리

후불(경로 B)로 발급된 수강권은 `paymentConfirmed=false` 상태입니다.

- **대시보드**: 입금 확인 대기 N건 뱃지 표시
- **미수금 목록**: 학생별 미수금 수강권 리스트
- **입금 안내**: 미수금 수강권에서 "입금 안내 보내기" 버튼
- **입금 확인**: 학생 입금 → 선생님 확인 → `paymentConfirmed=true`

### 구현 우선순위

| 순서 | 항목 | 복잡도 |
|------|------|--------|
| 1 | 선불 입금 안내 카드 (경로 A) | Medium |
| 2 | 후불 즉시 발급 카드 (경로 B) | Low |
| 3 | 무료 발급 카드 (경로 C) | Low |
| 4 | 2단계 입금 확인 (학생→선생님) | Medium |
| 5 | 미수금 대시보드 | Medium |

## Progress Bar Component

```dart
class LessonProgressBar extends StatelessWidget {
  final RequestPhase currentPhase;
  // Renders: ●──●──●──○──○
  //          신청 확정 결제 진행 완료
}
```

5단계 시각화 — 각 단계의 정확한 의미:

| 단계 | 라벨 | 의미 | 상태 범위 |
|------|------|------|----------|
| 1 | 신청 | 학생이 레슨 신청 → 선생님이 수락/거절/시간 협상 | pending ~ approved |
| 2 | 확정 | 양측 스케줄 합의 완료 | timeConfirmed |
| 3 | 결제 | 입금 안내 → 학생 입금 → 선생님 확인 → 수강권 발급 | proposalSent ~ subscriptionIssued |
| 4 | 진행 | 레슨 1회차 ~ N회차 진행 중 | inProgress |
| 5 | 완료 | 수강권 회차/기간 소진으로 자동 완료 | completed |

> **참고**: "결제" 단계는 결제 + 수강권 발급까지를 포함합니다.
> 체험레슨(무료)의 경우 결제를 스킵하고 수강권이 즉시 발급됩니다.
> 후불의 경우 수강권이 먼저 발급되고 입금 확인은 나중에 진행됩니다.

## Chapter Summary Widget

```dart
class ChapterSummary extends StatelessWidget {
  final RequestPhase phase;
  final bool isCompleted;
  final String summary;     // e.g., "4/5 토 14:00 확정"
  final VoidCallback onTap; // 접기/펼치기

  // Collapsed: [icon] [title — date] [summary]  [▼]
  // Expanded:  [icon] [title]                    [▲]
  //            [full event list]
}
```

## Implementation Order

### Step 1: 엔티티 확장 (Backend + Frontend)
- RequestEventType에 Phase 2, 3 이벤트 추가
- UnifiedRequestStatus에 새 상태 추가
- RequestPhase enum + currentPhase getter

### Step 2: Progress Bar UI
- LessonProgressBar 위젯 (core/widgets/)
- AppBar 아래 또는 채팅 상단에 배치

### Step 3: Chapter Summary 위젯
- ChapterSummary 위젯 (접기/펼치기)
- 기존 request_history_chat.dart를 챕터별로 그룹핑

### Step 4: Action Box 확장
- CurrentRequestBox에 Phase 2, 3 액션 추가
- 레슨 완료/취소/시간변경 버튼

### Step 5: 레슨 진행 이벤트 연동
- 기존 Lesson 엔티티의 완료/취소를 RequestEvent로 자동 기록
- 수강권 회차 카운트 연동

## Related Files (Current)

| File | Role |
|------|------|
| `unified_lesson_request.dart` | 엔티티 + 상태 머신 |
| `request_event.dart` | 이벤트 소싱 모델 |
| `request_detail_screen.dart` | 채팅 화면 |
| `request_history_chat.dart` | 이벤트 → 채팅 버블 |
| `current_request_box.dart` | 턴 기반 액션 박스 |

## Comparison with Other Services

| Service | Model | Lesson App (Chapter) |
|---------|-------|---------------------|
| JIRA | 1 ticket, status changes, comments | 1 request, chapters, events |
| Amazon | 1 order → status timeline | 1 request → phase timeline |
| GitHub PR | code → review → CI → merge | request → schedule → payment → lessons |
| 카카오톡 | 1 chat room, endless scroll | 1 chat, collapsed chapters |
