# 알림 시스템 Master Spec

> 구현 상태: ⚠️ 부분 구현 (90%) — FCM 푸시 미구현
> Last updated: 2026-03-07
> 기존 스펙: [notification_system.md](notification_system.md)

## 1. 개요

레슨 앱의 알림 시스템. 레슨, 연습, 결제, 관계, 수강권 등 앱 전반의 이벤트를 사용자에게 전달한다.

도서관의 게시판(인앱)과 문자(푸시)를 함께 운영하는 것과 같다. 중요한 소식은 문자로 즉시 보내고, 모든 소식은 게시판에 기록한다.

### 설계 원칙

1. **개인화** - 사용자별 최적 타이밍과 빈도
2. **피로도 관리** - 과도한 알림 방지 (일일 최대 제한), 반응 없으면 빈도 감소
3. **채널 보호** - 푸시 옵트아웃 방지를 위한 품질 관리
4. **선택권 제공** - 선생님/학생 모두 세밀한 설정 가능
5. **DND 우회** - 긴급 알림(레슨 시작, 취소, 노쇼)은 방해금지 무시

### 기존 스펙 대비 변경점

| 항목 | 기존 스펙 | 구현 현실 |
|------|----------|----------|
| 알림 유형 | 7개 카테고리 | 11개 카테고리 (스케줄 변경, 수강권 제안, 변경 허용 추가) |
| 서비스 구조 | 단일 NotificationService | 역할별 분리 (Connection, Proposal, Scheduler) |
| 설정 엔티티 | 개념 수준 | 학생/선생님 분리 구현 완료 |
| 알림 템플릿 | 미정의 | NotificationTemplate 클래스 구현 |
| Repository | Mock only | Mock + Remote 구현 |

---

## 2. 핵심 기능

### 2.1 알림 유형 (NotificationType) - 전체 목록

#### 레슨 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `lessonBooked` | normal | X | O |
| `lessonReminder` | normal | X | O |
| `lessonCancelled` | high | **O** | O |
| `lessonRescheduled` | high | **O** | O |
| `lessonStarting` | **urgent** | **O** | O |
| `lessonCompleted` | low | X | **X** |
| `lessonNoteShared` | normal | X | O |

#### 연습 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `practiceReminder` | normal | X | O |
| `streakWarning` | normal | X | O |
| `streakMilestone` | low | X | O |
| `practiceAssigned` | normal | X | O |
| `weeklyGoalAchieved` | low | X | O |

#### 결제 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `paymentRequested` | high | X | O |
| `paymentReminder` | high | X | O |
| `paymentReceived` | normal | X | O |
| `paymentConfirmed` | normal | X | O |
| `lessonsRunningLow` | normal | X | O |

#### 노쇼/취소 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `noshowWarning` | **urgent** | **O** | O |
| `noshowConfirmed` | **urgent** | **O** | O |
| `teacherNoshow` | normal | X | O |
| `compensationApplied` | normal | X | O |
| `cancellationDeadline` | high | X | O |

#### 관리 알림 (선생님용)

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `newStudentRegistered` | normal | X | O |
| `trialBookingRequest` | normal | X | O |
| `studentPracticeReport` | low | X | **X** |
| `reviewReceived` | normal | X | O |

#### 연결/초대 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `connectionRequestReceived` | high | X | O |
| `connectionRequestAccepted` | high | X | O |
| `connectionRequestRejected` | low | X | O |
| `connectionEstablished` | high | X | O |
| `connectionDisconnected` | low | X | O |

#### 보강 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `makeupLessonCreated` | normal | X | O |
| `makeupLessonExpiring` | high | X | O |
| `makeupLessonExpired` | low | X | O |

#### 스케줄 변경 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `scheduleChangeRequested` | high | X | O |
| `scheduleChangeApproved` | high | X | O |
| `scheduleChangeRejected` | normal | X | O |
| `scheduleChangeAlternative` | normal | X | O |

#### 수강권 제안 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `proposalReceived` | high | X | O |
| `proposalReminder24h` | normal | X | O |
| `proposalReminder48h` | normal | X | O |
| `proposalReminder72h` | high | X | O |
| `proposalAccepted` | normal | X | O |
| `proposalExpired` | normal | X | O |

