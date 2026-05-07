# 선생님 일괄 작업 스펙 (Bulk Teacher Actions)

> 상태: 📋 설계 완료 (v2 — 회차 매핑 + 챗 통합 + 수신 조건)
> Last updated: 2026-05-07
> 이전: enrollment_management_ux_spec.md §10에서 독립 승격
> 담당 화면: `students_tab.dart`, `bulk_cancel_screen.dart`, `bulk_message_sheet.dart`
> 관련:
> - [enrollment_management_ux_spec.md](./enrollment_management_ux_spec.md)
> - [subscription_schedule_change_ux_spec.md](../subscription/subscription_schedule_change_ux_spec.md)
> - [subscription_master.md](../subscription/subscription_master.md)

**⚠️ 이 문서는 선생님 일괄 작업(B1 휴강 공지 + B2 일괄 메시지)의 Single Source of Truth입니다.**

---

## 1. 개요

### 1.1 두 가지 유스케이스

| 기능 | 빈도 | 트리거 | 핵심 가치 |
|------|------|--------|----------|
| **B1. 휴강 공지** | 주 1회+ | "이번 금요일 개인 사정으로 휴강" | 해당 날짜 레슨 일괄 취소 + 학생별 알림 + **수강권 챗에 회차별 이력** |
| **B2. 일괄 메시지** | 월 1~2회 | "발표회 7월 12일 참가 여부" | 선택 학생에게 공지 알림 + **수강권 챗에 공지 기록** |

### 1.2 v1 → v2 변경 핵심

| 항목 | v1 (현재) | v2 (본 스펙) |
|------|----------|-------------|
| 회차 매핑 | 없음 (날짜 기반만) | **N회차 휴강** 표시 |
| 챗 이력 | 없음 (알림만) | **RequestEvent 생성** → 수강권 상세 챗에 표시 |
| 수신 조건 | 선택된 전원 | **활성 수강권 보유자** 기본 (전체 옵션도 제공) |
| 학생 액션 | 없음 | 휴강 알림에서 **보강 요청** CTA 제공 |
| 백엔드 API | 없음 (프론트 루프) | **전용 엔드포인트** 추가 |

---

## 2. B1 휴강 공지 — 상세 설계

### 2.1 선생님 UX 플로우

```
수강 관리 탭 Masthead [체크리스트 아이콘]
  ↓ 탭
선택 모드 ON → [전체 선택] / [선택 해제] + 개별 체크
  ↓
하단 액션바 [휴강 공지] 탭
  ↓
┌─── BulkCancelScreen ─────────────────┐
│                                       │
│  N명 선택됨                            │
│                                       │
│  [📅 기간 선택]  [+ 날짜 추가]          │
│  ※ 연속 범위(5/9~5/11) 또는            │
│    개별 날짜(5/9, 5/14) 복수 선택      │
│                                       │
│  선택된 날짜:                          │
│  [5/9 ×] [5/10 ×] [5/11 ×]           │
│                                       │
│  사유 (선택):                          │
│  [개인 사정으로 휴강합니다.     ]        │
│  ────────────────────────────────     │
│                                       │
│  ♪ 영향 받는 레슨                      │
│  ──────────────────────               │
│  i.  김민지 · 3회차 · 14:00            │
│  ii. 박지수 · 5회차 · 15:30            │
│  iii.이서연 · 2회차 · 17:00            │
│                                       │
│  ※ 해당 날짜 레슨 없음: 1명 (최영호)   │
│  ※ 수강권 미발급: 1명 (정하은) — 제외   │
│                                       │
│  [3건 휴강 공지 발송]                   │
└───────────────────────────────────────┘
  ↓ 버튼 탭
┌─── 확인 다이얼로그 ──────────────────┐
│  휴강 공지 발송                       │
│                                       │
│  2026.05.09                           │
│  3건의 레슨이 취소되고,                │
│  3명에게 알림이 발송됩니다.            │
│                                       │
│  ※ 변경권은 차감되지 않습니다.         │
│  ※ 학생은 보강 일정을 요청할 수 있습니다.│
│                                       │
│       [취소]    [발송]                 │
└───────────────────────────────────────┘
  ↓ 발송
SnackBar: "3건 취소 · 3명에게 알림 발송"
```

### 2.2 프리뷰 — 회차 매핑 규칙

