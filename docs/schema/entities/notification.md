# Notification Entities

> 알림 시스템 엔티티 정의
> 관련 스펙: [notification_system.md](../../specs/notification/notification_system.md)

---

## NotificationType

알림 유형 enum

```dart
enum NotificationType {
  // 레슨
  lessonBooked,
  lessonReminder,
  lessonCancelled,
  lessonRescheduled,
  lessonStarting,
  lessonCompleted,
  lessonNoteShared,

  // 연습
  practiceReminder,
  streakWarning,
  streakMilestone,
  practiceAssigned,
  weeklyGoalAchieved,

  // 결제
  paymentRequested,
  paymentReminder,
  paymentReceived,
  paymentConfirmed,
  lessonsRunningLow,

  // 🆕 수강권 (2026-01-25)
  subscriptionExpiring7d,    // 만료 임박 D-7
  subscriptionExpiring3d,    // 만료 임박 D-3
  subscriptionExpiring1d,    // 만료 임박 D-1
  subscriptionExpired,       // 만료됨
  subscriptionLow,           // 잔여 1회
  subscriptionRenewed,       // 갱신 완료

  // 🆕 회차권 레슨 예약 (2026-01-25)
  nextLessonRequest,         // 다음 레슨 예약 요청 (선생님)
  lessonTimeProposed,        // 레슨 시간 제안 (학생에게)
  lessonTimeConfirmed,       // 레슨 예약 확정

  // 노쇼/취소
  noshowWarning,
  noshowConfirmed,
  teacherNoshow,
  compensationApplied,
  cancellationDeadline,

  // 관리
  newStudentRegistered,
  trialBookingRequest,
  studentPracticeReport,
  reviewReceived,

  // 학원 관련
  academyInviteReceived,
  academyInviteAccepted,
  academyInviteDeclined,
  academyJoinRequest,
  academyJoinApproved,
  academyJoinRejected,
  academyMemberLeft,
  academyMemberRemoved,
}
```

---

## NotificationPriority

알림 우선순위 enum

```dart
enum NotificationPriority {
  low,      // 정보성 (성과, 리포트)
  normal,   // 일반 (리마인더)
  high,     // 중요 (결제, 취소)
  urgent,   // 긴급 (노쇼, 레슨 시작)
}
```

---

## AppNotification

알림 엔티티

```dart
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String body;
  final Map<String, dynamic>? data;     // 추가 데이터 (lessonId 등)
  final DateTime createdAt;
  final DateTime? scheduledAt;          // 예약 발송 시간
  final DateTime? sentAt;               // 실제 발송 시간
  final DateTime? readAt;               // 읽음 시간
  final bool isPush;                    // 푸시 알림 여부
  final bool isInApp;                   // 인앱 알림 여부
}
```

---

## NotificationTemplate

알림 템플릿

```dart
class NotificationTemplate {
  final NotificationType type;
  final String titleTemplate;           // "{{teacherName}} 선생님 레슨"
  final String bodyTemplate;            // "내일 {{time}}에 레슨이 있습니다"
  final NotificationPriority priority;
  final bool bypassDnd;                 // DND 무시 여부
}
```

### 템플릿 예시