#### 수강권 만료 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `subscriptionExpiringSoon` | high | X | O |
| `subscriptionExpired` | high | X | O |

#### 변경 허용 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `rescheduleAllowanceUsed` | normal | X | O |
| `rescheduleAllowanceDepleted` | normal | X | O |

### 2.2 알림 유형 상세 (Claude 구현 가이드)

아래 표는 주요 알림 유형별 트리거 조건, 제목, 본문 예시, 아이콘, 딥링크를 정리한 것이다. Claude가 알림 생성 로직을 구현할 때 이 표를 참조한다.

| 유형 | 트리거 | 제목 | 본문 예시 | 아이콘 | 딥링크 |
|------|--------|------|----------|--------|--------|
| `lessonReminder` | 레슨 30분 전 | 레슨 알림 | "김민수 바이올린 14:00" | calendar | `/lessons/{id}` |
| `lessonStarting` | 레슨 시작 시점 | 레슨 시작 | "김민수 바이올린 레슨이 시작됩니다" | alarm | `/lessons/{id}` |
| `lessonCancelled` | 레슨 취소 시 | 레슨 취소 | "김민수 3/7 14:00 레슨이 취소되었습니다" | cancel | `/lessons/{id}` |
| `lessonCompleted` | 레슨 종료 시 | 레슨 완료 | "김민수 바이올린 레슨이 완료되었습니다" | check_circle | `/lessons/{id}` |
| `lessonNoteShared` | 선생님 레슨 노트 작성 시 | 레슨 노트 | "선생님이 레슨 노트를 공유했습니다" | note | `/lessons/{id}/note` |
| `lessonsRunningLow` | 수강권 잔여 횟수 ≤ 2 | 수강권 임박 | "김민수 수강권 1회 남음" | warning | `/subscriptions/{id}` |
| `paymentRequested` | 수강권 발급 후 미입금 | 결제 요청 | "김민수 수강권 결제를 확인해주세요" | payment | `/subscriptions/{id}` |
| `paymentReminder` | 발급 후 3일 미입금 | 미수금 알림 | "김민수 수강권 미결제" | payment | `/subscriptions/{id}` |
| `paymentReceived` | 입금 확인 시 | 입금 확인 | "김민수 수강권 결제가 확인되었습니다" | payment | `/subscriptions/{id}` |
| `streakMilestone` | 연속 N일 달성 | 연습 축하 | "7일 연속 연습!" | celebration | `/practice/stats` |
| `streakWarning` | 연속 기록 위기 (당일 미연습) | 스트릭 경고 | "연속 연습 기록이 끊어질 수 있어요" | warning | `/practice` |
| `practiceReminder` | 설정된 연습 리마인더 시간 | 연습 알림 | "오늘의 연습 목표를 달성해보세요" | music_note | `/practice` |
| `practiceAssigned` | 선생님 과제 등록 시 | 과제 등록 | "선생님이 새 연습 과제를 등록했습니다" | task | `/practice/assignments` |
| `trialBookingRequest` | 학생 체험 요청 시 | 레슨 요청 | "새 체험 요청이 있습니다" | person_add | `/schedule/lesson-requests` |
| `noshowWarning` | 레슨 시작 10분 경과, 미도착 | 노쇼 경고 | "김민수 레슨에 출석하지 않았습니다" | warning | `/lessons/{id}` |
| `noshowConfirmed` | 노쇼 확정 시 | 노쇼 확정 | "김민수 레슨이 노쇼 처리되었습니다" | error | `/lessons/{id}` |
| `connectionRequestReceived` | 연결 요청 수신 시 | 연결 요청 | "김민수님이 연결을 요청했습니다" | person | `/profile/connections` |
| `connectionEstablished` | 연결 수락 시 | 연결 완료 | "김선생님과 연결되었습니다" | check | `/profile/connections` |
| `proposalReceived` | 수강권 제안 수신 시 | 수강권 제안 | "김선생님이 수강권을 제안했습니다" | ticket | `/subscriptions/{id}` |
| `proposalExpired` | 수강권 제안 72시간 경과 | 제안 만료 | "수강권 제안이 만료되었습니다" | timer_off | `/subscriptions` |
| `makeupLessonCreated` | 보강 레슨 생성 시 | 보강 레슨 | "보강 레슨이 등록되었습니다" | event | `/lessons/{id}` |
| `makeupLessonExpiring` | 보강 유효기간 D-3 | 보강 임박 | "보강 레슨 유효기간이 3일 남았습니다" | warning | `/lessons/{id}` |
| `scheduleChangeRequested` | 스케줄 변경 요청 시 | 스케줄 변경 | "김민수 3/10 레슨 변경 요청" | schedule | `/schedule/{id}` |
| `reviewReceived` | 학생 리뷰 작성 시 | 리뷰 알림 | "김민수님이 리뷰를 남겼습니다" | star | `/profile/reviews` |