| 정보 | 소스 | 표시 |
|------|------|------|
| 학생 이름 | `Lesson.studentName` | "김민지" |
| 회차 번호 | `Lesson.sessionNumber` (수강권 기준 N회차) | "3회차" |
| 시간 | `Lesson.startTime` | "14:00" |
| 수강권 상태 | 학생의 활성 수강권 여부 | 미발급 시 프리뷰에서 **제외** 안내 |

**회차 매핑 로직:**
```dart
// Lesson 엔티티에 sessionNumber 필드 존재
// 수강권 발급 시 레슨에 sessionNumber가 할당됨
// 예: 8회권의 3번째 레슨 → sessionNumber = 3

final displayText = lesson.sessionNumber != null
    ? '${lesson.studentName} · ${lesson.sessionNumber}회차 · ${lesson.startTime}'
    : '${lesson.studentName} · ${lesson.startTime}';
```

### 2.3 대상 필터링 규칙

| 조건 | 포함/제외 | 이유 |
|------|----------|------|
| 해당 날짜 `scheduled` 레슨 있음 | **포함** | 취소 대상 |
| 해당 날짜 `reschedulePending` 레슨 있음 | **포함** | 보강 대기 중이라도 취소 대상 |
| 해당 날짜 레슨 없음 | **제외** (skipped) | "해당 날짜 레슨 없음: N명" 안내 |
| 활성 수강권 없음 (만료/미발급) | **제외** | "수강권 미발급: N명 — 제외" 안내 |
| 이미 취소된 레슨 | **제외** | 중복 취소 방지 |

> **핵심 원칙: 수업일에 레슨이 있는 학생만 취소된다.**
> 선택된 5명 중 해당 날짜에 레슨이 있는 3명만 취소 대상.
> 나머지 2명은 "해당 날짜 레슨 없음"으로 skipped.
> 수강권이 없는 학생도 자동 제외.

### 2.3.1 필터링 데이터 흐름

```
입력: studentIds [김민지, 박지수, 이서연, 최영호, 정하은] (5명)
      targetDate: 2026-05-09 (금)

Step 1. getLessonsByDate(5/9)
   → [L1(김민지, 14:00), L2(박지수, 15:30), L3(이서연, 17:00)]
   ※ 최영호: 금요일에 레슨 없음 (화/목 수강)
   ※ 정하은: 수강권 미발급 (체험 대기 중)

Step 2. _isCancellable(status) 필터
   → L1(scheduled ✓), L2(scheduled ✓), L3(reschedulePending ✓)

Step 3. 활성 수강권 필터 (_filterActiveSubscriptionStudents)
   → [김민지 ✓, 박지수 ✓, 이서연 ✓]
   ※ 정하은: 수강권 없음 → 제외

Step 4. studentIds 교차
   → lessonsByStudent: {김민지: L1, 박지수: L2, 이서연: L3}
   → skipped: [최영호(레슨 없음), 정하은(수강권 없음)]

출력: BulkCancelResult(
  cancelledLessonCount: 3,
  notifiedStudentCount: 3,
  skippedStudentIds: [최영호, 정하은],
)
```

### 2.3.2 DB/API 호출 순서

```
[BulkTeacherActionService.cancelLessonsOnDate()]
  │
  ├─ 1. LessonRepository.getLessonsByDate(targetDate)
  │     → DB: SELECT * FROM lessons WHERE date = '2026-05-09'
  │
  ├─ 2. SubscriptionRepository.getByStudentId(each)
  │     → DB: SELECT * FROM subscriptions WHERE student_id = ?
  │     → 활성(active/expiringSoon) 수강권 존재 여부 확인
  │
  ├─ 3. LessonRepository.updateLesson(cancelledByTeacher)
  │     → DB: UPDATE lessons SET status = 'cancelledByTeacher' WHERE id = ?
  │     ※ isDeducted = false (수강권 차감 없음)
  │     ※ allowsReschedule = true (보강 요청 가능)
  │
  ├─ 4. UnifiedLessonRequestRepository.addEvent(RequestEvent)
  │     → DB: INSERT INTO request_events (type='lessonCancelledByTeacher', ...)
  │     ※ sessionNumber, changeCreditUsed=0, keepsSessionNumber=true
  │
  └─ 5. NotificationService.showNotification(high priority)
        → DB: INSERT INTO notifications (type='lessonCancelled', ...)
        → FCM: 푸시 알림 발송
```

