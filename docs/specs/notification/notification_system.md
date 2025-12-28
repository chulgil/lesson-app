# 알림 시스템 스펙

> 작성일: 2025-12-27
> 상태: ✅ 스펙 확정

레슨 앱의 알림 시스템 상세 설계

---

## 목차

1. [개요](#개요)
2. [알림 채널](#알림-채널)
3. [알림 유형](#알림-유형)
4. [알림 타이밍](#알림-타이밍)
5. [사용자 설정](#사용자-설정)
6. [데이터 모델](#데이터-모델)
7. [UI 와이어프레임](#ui-와이어프레임)
8. [기술 구현](#기술-구현)

---

## 개요

### 설계 원칙

1. **개인화** - 사용자별 최적 타이밍과 빈도
2. **피로도 관리** - 과도한 알림 방지, 반응 없으면 빈도 감소
3. **채널 보호** - 푸시 옵트아웃 방지를 위한 품질 관리
4. **선택권 제공** - 선생님/학생 모두 세밀한 설정 가능

### 결정 사항 요약

| 항목 | 결정 |
|------|------|
| 알림 채널 | 푸시 알림 + 인앱 알림 |
| 레슨 리마인더 | 기본 24시간 전, 개인화 가능 |
| 연습 리마인더 | 고정 시간 + 스트릭 위험 시 추가 알림 |
| 스트릭 위험 알림 | 사용자 설정 시간 |
| 알림 빈도 | 사용자 설정 (조용한 시간대 등) |
| 방해금지 시간 | 기본 22시-8시, 커스텀 가능 |
| 선생님 알림 | 선생님이 원하는 알림만 선택 |

---

## 자녀 프로필 알림 처리

> 미성년자 정책에 따라 만 14세 미만 학생은 별도 기기가 없을 수 있습니다.
> 자녀 프로필 관련 모든 알림은 **부모 기기**로 전송됩니다.

### 알림 수신 대상 결정

```dart
/// 알림 수신 대상 결정
class NotificationRouter {
  /// 학생/자녀 관련 알림의 실제 수신자 결정
  String getNotificationRecipient(LessonParticipant participant) {
    if (participant is ChildProfile) {
      // 자녀 프로필 → 부모 계정으로 알림
      return participant.parentId;
    } else if (participant is Student) {
      // 학생 계정 → 본인에게 알림
      return participant.id;
    }
    throw ArgumentError('Unknown participant type');
  }

  /// FCM 토큰 조회 (자녀 프로필은 부모 토큰 사용)
  Future<String?> getFcmToken(LessonParticipant participant) async {
    final recipientId = getNotificationRecipient(participant);
    return await _tokenRepository.getToken(recipientId);
  }
}
```

### 알림 내용 커스터마이징

자녀 프로필일 경우 알림 내용에 자녀 이름 포함:

```dart
/// 알림 메시지 생성
String buildNotificationBody(NotificationType type, LessonParticipant participant) {
  if (participant is ChildProfile) {
    // 부모에게: "민수의 레슨이 내일 14:00에 있습니다"
    return '${participant.name}의 ${getBaseMessage(type)}';
  } else {
    // 학생 본인에게: "레슨이 내일 14:00에 있습니다"
    return getBaseMessage(type);
  }
}
```

### 알림 유형별 수신자

| 알림 유형 | 자녀 프로필 수신자 | 학생 계정 수신자 |
|----------|------------------|----------------|
| 레슨 리마인더 | 부모 | 학생 본인 |
| 연습 리마인더 | 부모 | 학생 본인 |
| 스트릭 위험 | 부모 | 학생 본인 |
| 결제 요청 | 부모 | 학생 본인 (또는 연결된 부모) |
| 레슨 노트 공유 | 부모 | 학생 본인 |

### 학부모 알림 설정

```dart
/// 학부모 알림 설정
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

/// 자녀별 알림 설정
class ChildNotificationSettings {
  final String childProfileId;
  final bool practiceReminderEnabled;
  final TimeOfDay practiceReminderTime;
  final bool streakWarningEnabled;
}
```

### 알림 표시 예시

부모 기기에서 자녀 프로필 알림:

```
┌─────────────────────────────────────┐
│ 레슨앱                        지금   │
│ 🎻 민수 레슨 리마인더                │
│ 내일 14:00 김선생님 레슨이 있습니다   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 레슨앱                        지금   │
│ 🔥 민수 연습 알림                    │
│ 오늘 연습하면 8일 스트릭 달성!        │
└─────────────────────────────────────┘
```

---

## 알림 채널

### 지원 채널

| 채널 | 용도 | 특징 |
|------|------|------|
| **푸시 알림** | 앱 외부 알림 | 즉각적, 주목도 높음 |
| **인앱 알림** | 앱 내부 알림센터 | 기록 보관, 상세 정보 |

### 채널별 역할

```
푸시 알림 (외부)
├── 레슨 리마인더
├── 연습 리마인더
├── 스트릭 위험 경고
├── 취소/변경 긴급 알림
└── 결제 관련 알림

인앱 알림 (알림센터)
├── 모든 푸시 알림 기록
├── 레슨 노트 공유
├── 연습 과제 등록
├── 성과/뱃지 획득
└── 시스템 공지
```

### 알림센터 UI

```
┌─────────────────────────────────────┐
│  🔔 알림                      모두읽음 │
├─────────────────────────────────────┤
│  오늘                               │
│  ┌─────────────────────────────────┐│
│  │ 🎻 레슨 리마인더         10분 전 ││
│  │ 내일 14:00 김선생님 레슨        ││
│  │ [일정 확인]                     ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ 🔥 스트릭 알림           2시간 전 ││
│  │ 7일 연속 연습 중! 오늘도 이어가세요││
│  │ [연습 시작]                     ││
│  └─────────────────────────────────┘│
│                                     │
│  어제                               │
│  ┌─────────────────────────────────┐│
│  │ 📝 연습 과제 등록         어제   ││
│  │ 김선생님이 새 과제를 등록했습니다 ││
│  │ [과제 확인]                     ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

---

## 알림 유형

### 1. 레슨 관련 알림

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `LESSON_BOOKED` | 예약 확정 | 학생/선생님 | 즉시 | ✓ | ✓ |
| `LESSON_REMINDER` | 레슨 리마인더 | 학생/선생님 | 설정값 | ✓ | ✓ |
| `LESSON_CANCELLED` | 취소 알림 | 상대방 | 즉시 | ✓ | ✓ |
| `LESSON_RESCHEDULED` | 변경 알림 | 상대방 | 즉시 | ✓ | ✓ |
| `LESSON_STARTING` | 레슨 시작 | 학생/선생님 | 시작 시 | ✓ | ✓ |
| `LESSON_COMPLETED` | 레슨 완료 | 학생 | 종료 후 | ✗ | ✓ |
| `LESSON_NOTE_SHARED` | 레슨 노트 공유 | 학생 | 작성 시 | ✓ | ✓ |

### 2. 연습 관련 알림

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `PRACTICE_REMINDER` | 연습 리마인더 | 학생 | 설정 시간 | ✓ | ✓ |
| `STREAK_WARNING` | 스트릭 위험 | 학생 | 설정 시간 | ✓ | ✓ |
| `STREAK_MILESTONE` | 스트릭 달성 | 학생 | 달성 시 | ✓ | ✓ |
| `PRACTICE_ASSIGNED` | 연습 과제 등록 | 학생 | 등록 시 | ✓ | ✓ |
| `WEEKLY_GOAL_ACHIEVED` | 주간 목표 달성 | 학생 | 달성 시 | ✓ | ✓ |

### 3. 결제 관련 알림

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `PAYMENT_REQUESTED` | 결제 요청 | 학생 | 요청 시 | ✓ | ✓ |
| `PAYMENT_REMINDER` | 결제 독촉 | 학생 | D-3, D-1 | ✓ | ✓ |
| `PAYMENT_RECEIVED` | 입금 확인 | 선생님 | 입금 시 | ✓ | ✓ |
| `PAYMENT_CONFIRMED` | 결제 완료 | 학생 | 확인 후 | ✓ | ✓ |
| `LESSONS_RUNNING_LOW` | 레슨 소진 예정 | 학생 | 잔여 2회 | ✓ | ✓ |

### 4. 노쇼/취소 관련 알림

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `NOSHOW_WARNING` | 노쇼 경고 | 학생 | 레슨 시작 시 | ✓ | ✓ |
| `NOSHOW_CONFIRMED` | 노쇼 확정 | 학생/선생님 | 15분 후 | ✓ | ✓ |
| `TEACHER_NOSHOW` | 선생님 노쇼 | 학생 | 신고 확정 시 | ✓ | ✓ |
| `COMPENSATION_APPLIED` | 보상 적용 | 학생 | 처리 완료 시 | ✓ | ✓ |
| `CANCELLATION_DEADLINE` | 취소 마감 임박 | 학생 | 마감 2시간 전 | ✓ | ✓ |

### 5. 관리 알림 (선생님용)

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `NEW_STUDENT_REGISTERED` | 새 학생 등록 | 선생님 | 등록 시 | ✓ | ✓ |
| `TRIAL_BOOKING_REQUEST` | 체험레슨 요청 | 선생님 | 요청 시 | ✓ | ✓ |
| `STUDENT_PRACTICE_REPORT` | 학생 연습 현황 | 선생님 | 주간 | ✗ | ✓ |
| `REVIEW_RECEIVED` | 리뷰 작성됨 | 선생님 | 작성 시 | ✓ | ✓ |

---

## 알림 타이밍

### 레슨 리마인더 타이밍

```dart
/// 레슨 리마인더 기본 설정
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

### 연습 리마인더 전략

```
사용자 설정 시간 (예: 19:00)
    ↓
매일 해당 시간에 연습 리마인더 발송
    ↓
(오늘 연습 미완료 시)
    ↓
스트릭 위험 알림 발송 (사용자 설정 시간)
    ↓
예: 22:00 "오늘 연습하면 8일 스트릭 달성!"
```

**연습 리마인더 로직:**

```dart
/// 연습 리마인더 스케줄러
class PracticeReminderScheduler {
  void scheduleReminders(PracticeReminderSettings settings) {
    // 1. 고정 시간 리마인더
    if (settings.dailyReminderEnabled) {
      scheduleAt(settings.dailyReminderTime, NotificationType.practiceReminder);
    }

    // 2. 스트릭 위험 알림 (오늘 연습 안 했을 때만)
    if (settings.streakWarningEnabled && !todayPracticeCompleted) {
      scheduleAt(settings.streakWarningTime, NotificationType.streakWarning);
    }
  }
}
```

---

## 사용자 설정

### 학생 알림 설정

```dart
/// 학생 알림 설정
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

### 선생님 알림 설정

```dart
/// 선생님 알림 설정
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

### 방해금지(DND) 처리

```dart
/// DND 시간대 확인
bool shouldSendNotification(DateTime now, NotificationSettings settings) {
  if (!settings.dndEnabled) return true;

  final currentTime = TimeOfDay.fromDateTime(now);
  final dndStart = settings.dndStart;  // 22:00
  final dndEnd = settings.dndEnd;      // 08:00

  // 자정을 넘어가는 경우 처리
  if (dndStart.hour > dndEnd.hour) {
    // 22:00 ~ 24:00 또는 00:00 ~ 08:00
    return currentTime.hour >= dndEnd.hour &&
           currentTime.hour < dndStart.hour;
  }

  return currentTime.hour < dndStart.hour ||
         currentTime.hour >= dndEnd.hour;
}
```

**DND 중 긴급 알림 처리:**

| 알림 유형 | DND 중 처리 |
|----------|------------|
| 일반 알림 | 지연 발송 (DND 종료 후) |
| 레슨 시작 알림 | 즉시 발송 |
| 취소/변경 알림 | 즉시 발송 |
| 노쇼 관련 알림 | 즉시 발송 |

---

## 데이터 모델

### 핵심 모델

```dart
/// 알림 타입
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
}

/// 알림 우선순위
enum NotificationPriority {
  low,      // 정보성 (성과, 리포트)
  normal,   // 일반 (리마인더)
  high,     // 중요 (결제, 취소)
  urgent,   // 긴급 (노쇼, 레슨 시작)
}

/// 알림 엔티티
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

/// 알림 템플릿
class NotificationTemplate {
  final NotificationType type;
  final String titleTemplate;           // "{{teacherName}} 선생님 레슨"
  final String bodyTemplate;            // "내일 {{time}}에 레슨이 있습니다"
  final NotificationPriority priority;
  final bool bypassDnd;                 // DND 무시 여부
}
```

### 알림 템플릿 예시

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
};
```

---

## UI 와이어프레임

### 학생 알림 설정 화면

```
┌─────────────────────────────────────┐
│  ← 알림 설정                         │
├─────────────────────────────────────┤
│                                     │
│  레슨 알림                           │
│  ┌─────────────────────────────────┐│
│  │ 레슨 리마인더              [ON] ││
│  │ 알림 시간                    >  ││
│  │   ✓ 24시간 전                   ││
│  │   ○ 3시간 전                    ││
│  │   ○ 1시간 전                    ││
│  └─────────────────────────────────┘│
│                                     │
│  연습 알림                           │
│  ┌─────────────────────────────────┐│
│  │ 연습 리마인더              [ON] ││
│  │ 알림 시간               19:00 > ││
│  ├─────────────────────────────────┤│
│  │ 스트릭 위험 알림           [ON] ││
│  │ 알림 시간               21:00 > ││
│  └─────────────────────────────────┘│
│                                     │
│  결제 알림                           │
│  ┌─────────────────────────────────┐│
│  │ 결제 리마인더              [ON] ││
│  │ 레슨 소진 알림             [ON] ││
│  └─────────────────────────────────┘│
│                                     │
│  방해금지 시간                       │
│  ┌─────────────────────────────────┐│
│  │ 방해금지 모드              [ON] ││
│  │ 시작 시간              22:00 >  ││
│  │ 종료 시간              08:00 >  ││
│  │                                 ││
│  │ ⚠️ 긴급 알림은 항상 발송됩니다   ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

### 선생님 알림 설정 화면

```
┌─────────────────────────────────────┐
│  ← 알림 설정                         │
├─────────────────────────────────────┤
│                                     │
│  레슨 알림                           │
│  ┌─────────────────────────────────┐│
│  │ 레슨 리마인더              [ON] ││
│  │ 알림 시간                    >  ││
│  └─────────────────────────────────┘│
│                                     │
│  학생 활동 알림                      │
│  ┌─────────────────────────────────┐│
│  │ 새 학생 등록               [ON] ││
│  │ 체험레슨 요청              [ON] ││
│  │ 입금 확인                  [ON] ││
│  │ 학생 연습 현황 (주간)      [OFF]││
│  │ 리뷰 알림                  [ON] ││
│  └─────────────────────────────────┘│
│                                     │
│  방해금지 시간                       │
│  ┌─────────────────────────────────┐│
│  │ 방해금지 모드              [ON] ││
│  │ 시작 시간              22:00 >  ││
│  │ 종료 시간              08:00 >  ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

### 푸시 알림 예시

```
┌─────────────────────────────────────┐
│ 레슨앱                        지금   │
│ 🎻 레슨 리마인더                     │
│ 내일 14:00 김선생님 레슨이 있습니다   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 레슨앱                        지금   │
│ 🔥 스트릭 위험!                      │
│ 오늘 연습하면 8일 스트릭 달성!        │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 레슨앱                        지금   │
│ 📝 새 연습 과제                      │
│ 김선생님이 "바흐 파르티타" 과제를 등록 │
└─────────────────────────────────────┘
```

---

## 기술 구현

### Flutter 푸시 알림 스택

```yaml
dependencies:
  firebase_messaging: ^14.0.0      # FCM
  flutter_local_notifications: ^16.0.0  # 로컬 알림
  timezone: ^0.9.0                 # 시간대 처리
```

### 알림 서비스 구조

```dart
/// 알림 서비스 인터페이스
abstract class NotificationService {
  Future<void> initialize();
  Future<void> requestPermission();
  Future<void> scheduleNotification(AppNotification notification);
  Future<void> cancelNotification(String id);
  Future<void> cancelAllNotifications();
  Stream<AppNotification> get onNotificationTapped;
}

/// FCM + Local Notification 구현
class NotificationServiceImpl implements NotificationService {
  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications;

  @override
  Future<void> initialize() async {
    // FCM 초기화
    await _fcm.requestPermission();
    final token = await _fcm.getToken();

    // 로컬 알림 초기화
    await _localNotifications.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  @override
  Future<void> scheduleNotification(AppNotification notification) async {
    if (notification.scheduledAt != null) {
      // 예약 알림
      await _localNotifications.zonedSchedule(
        notification.id.hashCode,
        notification.title,
        notification.body,
        tz.TZDateTime.from(notification.scheduledAt!, tz.local),
        _getNotificationDetails(notification),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      // 즉시 발송
      await _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.body,
        _getNotificationDetails(notification),
      );
    }
  }
}
```

### 알림 스케줄러

```dart
/// 연습 리마인더 스케줄러
class PracticeReminderScheduler {
  final NotificationService _notificationService;
  final PracticeRepository _practiceRepository;

  /// 매일 자정에 실행 - 오늘의 알림 스케줄링
  Future<void> scheduleDailyReminders(String userId) async {
    final settings = await _getSettings(userId);
    final today = DateTime.now();

    // 1. 연습 리마인더 스케줄링
    if (settings.practiceReminderEnabled) {
      final reminderTime = DateTime(
        today.year, today.month, today.day,
        settings.practiceReminderTime.hour,
        settings.practiceReminderTime.minute,
      );

      await _notificationService.scheduleNotification(
        AppNotification(
          id: 'practice_reminder_$userId_${today.toIso8601String()}',
          userId: userId,
          type: NotificationType.practiceReminder,
          title: '🎻 연습 시간이에요!',
          body: '오늘의 연습을 시작해보세요',
          scheduledAt: reminderTime,
        ),
      );
    }

    // 2. 스트릭 위험 알림 스케줄링 (연습 미완료 시에만)
    if (settings.streakWarningEnabled) {
      final warningTime = DateTime(
        today.year, today.month, today.day,
        settings.streakWarningTime.hour,
        settings.streakWarningTime.minute,
      );

      final currentStreak = await _practiceRepository.getCurrentStreak(userId);

      // 조건부 알림 - 해당 시간에 연습 완료 여부 체크
      await _notificationService.scheduleConditionalNotification(
        AppNotification(
          id: 'streak_warning_$userId_${today.toIso8601String()}',
          userId: userId,
          type: NotificationType.streakWarning,
          title: '🔥 스트릭 위험!',
          body: '오늘 연습하면 ${currentStreak + 1}일 스트릭 달성!',
          scheduledAt: warningTime,
        ),
        condition: () async => !await _practiceRepository.hasPracticedToday(userId),
      );
    }
  }
}
```

### 백엔드 연동 (추후)

```dart
/// 서버 푸시 알림 (FCM)
class ServerNotificationService {
  /// 레슨 리마인더 발송 (서버에서 스케줄링)
  Future<void> sendLessonReminder(String lessonId) async {
    final lesson = await _lessonRepository.getLesson(lessonId);
    final student = await _userRepository.getUser(lesson.studentId);
    final teacher = await _userRepository.getUser(lesson.teacherId);

    // FCM 토큰으로 푸시 발송
    await _fcmClient.send(
      to: student.fcmToken,
      notification: FCMNotification(
        title: '🎻 레슨 리마인더',
        body: '${teacher.name} 선생님 레슨이 24시간 후입니다',
      ),
      data: {
        'type': 'lesson_reminder',
        'lessonId': lessonId,
      },
    );
  }
}
```

---

## 구현 우선순위

### Phase 1 (MVP)

1. 푸시 알림 기본 인프라 (FCM + Local)
2. 레슨 리마인더 (24시간 전)
3. 연습 리마인더 (고정 시간)
4. 인앱 알림센터

### Phase 2

1. 스트릭 위험 알림
2. 결제 관련 알림
3. 알림 설정 화면 (학생/선생님)
4. 방해금지 시간대

### Phase 3

1. 알림 개인화 (시간 커스텀)
2. 알림 빈도 관리
3. 선생님 학생 활동 알림
4. 알림 통계/분석

---

## 참고 자료

- [Acuity Scheduling - Appointment Reminders Guide](https://acuityscheduling.com/learn/appointment-reminders-guide)
- [Duolingo - AI Behind Push Notifications](https://blog.duolingo.com/hi-its-duo-the-ai-behind-the-meme/)
- [Duolingo Streaks Retention Secret](https://darewell.co/en/duolingo-streaks-retention-secret/)
- [EdTech Push Notification Research](https://link.springer.com/article/10.1186/s41239-025-00537-x)