> **참고**: `{id}` 부분은 `AppNotification.data` 맵에서 해당 리소스 ID를 추출하여 동적으로 치환한다.

### 2.3 알림 우선순위 (NotificationPriority)

| 레벨 | 용도 | 아이콘 배경색 |
|------|------|-------------|
| `urgent` | 레슨 시작, 노쇼 | error (빨간) |
| `high` | 결제, 취소, 연결 | secondary (오렌지) |
| `normal` | 리마인더 | primary (보라) |
| `low` | 성과, 보고서 | secondary (회색) |

### 2.4 알림 템플릿 (NotificationTemplate)

구현된 템플릿 (13개):
- 레슨: `lessonReminder`, `lessonStarting`
- 연습: `practiceReminder`, `streakWarning`, `streakMilestone`, `practiceAssigned`
- 연결: `connectionRequestReceived`, `connectionRequestAccepted`, `connectionEstablished`
- 보강: `makeupLessonCreated`, `makeupLessonExpiring`
- 스케줄: `scheduleChangeRequested`, `scheduleChangeApproved`, `scheduleChangeAlternative`

템플릿은 `{{placeholder}}` 패턴으로 동적 값 삽입 지원.

---

## 3. 화면/UI 구조

### 3.1 알림 벨 아이콘 (NotificationBellIcon)

모든 화면 앱바에 배치되는 재사용 위젯.

```
AppBar 우측
┌──────┐
│ 🔔 3 │  <- 읽지 않은 알림 수 뱃지 (빨간색, 99+ 표시)
└──────┘
```

- 위치: 앱바 actions
- 뱃지: 읽지 않은 알림 수 (0이면 숨김, 99 초과 시 "99+")
- 탭: `/notifications` 라우트로 이동

### 3.2 알림 목록 화면 (NotificationListScreen)

```
/notifications
┌──────────────────────────────────┐
│  <- 알림                 [모두 읽음] │
├──────────────────────────────────┤
│  오늘                             │
│  ┌──────────────────────────────┐│
│  │ [🎫] 수강권 제안이 도착했어요!    ││
│  │     체험레슨 후 72시간 골든타임... ││
│  │     [제안 확인하기]       1시간 전 ●││
│  └──────────────────────────────┘│
│  ┌──────────────────────────────┐│
│  │ [✅] 연결 완료                   ││
│  │     김선생님과 연결되었습니다!     ││
│  │     [선생님 보기]         5분 전 ●││
│  └──────────────────────────────┘│
│                                  │
│  어제                             │
│  ┌──────────────────────────────┐│
│  │ [🎯] 연습 시간이에요!            ││
│  │     오늘의 연습 목표를 달성해보세요 ││
│  │                         어제    ││
│  └──────────────────────────────┘│
│                                  │
│  월요일                           │
│  ┌──────────────────────────────┐│
│  │ [🔥] 연속 연습 달성!             ││
│  │     7일 연속 연습을 달성했어요!    ││
│  └──────────────────────────────┘│
└──────────────────────────────────┘

● = 읽지 않은 알림 (파란 점)
```

#### 날짜 그룹핑 규칙

| 기간 | 표시 |
|------|------|
| 오늘 | "오늘" |
| 어제 | "어제" |
| 최근 7일 | 요일명 (월요일, 화요일...) |
| 그 이전 | "M월 D일" |

