# Lesson Lifecycle — Chapter Model Design

> 2026-03-29 | Status: APPROVED (구현 대기)

## Overview

레슨 요청(UnifiedLessonRequest)의 전체 라이프사이클을 **하나의 채팅 스레드**에서 관리하되,
완료된 단계는 **접힌 요약**으로 표시하는 챕터 모델.

## Lifecycle Phases

```
Phase 1: 레슨 신청 (CURRENT — 구현 완료)
  레슨신청 → 시간협상 → 스케줄확정 → 수강권제안 → 결제

Phase 2: 수강권 발행 (NEW)
  수강권 발행 → (체험/정규/회차) 확인

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

  // Chapter 2: 수강권 & 결제 (NEW)
  paymentRequested,      // 선생님 → 학생: 결제 안내
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
| 수강권 | 결제 안내 전송 | 입금 완료 알림 |
| 레슨 진행 | 레슨 완료/취소/시간변경/메모 | 시간 변경 요청 |
| 완료 | 연장 제안 | 재수강 신청 |

## Progress Bar Component

```dart
class LessonProgressBar extends StatelessWidget {
  final RequestPhase currentPhase;
  // Renders: ●──●──●──○──○
  //          신청 확정 결제 진행 완료
}
```

5단계 시각화:
1. 신청 (pending~approved)
2. 확정 (timeConfirmed)
3. 결제 (paymentNotified~subscriptionIssued)
4. 진행 (inProgress)
5. 완료 (completed)

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
