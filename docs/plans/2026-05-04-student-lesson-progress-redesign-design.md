# Student Lesson Progress Redesign Design

> Date: 2026-05-04
> Status: Approved direction, ready for implementation planning

## Goal

학생 홈의 레슨 신청, 수강권 제안, 입금, 수강권 준비, 스케줄 확정 흐름을 선생님 홈의 레슨요청/스케줄 조절과 같은 정보 구조로 개편한다.

## Product Principle

선생님 홈은 "오늘 처리해야 할 운영 업무"를 정리한다. 학생 홈은 같은 구조를 쓰되 "내가 지금 확인해야 할 레슨 진행 상태"를 정리한다.

따라서 두 화면은 같은 골격을 공유한다.

| Layer | Teacher Home | Student Home |
|---|---|---|
| Primary focus | 오늘 레슨 | 다음 레슨 |
| Resource state | 수강권/미수금/확인 필요 | 내 수강권/잔여 횟수 |
| Work queue | 레슨요청, 스케줄 조절 | 레슨 진행 타임라인 |
| Support area | 과제/통계 | 연습/피드백 |

## Target Student Home Structure

```
Notebook masthead
Programme title
Time context banner
Gamification
Getting started
Next lesson
Student subscription summary
Lesson progress timeline
Learning record group
Fine footer
```

`Lesson progress timeline` replaces the current scattered event group:

- `LessonRequestSection(userId, viewerRole: student)`
- `SubscriptionRenewalBanner`
- `PendingProposalsBanner`
- `_ScheduleConfirmationSection`

## Lesson Progress Timeline

The timeline is a single section with the same visual grammar as teacher home sections:

- `NotebookSectionHeader`
- compact status summary line
- top/bottom ink rule
- row-based items
- right-side status chip and timestamp
- no standalone marketing-style banners

Recommended label:

```
레슨 진행 · N
```

Recommended summary examples:

```
내가 할 일 1 · 대기 2 · 완료 1
```

## Timeline Item Model

Each row represents one student-facing progress item.

| Field | Description |
|---|---|
| `id` | Stable item id |
| `kind` | request, proposal, payment, subscriptionReady, scheduleConfirmation, renewal |
| `priority` | actionRequired, waiting, completed |
| `title` | One-line title |
| `subtitle` | Context text |
| `statusLabel` | Short chip text |
| `createdAt` | For elapsed label |
| `route` | Detail destination |

Priority order:

1. `actionRequired`: the student must choose, confirm, pay, or review.
2. `waiting`: the student is waiting for the teacher or system.
3. `completed`: recently completed milestone.

## Flow Mapping

| Flow State | Student Timeline Copy | Priority | Route |
|---|---|---|---|
| initial request pending | 레슨 신청을 보냈어요 | waiting | request detail |
| teacher alternative proposed | 선생님이 가능한 시간을 제안했어요 | actionRequired | request detail |
| proposal sent | 수강권 조건을 확인해주세요 | actionRequired | proposal detail |
| proposal accepted | 입금 후 완료 알림을 보내주세요 | actionRequired | request detail |
| payment notified | 선생님이 입금을 확인하고 있어요 | waiting | request detail |
| subscription issued, schedule needed | 수강권이 준비됐어요 | actionRequired | schedule confirmation |
| subscription issued, schedule exists | 수강권이 준비됐어요 | completed | subscription detail |
| renewal needed | 수강권 갱신이 필요해요 | actionRequired | lesson request |

## Subscription Issued UX

Do not treat subscription issuance as a blunt completion toast. It is a transition point from "purchase/issue" to "start lessons".

User-facing phrase:

```
수강권이 준비됐어요
```

Context copy:

- Schedule confirmation needed: `첫 레슨 시간을 확인해주세요`
- Schedule already confirmed: `다음 레슨 일정에 맞춰 시작합니다`
- Postpaid issue: `수강권은 준비됐고, 입금 확인은 나중에 진행됩니다`

Terms:

- User-facing student copy uses `준비`.
- Teacher action logs and internal domain events may use `발급`.
- Avoid `발행` in visible student copy.
- Avoid emoji in title text; use existing icon widgets instead.

## Component Direction

Create a student-specific timeline component instead of overloading the teacher-only sections.

Suggested files:

- `frontend/lib/features/student_home/domain/entities/student_lesson_progress_item.dart`
- `frontend/lib/features/student_home/presentation/providers/student_lesson_progress_provider.dart`
- `frontend/lib/features/student_home/presentation/widgets/student_lesson_progress_section.dart`
- `frontend/lib/features/student_home/presentation/widgets/student_lesson_progress_item_row.dart`

`StudentDashboardTab._StudentEventsGroup` should be replaced with `StudentLessonProgressSection`.

## Error And Empty States

No section should render if there are no active progress items.

Provider errors should hide the section for the first implementation, matching current home behavior. Later, a compact inline error can be added if backend failure observability is needed.

## Testing Strategy

Test the section as a home dashboard unit:

- action-required items render above waiting items
- subscription issued renders as `수강권이 준비됐어요`
- no visible `수강권이 발급되었습니다` or `수강권이 발행되었습니다` in student timeline
- empty item list hides the section
- narrow-width widget test catches RenderBox layout regressions

## Out Of Scope

- Backend data model changes
- Push notification delivery semantics
- Full subscription detail redesign
- Teacher home structural changes