#### 시간 표시 규칙

| 경과 시간 | 표시 |
|----------|------|
| < 1분 | "방금" |
| < 60분 | "N분 전" |
| < 24시간 | "N시간 전" |
| < 7일 | "N일 전" |
| >= 7일 | "M/D" |

### 3.3 개별 알림 항목 (NotificationItem)

| 요소 | 설명 |
|------|------|
| 아이콘 | 알림 유형별 이모지, 우선순위별 배경색 |
| 제목 | 굵은 글씨 (미읽음 시), 일반 (읽음 시) |
| 본문 | 최대 2줄, 말줄임 처리 |
| 시간 | 우측 상단 |
| 액션 버튼 | `actionLabel` 있을 때만 표시 (primary 색상) |
| 미읽음 표시 | 우측 파란 점, 배경 하이라이트 |
| 탭 동작 | 읽음 처리 + `actionUrl`로 딥링크 이동 |

---

## 4. 데이터 모델

### AppNotification 엔티티

```
AppNotification
├── id: String                    // 고유 ID
├── userId: String                // 수신 사용자 ID
├── type: NotificationType        // 알림 유형 (enum, 40+ 종류)
├── priority: NotificationPriority // 우선순위 (urgent/high/normal/low)
├── title: String                 // 알림 제목
├── body: String                  // 알림 본문
├── data: Map<String, dynamic>?   // 추가 데이터 (proposalId 등)
├── createdAt: DateTime           // 생성 시각
├── scheduledAt: DateTime?        // 예약 발송 시각
├── sentAt: DateTime?             // 실제 발송 시각
├── readAt: DateTime?             // 읽은 시각
├── isPush: bool                  // 푸시 발송 여부 (기본 true)
├── isInApp: bool                 // 인앱 표시 여부 (기본 true)
├── actionUrl: String?            // 탭 시 이동할 딥링크 URL
└── actionLabel: String?          // 액션 버튼 텍스트
```

### StudentNotificationSettings

```
StudentNotificationSettings
├── lessonReminderEnabled: bool          // 레슨 리마인더 (기본 true)
├── lessonReminderTimes: List<Duration>  // 리마인더 시간 (기본 24시간 전)
├── practiceReminderEnabled: bool        // 연습 리마인더 (기본 true)
├── practiceReminderTime: TimeOfDay      // 연습 리마인더 시간 (기본 19:00)
├── streakWarningEnabled: bool           // 스트릭 경고 (기본 true)
├── streakWarningTime: TimeOfDay         // 스트릭 경고 시간 (기본 21:00)
├── paymentReminderEnabled: bool         // 결제 리마인더 (기본 true)
├── dndEnabled: bool                     // 방해금지 (기본 true)
├── dndStart: TimeOfDay                  // DND 시작 (기본 22:00)
├── dndEnd: TimeOfDay                    // DND 종료 (기본 08:00)
└── maxDailyNotifications: int           // 일일 최대 (기본 5)
```

### TeacherNotificationSettings

```
TeacherNotificationSettings
├── lessonReminderEnabled: bool          // 레슨 리마인더 (기본 true)
├── lessonReminderTimes: List<Duration>  // 리마인더 시간 (기본 24시간 전)
├── newStudentAlert: bool                // 새 학생 (기본 true)
├── trialBookingAlert: bool              // 체험레슨 요청 (기본 true)
├── paymentReceivedAlert: bool           // 입금 확인 (기본 true)
├── studentPracticeReport: bool          // 학생 연습 현황 (기본 false)
├── reviewReceivedAlert: bool            // 리뷰 알림 (기본 true)
├── dndEnabled: bool                     // 방해금지 (기본 true)
├── dndStart: TimeOfDay                  // DND 시작 (기본 22:00)
└── dndEnd: TimeOfDay                    // DND 종료 (기본 08:00)
```

### NotificationRepository 인터페이스

| 메서드 | 설명 |
|--------|------|
| `getNotifications()` | 현재 사용자 알림 목록 |
| `markAsRead(id)` | 단건 읽음 처리 |
| `markAllAsRead()` | 전체 읽음 처리 |
| `getUnreadCount()` | 미읽음 수 |

### Provider 구성