### 2.4 실행 — 이벤트 생성 규칙

휴강 확정 시 **3가지 산출물** 생성:

#### (A) 레슨 상태 변경
```dart
lesson.copyWith(
  status: LessonStatus.cancelledByTeacher,
  updatedAt: DateTime.now(),
)
```
- `isDeducted = false` (수강권 차감 없음)
- `allowsReschedule = true` (학생 보강 요청 가능)

#### (B) RequestEvent 생성 (챗 이력)
```dart
RequestEvent(
  requestId: subscription.requestId,   // 해당 수강권의 레슨 요청 ID
  actorType: 'teacher',
  actorId: teacherId,
  eventType: RequestEventType.lessonCancelledByTeacher,  // NEW
  subscriptionId: subscription.id,
  sessionNumber: lesson.sessionNumber,
  message: reason,                      // 선생님 입력 사유
  changeCreditUsed: 0,                  // 변경권 미차감
  changeCreditRemainingAfter: subscription.remainingChangeCredits,
  keepsSessionNumber: true,             // 회차 번호 유지
  createdAt: DateTime.now(),
)
```

#### (C) Notification 생성 (알림)
```dart
AppNotification(
  userId: studentId,
  type: NotificationType.lessonCancelled,
  priority: NotificationPriority.high,   // DND 무시
  title: '휴강 안내',
  body: '${sessionNumber}회차 ${formatDate(date)} ${startTime} 레슨이 휴강 처리되었습니다',
  data: {
    'teacherId': teacherId,
    'lessonId': lesson.id,
    'subscriptionId': subscription.id,
    'sessionNumber': sessionNumber,
    'source': 'bulk_teacher_action',
    'actionUrl': '/subscriptions/${subscription.id}',  // 수강권 상세로 딥링크
    'actionLabel': '보강 요청',
  },
)
```

### 2.4.1 선생님 ↔ 학생 전체 프로세스 (End-to-End)

```
[선생님]                    [시스템]                    [학생]
   │                         │                          │
   ├─ 수강관리 > 학생 선택    │                          │
   ├─ 날짜 선택 (5/9)        │                          │
   ├─ 사유 입력              │                          │
   ├─ [확정]                 │                          │
   │                         │                          │
   │    ─── 확정 시점 ────   │                          │
   │                         │                          │
   │                    ┌─── ▼ ────────────────────┐    │
   │                    │ 1. 레슨 상태 변경         │    │
   │                    │    cancelledByTeacher     │    │
   │                    │    isDeducted=false       │    │
   │                    │    allowsReschedule=true  │    │
   │                    │                          │    │
   │                    │ 2. RequestEvent 생성      │    │
   │                    │    lessonCancelledByTeacher│   │
   │                    │    sessionNumber=3        │    │
   │                    │    changeCreditUsed=0     │    │
   │                    │    keepsSessionNumber=T   │    │
   │                    │                          │    │
   │                    │ 3. Notification 생성      │    │
   │                    │    lessonCancelled, high  │    │
   │                    │    + FCM 푸시 발송        │    │
   │                    └──────────────────────────┘    │
   │                         │                          │
   │                         ├── 푸시 알림 ────────────→│
   │                         │   "3회차 휴강 안내"       │
   │                         │                          │
   │                         │            [학생 앱 진입]  │
   │                         │                          │
   │                         │   ① 알림 리스트에 표시 ──→│
   │                         │   ② 수강권 상세 챗:       │
   │                         │      상단 배너 (기간 중)  │
   │                         │      + 챗 이벤트 (영구)   │
   │                         │   ③ 스케줄 탭: "휴강"     │
   │                         │                          │
   │                         │            [보강 요청]     │
   │                         │                          │
   │                         │   ←── 보강 일정 요청 ────│
   │                         │   scheduleChanged        │
   │                         │   changeCreditUsed=0     │
   │                         │   (선생님 사유→미차감)    │
   │                         │                          │
   │ ← 보강 요청 알림 ───────│                          │
   │   "3회차 보강 요청"      │                          │
   │                         │                          │
   ├─ 시간대 3개 제안 ──────→│                          │
   │   scheduleChangeProposed│                          │
   │                         │── 제안 알림 ────────────→│
   │                         │                          │
   │                         │   ←── 수락 ─────────────│
   │                         │   scheduleChangeAccepted │
   │                         │   sessionNumber=3 유지    │
   │                         │                          │
   │ ← 수락 알림 ────────────│                          │
   │   "3회차 보강 확정"      │                          │
   │                         │                          │
```