```dart
const notificationTemplates = {
  NotificationType.lessonReminder: NotificationTemplate(
    type: NotificationType.lessonReminder,
    titleTemplate: '🎻 레슨 리마인더',
    bodyTemplate: '{{when}} {{teacherName}} 선생님 레슨이 있습니다',
    priority: NotificationPriority.normal,
    bypassDnd: false,
  ),

  NotificationType.streakWarning: NotificationTemplate(
    type: NotificationType.streakWarning,
    titleTemplate: '🔥 스트릭 위험!',
    bodyTemplate: '오늘 연습하면 {{streakDays}}일 스트릭 달성!',
    priority: NotificationPriority.normal,
    bypassDnd: false,
  ),

  NotificationType.lessonStarting: NotificationTemplate(
    type: NotificationType.lessonStarting,
    titleTemplate: '🎵 레슨 시작',
    bodyTemplate: '{{teacherName}} 선생님 레슨이 곧 시작됩니다',
    priority: NotificationPriority.urgent,
    bypassDnd: true,  // DND 무시
  ),

  NotificationType.streakMilestone: NotificationTemplate(
    type: NotificationType.streakMilestone,
    titleTemplate: '🎉 스트릭 달성!',
    bodyTemplate: '{{streakDays}}일 연속 연습! 대단해요!',
    priority: NotificationPriority.low,
    bypassDnd: false,
  ),

  // 🆕 수강권 알림 템플릿
  NotificationType.subscriptionExpiring7d: NotificationTemplate(
    type: NotificationType.subscriptionExpiring7d,
    titleTemplate: '⏰ 수강권 만료 예정',
    bodyTemplate: '{{subscriptionName}}이 7일 후 만료됩니다. 갱신하시겠어요?',
    priority: NotificationPriority.normal,
    bypassDnd: false,
  ),

  NotificationType.subscriptionExpiring3d: NotificationTemplate(
    type: NotificationType.subscriptionExpiring3d,
    titleTemplate: '⚠️ 수강권 곧 만료',
    bodyTemplate: '{{subscriptionName}}이 3일 후 만료됩니다. {{remainingLessons}}회가 남아있어요.',
    priority: NotificationPriority.high,
    bypassDnd: false,
  ),

  NotificationType.subscriptionExpiring1d: NotificationTemplate(
    type: NotificationType.subscriptionExpiring1d,
    titleTemplate: '🚨 수강권 내일 만료',
    bodyTemplate: '{{subscriptionName}}이 내일 만료됩니다. 미사용 횟수가 소멸됩니다.',
    priority: NotificationPriority.high,
    bypassDnd: false,
  ),

  NotificationType.subscriptionLow: NotificationTemplate(
    type: NotificationType.subscriptionLow,
    titleTemplate: '📢 마지막 수강권',
    bodyTemplate: '수강권이 1회 남았습니다. 갱신을 준비해주세요.',
    priority: NotificationPriority.normal,
    bypassDnd: false,
  ),

  NotificationType.nextLessonRequest: NotificationTemplate(
    type: NotificationType.nextLessonRequest,
    titleTemplate: '📅 다음 레슨 예약',
    bodyTemplate: '{{studentName}} 학생 레슨이 완료되었습니다. 다음 레슨 시간을 제안해주세요. ({{remainingLessons}}회 남음)',
    priority: NotificationPriority.normal,
    bypassDnd: false,
  ),

  NotificationType.lessonTimeProposed: NotificationTemplate(
    type: NotificationType.lessonTimeProposed,
    titleTemplate: '🎻 레슨 시간 제안',
    bodyTemplate: '{{teacherName}} 선생님이 다음 레슨 시간을 제안했습니다',
    priority: NotificationPriority.normal,
    bypassDnd: false,
  ),

  NotificationType.lessonTimeConfirmed: NotificationTemplate(
    type: NotificationType.lessonTimeConfirmed,
    titleTemplate: '✅ 레슨 예약 확정',
    bodyTemplate: '{{date}} {{time}} 레슨이 확정되었습니다',
    priority: NotificationPriority.normal,
    bypassDnd: false,
  ),
};
```

---

## NotificationSettings

### StudentNotificationSettings

학생 알림 설정

```dart
class StudentNotificationSettings {
  // 레슨 알림
  final bool lessonReminderEnabled;
  final List<Duration> lessonReminderTimes;  // 기본: 24시간 전

  // 연습 알림
  final bool practiceReminderEnabled;
  final TimeOfDay practiceReminderTime;      // 기본: 19:00
  final bool streakWarningEnabled;
  final TimeOfDay streakWarningTime;         // 기본: 21:00

  // 결제 알림
  final bool paymentReminderEnabled;

  // 방해금지 시간
  final bool dndEnabled;
  final TimeOfDay dndStart;                  // 기본: 22:00
  final TimeOfDay dndEnd;                    // 기본: 08:00

  // 알림 빈도
  final int maxDailyNotifications;           // 기본: 5, 0=무제한
}
```

### TeacherNotificationSettings

선생님 알림 설정

```dart
class TeacherNotificationSettings {
  // 레슨 알림
  final bool lessonReminderEnabled;
  final List<Duration> lessonReminderTimes;

  // 학생 활동 알림 (선택)
  final bool newStudentAlert;                // 새 학생 등록
  final bool trialBookingAlert;              // 체험레슨 요청
  final bool paymentReceivedAlert;           // 입금 확인
  final bool studentPracticeReport;          // 학생 연습 현황 (주간)
  final bool reviewReceivedAlert;            // 리뷰 알림

  // 방해금지 시간
  final bool dndEnabled;
  final TimeOfDay dndStart;
  final TimeOfDay dndEnd;
}
```

### ParentNotificationSettings

학부모 알림 설정

```dart
class ParentNotificationSettings {
  // 기본 설정
  final bool lessonReminderEnabled;
  final List<Duration> lessonReminderTimes;

  // 자녀별 설정 (프로필별로 다르게 설정 가능)
  final Map<String, ChildNotificationSettings> childSettings;

  // 방해금지 시간
  final bool dndEnabled;
  final TimeOfDay dndStart;
  final TimeOfDay dndEnd;
}
```

### ChildNotificationSettings

자녀별 알림 설정

```dart
class ChildNotificationSettings {
  final String childProfileId;
  final bool practiceReminderEnabled;
  final TimeOfDay practiceReminderTime;
  final bool streakWarningEnabled;
}
```

### LessonReminderSettings

레슨 리마인더 설정

```dart
class LessonReminderSettings {
  final List<Duration> reminderTimes;  // 기본: [24시간 전]
  final bool enabled;

  static const defaultSettings = LessonReminderSettings(
    reminderTimes: [Duration(hours: 24)],
    enabled: true,
  );
}
```

**선택 가능한 옵션:**

| 옵션 | 설명 |
|------|------|
| 24시간 전 | 기본값 |
| 3시간 전 | 추가 선택 |
| 1시간 전 | 추가 선택 |
| 30분 전 | 추가 선택 |