| Provider | 용도 |
|----------|------|
| `notificationApiRepositoryProvider` | Remote Repository (keepAlive, null if mock) |
| `notificationServiceProvider` | LocalNotificationService 인스턴스 |
| `practiceReminderSchedulerProvider` | 연습 리마인더 스케줄러 |
| `connectionNotificationServiceProvider` | 연결 알림 서비스 |
| `proposalNotificationServiceProvider` | 수강권 제안 알림 서비스 |
| `studentNotificationSettingsNotifierProvider` | 학생 알림 설정 관리 |
| `teacherNotificationSettingsNotifierProvider` | 선생님 알림 설정 관리 |
| `userNotificationsProvider` | 사용자 알림 목록 (Mock/Remote) |
| `unreadNotificationCountProvider` | 미읽음 수 (뱃지용) |
| `notificationActionsProvider` | 알림 액션 (markAsRead, markAllAsRead, delete) |
| `notificationSchedulerServiceProvider` | 알림 스케줄링 서비스 (keepAlive) |

### Provider 설계 (Claude 구현 가이드)

아래는 주요 Provider의 코드 수준 설계이다. 새 Provider 추가 시 이 패턴을 따른다.

```dart
// 알림 목록 조회 (화면 진입 시 자동 fetch)
@riverpod
Future<List<AppNotification>> notifications(Ref ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getNotifications();
}

// 미읽음 수 (뱃지용, 여러 화면에서 참조)
@riverpod
Future<int> unreadNotificationCount(Ref ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getUnreadCount();
}

// 알림 액션 (읽음 처리, 전체 읽음, 삭제)
@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  @override
  Future<List<AppNotification>> build() async {
    final repo = ref.read(notificationRepositoryProvider);
    return repo.getNotifications();
  }

  Future<void> markAsRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(id);
    ref.invalidateSelf();
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead();
    ref.invalidateSelf();
    ref.invalidate(unreadNotificationCountProvider);
  }
}

// 알림 설정 관리 (학생용)
@Riverpod(keepAlive: true)
class StudentNotificationSettingsNotifier extends _$StudentNotificationSettingsNotifier {
  @override
  StudentNotificationSettings build() {
    return StudentNotificationSettings.defaults();
  }

  void updateLessonReminder({bool? enabled, List<Duration>? times}) { ... }
  void updatePracticeReminder({bool? enabled, TimeOfDay? time}) { ... }
  void updateDnd({bool? enabled, TimeOfDay? start, TimeOfDay? end}) { ... }
}
```

> **참고**: `markAsRead` 호출 시 반드시 `unreadNotificationCountProvider`도 invalidate하여 뱃지가 즉시 갱신되도록 한다.

### 백엔드 API (RemoteNotificationRepository)

| 메서드 | API 엔드포인트 |
|--------|---------------|
| 목록 조회 | `GET /notifications` (Paginated) |
| 읽음 처리 | `PATCH /notifications/{id}/read` |
| 전체 읽음 | `PATCH /notifications/read-all` |
| 미읽음 수 | `GET /notifications/unread-count` |

---

## 5. 구현 파일 위치

> `features/notifications/` 기준 상대 경로. 새 파일 추가 시 이 표를 업데이트한다.

| 레이어 | 파일 경로 | 설명 |
|--------|----------|------|
| **Entity** | `domain/entities/notification.dart` | AppNotification, NotificationType, NotificationPriority |
| **Entity** | `domain/entities/notification_settings.dart` | StudentNotificationSettings, TeacherNotificationSettings |
| **Entity** | `domain/entities/notification_template.dart` | NotificationTemplate (템플릿 패턴) |
| **Repository Interface** | `domain/repositories/notification_repository.dart` | NotificationRepository 인터페이스 |
| **Service** | `domain/services/connection_notification_service.dart` | 연결 알림 생성 |
| **Service** | `domain/services/proposal_notification_service.dart` | 수강권 제안 알림 생성 |
| **Service** | `domain/services/notification_scheduler_service.dart` | 알림 예약/취소 |
| **Mock Repository** | `data/repositories/mock_notification_repository.dart` | Mock 데이터 |
| **Remote Repository** | `data/repositories/remote_notification_repository.dart` | 백엔드 API 연동 |
| **Provider** | `presentation/providers/notification_providers.dart` | 모든 알림 Provider |
| **Screen** | `presentation/screens/notification_list_screen.dart` | 알림 목록 화면 |
| **Widget** | `presentation/widgets/notification_bell_icon.dart` | 앱바 알림 벨 아이콘 |
| **Widget** | `presentation/widgets/notification_item.dart` | 개별 알림 항목 위젯 |
| **Route** | `core/router/routes/notification_routes.dart` | 알림 관련 라우트 정의 |