### 2.4.2 선생님이 얻는 어드벤티지

| 어드벤티지 | 설명 |
|-----------|------|
| **일괄 처리** | N명 학생을 한번에 휴강 처리 (개별 취소 N회 대비 1회 작업) |
| **프리뷰 확인** | 영향받는 레슨을 미리 보고 확인 (오취소 방지) |
| **자동 알림** | 학생별 푸시+인앱 알림 자동 발송 (개별 연락 불필요) |
| **이력 보존** | 챗에 "선생님 사유 휴강" 기록 → 나중에 분쟁 시 증거 |
| **보강 유도** | 학생에게 보강 CTA 자동 제공 → 레슨 누락 방지 |
| **변경권 보호** | 선생님 사유이므로 학생 변경권 미차감 → 학생 불만 최소화 |

### 2.4.3 학생이 받는 보호

| 보호 | 설명 |
|------|------|
| **수강권 차감 없음** | `isDeducted=false` — 유료 레슨 횟수 손실 없음 |
| **변경권 차감 없음** | `changeCreditUsed=0` — 학생 귀책 아니므로 변경권 소모 없음 |
| **회차 번호 유지** | `keepsSessionNumber=true` — 3회차가 취소되면 다음 보강도 3회차 |
| **보강 요청 가능** | `allowsReschedule=true` — 학생이 원하면 보강 일정 요청 CTA 제공 |
| **사유 확인** | 챗 이벤트에 선생님 사유가 기록되어 투명한 이력 |
| **High priority 알림** | DND 무시 → 즉시 인지 가능 |

### 2.5 학생 수신 — 4가지 터치포인트

#### (1) 푸시 알림
```
┌─────────────────────────────┐
│ 🔔 휴강 안내                  │
│ 3회차 5/9(금) 14:00 레슨이    │
│ 휴강 처리되었습니다            │
│            [보강 요청]         │
└─────────────────────────────┘
```

#### (2) 알림 리스트 (notification_list_screen.dart)
```
┌─────────────────────────────────┐
│ [■ event_busy]  휴강 안내        │
│ 3회차 5/9(금) 14:00 레슨이       │
│ 휴강 처리되었습니다               │
│ 사유: 개인 사정으로 휴강합니다     │
│                     14:30  [보강 요청] │
└─────────────────────────────────┘
```
- 아이콘: `Icons.event_busy` (paperAccent 배경)
- 액션 라벨: "보강 요청" → 수강권 상세로 이동

#### (3) 수강권 상세 챗 (request_history_chat.dart)

```
┌─── 선생님 버블 (우측) ──────────────┐
│                                     │
│  ♪ 3회차 휴강                        │
│  ──────────────────                 │
│  5월 9일(금) 14:00 레슨이            │
│  휴강 처리되었습니다.                 │
│                                     │
│  사유: 개인 사정으로 휴강합니다        │
│                                     │
│  ※ 변경권 차감 없음 (잔여 2회)        │
│  ※ 회차 번호 유지 (다음 레슨도 3회차)  │
│                                     │
│  → 보강 일정을 요청할 수 있어요       │
│                                     │
│                      5/7 14:30      │
└─────────────────────────────────────┘
```

**Notebook × Score 디자인:**
- 선생님 발신 → **우측 버블** (viewer가 학생이면 좌측에 선생님 아바타)
- 제목: `NotebookTypography.pieceTitle` + 악보 음표 (♪)
- 구분선: `ThinRule`
- 본문: `AppTypography.bodySmall` + `inkSecondary`
- 메타 (변경권/회차): `AppTypography.captionSmall` + `inkTertiary`
- CTA: "보강 일정을 요청할 수 있어요" → `AppColors.paperAccent` 밑줄 링크

#### (4) 스케줄 탭 — 해당 날짜 레슨 표시
- 레슨 카드에 `cancelledByTeacher` 상태 → "휴강" 라벨 (기존 렌더링 재사용)
- 색상: `AppColors.inkTertiary` (grey-out)