---

## 6. 구현 현황

### 완료

| 컴포넌트 | 파일 | 상태 |
|----------|------|:----:|
| AppNotification 엔티티 | `notifications/domain/entities/notification.dart` | 완료 |
| NotificationSettings 엔티티 | `notifications/domain/entities/notification_settings.dart` | 완료 |
| NotificationRepository | `notifications/domain/repositories/notification_repository.dart` | 완료 |
| RemoteNotificationRepository | `notifications/data/repositories/remote_notification_repository.dart` | 완료 |
| ConnectionNotificationService | `notifications/domain/services/connection_notification_service.dart` | 완료 |
| ProposalNotificationService | `notifications/domain/services/proposal_notification_service.dart` | 완료 |
| NotificationSchedulerService | `notifications/domain/services/notification_scheduler_service.dart` | 완료 |
| Notification Providers | `notifications/presentation/providers/notification_providers.dart` | 완료 |
| NotificationListScreen | `notifications/presentation/screens/notification_list_screen.dart` | 완료 |
| NotificationBellIcon | `notifications/presentation/widgets/notification_bell_icon.dart` | 완료 |
| NotificationItem | `notifications/presentation/widgets/notification_item.dart` | 완료 |

### 서비스별 역할

| 서비스 | 역할 |
|--------|------|
| `LocalNotificationService` | 인앱 알림 표시/관리 (core service) |
| `ConnectionNotificationService` | 연결 요청/수락/완료 알림 생성 |
| `ProposalNotificationService` | 수강권 제안/수락/리마인더/만료 알림 생성 |
| `NotificationSchedulerService` | 미래 시점 알림 예약/취소 (인메모리 큐) |
| `PracticeReminderScheduler` | 연습 리마인더 스케줄링 |

### 미구현 (예정)

| 항목 | 우선순위 |
|------|---------|
| ~~FCM 푸시 알림 인프라~~ | ✅ 완료 (코드 구현, Firebase 설정 대기) |
| 알림 설정 화면 (학생/선생님) | Phase 2 |
| 알림 설정 Hive 영속화 | Phase 2 |
| 알림 빈도 관리 / 개인화 | Phase 3 |
| 서버 기반 알림 스케줄링 | Phase 3 |
| 알림 통계/분석 | Phase 3 |

---

## 7. 관련 스펙

| 스펙 | 관계 |
|------|------|
| [notification_system.md](notification_system.md) | 기존 스펙 (알림 채널, 타이밍, 와이어프레임 상세) |
| [수강권 시스템](../subscription/subscription_system_spec.md) | 수강권 만료 알림 |
| [초대 시스템](../lesson/invite/invite_system_v2.md) | 학원 관련 알림 |
| [수강권 기반 관계](../lesson/invite/subscription_based_relationship.md) | 관계 상태 변경 알림 |
| [팔로우 시스템](../follow/follow_master.md) | 팔로우 알림 (NEW_FOLLOWER 등) |

---

## 8. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2025-12-27 | 기존 스펙 작성 (notification_system.md) |
| 2026-01-27 | 인앱 알림 UI 구현 완료 |
| 2026-03-06 | 구현 코드 기반 Master Spec 작성 (기존 스펙 + 구현 현실 통합) |
| 2026-03-07 | 알림 유형 상세 테이블(트리거/제목/본문/아이콘/딥링크), Provider 코드 설계, 구현 파일 위치 섹션 추가 |
| 2026-03-30 | FCM 푸시 알림 인프라 구현 (FcmService, DeviceToken 모델/API, Firebase 설정 가이드) |