---

## 3. B2 일괄 메시지 — 상세 설계

### 3.1 수신 대상 — 활성 수강권 학생 고정

> **원칙**: 선생님이 일괄 메시지를 보내는 주요 목적은 스케줄 조정/공지이므로,
> **활성 수강권이 있는 학생에게만** 전송한다. 만료/미시작 학생에게 보내면 "나는 이미 그만뒀는데" 혼란 유발.
> 별도 필터 UI 없이, 안내 문구로 대상을 명시한다.

```
┌─── BulkMessageSheet ─────────────────┐
│                                       │
│  ♪ 일괄 메시지 보내기                  │
│  ──────────────────                   │
│  N명에게 알림으로 전송됩니다            │
│                                       │
│  ┌────────────────────────────────┐   │
│  │ ℹ 활성 수강권이 있는 학생에게만  │   │
│  │   전송됩니다                    │   │
│  └────────────────────────────────┘   │
│                                       │
│  제목: [발표회 참가 확인           ]    │
│                                       │
│  내용:                                 │
│  [7월 12일 발표회 참가 여부를    ]      │
│  [알려주세요. 참가비는 없습니다.  ]      │
│  [                              ]      │
│                                       │
│  [메시지 보내기]                        │
└───────────────────────────────────────┘
```

**수신 조건:** `SubscriptionStatus.active | expiringSoon` 보유자만 (서비스 레이어에서 자동 필터)

### 3.2 챗 이벤트 생성

일괄 메시지도 수강권 상세 챗에 기록:

```dart
RequestEvent(
  requestId: subscription.requestId,
  actorType: 'teacher',
  actorId: teacherId,
  eventType: RequestEventType.teacherAnnouncement,  // NEW
  subscriptionId: subscription.id,
  message: '$title\n$body',        // 제목+본문 합쳐서 저장
  createdAt: DateTime.now(),
)
```

**챗 버블 렌더링:**

```
┌─── 선생님 버블 (우측) ──────────────┐
│                                     │
│  📋 공지                             │
│  ──────────────────                 │
│  발표회 참가 확인                     │
│                                     │
│  7월 12일 발표회 참가 여부를          │
│  알려주세요. 참가비는 없습니다.        │
│                                     │
│                      5/7 10:00      │
└─────────────────────────────────────┘
```

- 아이콘: 📋 (클립보드) — `NotebookGlyph` 사용 또는 `Icons.campaign`
- 제목: bold, `AppTypography.bodyMedium.w600`
- 본문: `AppTypography.bodySmall` + `inkSecondary`

### 3.3 활성 수강권 학생에게만 보내는 경우 — 이벤트 연결

활성 수강권이 있는 학생: 해당 수강권의 `requestId`에 `RequestEvent` 생성
→ 수강권 상세 챗에서 공지 확인 가능

활성 수강권이 없는 학생 (전체 모드): `RequestEvent` 생성 안 함
→ 알림 리스트에서만 확인

---

## 4. 시간변경 상세 페이지 — 이중 표시 (배너 + 챗)

### 4.1 설계 결정

> **Q: 휴강은 대화(챗 이벤트)인가, 공지(시스템 배너)인가?**
> **A: 둘 다** — 상단 배너로 즉시 인지 + 챗 타임라인으로 이력 보존.

| 역할 | 상단 배너 | 챗 이벤트 |
|------|----------|----------|
| **즉시 인지** | 화면 진입 시 바로 보임 | 스크롤 필요 |
| **행동 유도** | 보강 CTA 최상단 | 타임라인에 묻힘 |
| **이력 보존** | 기간 지나면 사라짐 | 영구 기록 |
| **유사 사례** | Slack 채널 토픽, 카카오톡 공지 | 카카오톡 톡게시판 |

### 4.1.1 상단 휴강 배너 (신규)

수강권 상세 챗 최상단에 표시되는 공지형 배너. 해당 기간에만 노출.

```
┌─── 수강권 상세 ─────────────────────────┐
│                                          │
│  ┌─── 휴강 배너 (paperDark 배경) ─────┐  │
│  │ ⚠ 5/9~5/11 휴강                   │  │
│  │ 사유: 선생님 개인 사정              │  │
│  │ ※ 변경권 차감 없음                 │  │
│  │ [보강 일정 요청하기]               │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ── 챗 타임라인 ──                        │
│  ...                                     │
└──────────────────────────────────────────┘
```

**표시 조건:**
- 해당 수강권에 `lessonCancelledByTeacher` 이벤트가 존재
- 휴강 날짜 중 **1개 이상이 오늘 이후** (미래 휴강이 남아있음)
- 모든 휴강 날짜가 지나면 **자동 숨김**
- 보강 일정이 모두 확정되면 **자동 숨김**

**Notebook × Score 디자인:**
- 배경: `AppColors.paperDark`
- 테두리: `AppColors.inkQuaternary` (1px)
- 아이콘: `Icons.event_busy` (18px, `AppColors.ink`)
- 날짜: `AppTypography.bodyMedium.w600`
- 사유: `AppTypography.bodySmall` + `inkSecondary`
- CTA: `FilledButton` "보강 일정 요청하기" (compact, `paperAccent`)

### 4.2 챗 타임라인 예시

```
── 수강권 상세 (바이올린 8회권) ──

[수강권 발급]  4/1                    시스템
  8회 수강권이 발급되었습니다.

[1회차 완료]  4/5                     시스템
  4/5(토) 14:00 레슨 완료

[2회차 완료]  4/12                    시스템
  4/12(토) 14:00 레슨 완료

[3회차 휴강]  5/9                     선생님 ←── NEW
  ♪ 3회차 휴강
  5/9(금) 14:00 레슨이 휴강 처리되었습니다.
  사유: 개인 사정으로 휴강합니다
  ※ 변경권 차감 없음 (잔여 2회)
  ※ 회차 번호 유지

[보강 요청]  5/10                     학생
  3회차 보강 일정을 요청합니다.
  희망: 5/16(금) 14:00 ...

[공지]  5/12                          선생님 ←── NEW
  📋 발표회 참가 확인
  7월 12일 발표회 참가 여부를 알려주세요.
```

### 4.3 이벤트 타입별 버블 스타일

| 이벤트 타입 | 아이콘 | 배경 | 액터 | CTA |
|------------|--------|------|------|-----|
| `lessonCancelledByTeacher` | ♪ (NotebookGlyph) | `paperDark` | 선생님 (우측) | "보강 일정을 요청할 수 있어요" |
| `teacherAnnouncement` | 📋 (NotebookGlyph) | `paper` | 선생님 (우측) | 없음 |
| `lessonCancelled` (학생) | — | `paper` | 학생 (좌측) | — (기존 유지) |

---

## 5. 백엔드 API 계약

### 5.1 일괄 취소 엔드포인트 (신규)

```
POST /api/v1/lessons/bulk-cancel
```

**Request:**
```json
{
  "teacher_id": "uuid",
  "student_ids": ["uuid1", "uuid2", "uuid3"],
  "target_date": "2026-05-09",
  "reason": "개인 사정으로 휴강합니다",
  "notification_title": "휴강 안내"
}
```

**처리 로직:**
1. `target_date`에 `scheduled` / `reschedulePending` 상태 레슨 조회
2. `student_ids`에 해당하는 레슨만 필터
3. 활성 수강권 없는 학생 제외 (skipped)
4. 각 레슨: `status → cancelledByTeacher`
5. 각 학생: `RequestEvent(lessonCancelledByTeacher)` 생성
6. 각 학생: `Notification(lessonCancelled, high)` 생성
7. FCM 푸시 발송

**Response:**
```json
{
  "cancelled_lesson_count": 3,
  "notified_student_count": 3,
  "skipped_student_ids": ["uuid4"],
  "events_created": [
    {
      "student_id": "uuid1",
      "lesson_id": "lesson_uuid",
      "session_number": 3,
      "subscription_id": "sub_uuid"
    }
  ]
}
```

### 5.2 일괄 메시지 엔드포인트 (신규)

```
POST /api/v1/notifications/broadcast
```

**Request:**
```json
{
  "teacher_id": "uuid",
  "student_ids": ["uuid1", "uuid2"],
  "target_filter": "active_subscription",
  "title": "발표회 참가 확인",
  "body": "7월 12일 발표회 참가 여부를 알려주세요."
}
```

**처리 로직:**
1. `target_filter == "active_subscription"` → 활성 수강권 보유자만 필터
2. `target_filter == "all"` → 전원
3. 활성 수강권 보유 학생: `RequestEvent(teacherAnnouncement)` + `Notification` 생성
4. 수강권 없는 학생 (전체 모드): `Notification`만 생성
5. FCM 푸시 발송

**Response:**
```json
{
  "sent_count": 3,
  "event_created_count": 2,
  "filtered_out_count": 1
}
```

### 5.3 RequestEventType 확장 (백엔드)

```python
# backend/app/models/request_event.py
class RequestEventType(str, Enum):
    # ... 기존 29개 ...

    # Phase 3 — 선생님 일괄 작업 (v2)
    lesson_cancelled_by_teacher = "lessonCancelledByTeacher"  # NEW
    teacher_announcement = "teacherAnnouncement"              # NEW
```

---

## 6. 데이터 모델

### 6.1 RequestEventType 확장 (프론트엔드)

```dart
enum RequestEventType {
  // ... 기존 ...

  /// 선생님 사유 레슨 휴강 (일괄 또는 개별)
  /// sessionNumber + message(사유) + changeCreditUsed(0) 포함
  lessonCancelledByTeacher,

  /// 선생님 공지 메시지
  /// message(제목\n본문) 포함
  teacherAnnouncement,
}
```

### 6.2 BulkCancelResult 확장

```dart
class BulkCancelResult {
  final int cancelledLessonCount;
  final int notifiedStudentCount;
  final List<String> skippedStudentIds;
  final List<BulkCancelEventInfo> eventsCreated;  // NEW

  bool get hasSkipped => skippedStudentIds.isNotEmpty;
}

class BulkCancelEventInfo {
  final String studentId;
  final String lessonId;
  final int? sessionNumber;
  final String? subscriptionId;
}
```

---

## 7. 챗 버블 렌더링 — Notebook × Score 디자인

### 7.1 lessonCancelledByTeacher 버블

```dart
Widget _buildTeacherCancelBubble(RequestEvent event) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 헤더: "♪ N회차 휴강"
      Row(
        children: [
          NotebookGlyph(NotebookGlyph.note, size: 14, color: AppColors.ink),
          SizedBox(width: AppSpacing.space1),
          Text(
            '${event.sessionNumber}회차 휴강',
            style: NotebookTypography.pieceTitle.copyWith(fontSize: 14),
          ),
        ],
      ),
      ThinRule(),
      SizedBox(height: AppSpacing.space2),

      // 본문: 날짜+시간+상태
      Text(
        '${formatDate(event)} 레슨이 휴강 처리되었습니다.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary),
      ),

      // 사유 (있으면)
      if (event.message != null) ...[
        SizedBox(height: AppSpacing.space2),
        Text(
          '사유: ${event.message}',
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary),
        ),
      ],

      // 메타: 변경권 + 회차
      SizedBox(height: AppSpacing.space2),
      Text(
        '※ 변경권 차감 없음 (잔여 ${event.changeCreditRemainingAfter}회)',
        style: AppTypography.captionSmall.copyWith(color: AppColors.inkTertiary),
      ),
      Text(
        '※ 회차 번호 유지',
        style: AppTypography.captionSmall.copyWith(color: AppColors.inkTertiary),
      ),

      // CTA: 보강 요청
      SizedBox(height: AppSpacing.space3),
      Text(
        '→ 보강 일정을 요청할 수 있어요',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.paperAccent,
          decoration: TextDecoration.underline,
        ),
      ),
    ],
  );
}
```

### 7.2 teacherAnnouncement 버블

```dart
Widget _buildTeacherAnnouncementBubble(RequestEvent event) {
  final parts = (event.message ?? '').split('\n');
  final title = parts.isNotEmpty ? parts.first : '';
  final body = parts.length > 1 ? parts.sublist(1).join('\n') : '';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 헤더: "📋 공지"
      Row(
        children: [
          Icon(Icons.campaign, size: 14, color: AppColors.ink),
          SizedBox(width: AppSpacing.space1),
          Text('공지', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
      ThinRule(),
      SizedBox(height: AppSpacing.space2),

      // 제목
      Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      if (body.isNotEmpty) ...[
        SizedBox(height: AppSpacing.space1),
        Text(body, style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary)),
      ],
    ],
  );
}
```

---

## 8. UX 감정 분석

| 시점 | 선생님 감정 | 학생 감정 |
|------|-----------|----------|
| 휴강 공지 작성 | **약간 불안** → 프리뷰로 **안심** (영향 범위 확인) | — |
| 확인 다이얼로그 | **통제감** (2단계 확인 + 변경권 미차감 안내) | — |
| 발송 완료 | **성취감** (SnackBar로 결과 확인) | — |
| 푸시 알림 수신 | — | **놀람** → 즉시 확인 (high priority) |
| 챗에서 확인 | — | **안심** (사유 확인 + 보강 가능 안내) |
| 보강 요청 | — | **행동 유도** (CTA로 자연스럽게 보강 요청) |
| 일괄 메시지 수신 | — | **정보 확인** (별도 행동 불필요) |

---

## 9. Lore 결정

- **Lore-directive**: 휴강 공지는 반드시 `RequestEvent(lessonCancelledByTeacher)` 생성 → 수강권 챗에 이력 보존. 알림만으로는 이력이 유실됨.
- **Lore-directive**: 일괄 메시지 기본 수신 대상은 활성 수강권 학생만. 만료 학생에게 공지하면 "나는 이미 그만뒀는데" 혼란.
- **Lore-constraint**: 휴강 시 변경권 미차감 + 회차 번호 유지. 선생님 사유 취소이므로 학생에게 불이익 없음.
- **Lore-constraint**: 프리뷰 → 확인 2단계 필수. 1탭 실행은 대량 오조작 위험.
- **Lore-rejected**: 휴강을 별도 "휴강 관리" 화면으로 분리 — 수강관리 탭의 선택 모드에서 자연스럽게 접근하는 현재 플로우가 더 효율적.
- **Lore-rejected**: 일괄 메시지에 "답장" 기능 추가 — 답장은 1:1 대화의 영역. 공지는 단방향.
- **Lore-rejected**: 일괄 메시지 수신 대상 필터 UI (활성/전체 선택) — 선생님의 주 용도가 스케줄 조정 공지이므로 활성 수강권 학생만 고정. 불필요한 선택지는 UX 복잡도만 증가.
- **Lore-directive**: 휴강 날짜는 복수 선택 지원 — 기간 선택(DateRangePicker) + 개별 날짜 추가. 연속 휴강(여행/명절)과 비연속 휴강(개인 사정) 모두 커버.

---

## 10. 구현 Phase 분해

| Phase | 내용 | 의존성 |
|-------|------|--------|
| **A. 모델 확장** | `RequestEventType` 2개 추가 (FE + BE) | 없음 |
| **B. 서비스 수정** | `BulkTeacherActionService`에 이벤트 생성 로직 추가 | A |
| **C. 프리뷰 개선** | `BulkCancelScreen` 프리뷰에 회차 표시 + 수강권 미발급 학생 제외 | A |
| **D. 메시지 필터** | `BulkMessageSheet`에 수신 조건 선택 UI 추가 | A |
| **E. 챗 버블** | `schedule_change_event_bubble.dart`에 2개 버블 타입 추가 | A |
| **F. 백엔드 API** | `POST /lessons/bulk-cancel` + `POST /notifications/broadcast` | A |
| **G. 테스트** | 서비스 + 위젯 + 시나리오 테스트 | B~F |

---

## 11. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-05-07 | v2.3 — 프로세스 상세: 필터링 데이터 흐름, DB/API 호출 순서, E2E 플로우, 어드벤티지/보호 매트릭스. 수강권 미발급 학생 자동 제외 구현 |
| 2026-05-07 | v2.2 — 휴강 이중 표시: 상단 배너(기간 한정) + 챗 이벤트(영구). 배너 자동 숨김 조건 명시 |
| 2026-05-07 | v2.1 — 전체 선택 기능, 복수 날짜 선택(기간/개별), 일괄 메시지 필터 UI 제거(활성 고정+안내 텍스트) |
| 2026-05-07 | v2 독립 스펙 작성 — 회차 매핑 + 챗 이벤트 통합 + 수신 조건 필터 + 백엔드 API + Notebook × Score 버블 디자인 |
| 2026-04-24 | v1 enrollment_management_ux_spec.md §10으로 초기 설계 |
