# 알림 시스템 스펙

> 작성일: 2025-12-27
> 상태: ✅ 스펙 확정
> 엔티티 스키마: [notification.md](../../schema/entities/notification.md)

레슨 앱의 알림 시스템 상세 설계

---

## 목차

1. [개요](#개요)
2. [알림 채널](#알림-채널)
3. [알림 유형](#알림-유형)
4. [알림 타이밍](#알림-타이밍)
5. [사용자 설정](#사용자-설정)
6. [UI 와이어프레임](#ui-와이어프레임)
7. [기술 구현](#기술-구현)

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

### 알림 수신 대상 결정 로직

```dart
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
```

### 알림 내용 커스터마이징 로직

자녀 프로필일 경우 알림 내용에 자녀 이름 포함:

```dart
/// 알림 메시지 생성
String buildNotificationBody(
  NotificationType type,
  LessonParticipant participant,
) {
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
| 입금 안내 | 부모 | 학생 본인 (또는 연결된 부모) |
| 레슨 노트 공유 | 부모 | 학생 본인 |

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
└── 입금 상태 알림

인앱 알림 (알림센터)
├── 모든 푸시 알림 기록
├── 레슨 노트 공유
├── 연습 과제 등록
├── 성과/뱃지 획득
└── 시스템 공지
```

### 알림센터 UI (✅ 구현 완료)

**진입 경로**: 앱바의 종 아이콘(NotificationBellIcon) 탭 → `/notifications`

```
┌─────────────────────────────────────┐
│  ← 알림                    [모두 읽음] │
├─────────────────────────────────────┤
│  오늘                               │
│  ┌─────────────────────────────────┐│
│  │ 🎻 레슨 리마인더         10분 전 ││
│  │ 내일 14:00 김선생님 레슨       ● ││
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

● = 읽지 않은 알림 표시 (파란 점)
```

**구현 파일**:
- `lib/features/notifications/presentation/screens/notification_list_screen.dart`
- `lib/features/notifications/presentation/widgets/notification_item.dart`
- `lib/features/notifications/presentation/widgets/notification_bell_icon.dart`

---

## 알림 유형

> 엔티티 정의: [NotificationType](../../schema/entities/notification.md#notificationtype)

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

### 3. 입금 상태 알림

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `PAYMENT_REQUESTED` | 입금 안내 | 학생 | 요청 시 | ✓ | ✓ |
| `PAYMENT_REMINDER` | 입금 확인 대기 알림 | 학생 | D-3, D-1 | ✓ | ✓ |
| `PAYMENT_RECEIVED` | 입금 완료 알림 | 선생님 | 학생/학부모 알림 시 | ✓ | ✓ |
| `PAYMENT_CONFIRMED` | 입금 확인 완료 | 학생 | 확인 후 | ✓ | ✓ |
| `LESSONS_RUNNING_LOW` | 레슨 소진 예정 | 학생 | 잔여 1회 | ✓ | ✓ |
| `MONTHLY_SCHEDULE_CREATED` | 🆕 월정액 스케줄 생성 | 학생 | 월초/입금 예정일 | ✓ | ✓ |
| `MONTHLY_PAYMENT_PENDING` | 🆕 월정액 입금 확인 대기 | 선생님 | 스케줄 생성 시 | ✗ | ✓ |

### 3-1. 수강권 관련 알림 (🆕)

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `SUBSCRIPTION_EXPIRING_7D` | 만료 임박 | 학생 | D-7 | ✓ | ✓ |
| `SUBSCRIPTION_EXPIRING_3D` | 만료 임박 | 학생 | D-3 | ✓ | ✓ |
| `SUBSCRIPTION_EXPIRING_1D` | 만료 임박 | 학생 | D-1 | ✓ | ✓ |
| `SUBSCRIPTION_EXPIRED` | 만료됨 | 학생 + 선생님 | 만료일 | ✗ | ✓ |
| `SUBSCRIPTION_LOW` | 잔여 1회 | 학생 | 레슨 완료 시 | ✓ | ✓ |
| `SUBSCRIPTION_RENEWED` | 갱신 완료 | 학생 | 갱신 시 | ✓ | ✓ |
| `NEXT_LESSON_REQUEST` | 다음 레슨 예약 요청 | 선생님 | 회차권 레슨 완료 시 | ✓ | ✓ |
| `LESSON_TIME_PROPOSED` | 레슨 시간 제안 | 학생 | 선생님 제안 시 | ✓ | ✓ |
| `LESSON_TIME_CONFIRMED` | 레슨 예약 확정 | 선생님 + 학생 | 학생 선택 시 | ✓ | ✓ |

#### 수강권 알림 상세

```
[D-7 알림]
┌─────────────────────────────────────┐
│ 레슨앱                        오전 9:00 │
│ ⏰ 수강권 만료 예정                    │
│ 8회권이 7일 후 만료됩니다.             │
│ 갱신하시겠어요?                        │
└─────────────────────────────────────┘

[D-3 알림]
┌─────────────────────────────────────┐
│ 레슨앱                        오전 9:00 │
│ ⚠️ 수강권 곧 만료                      │
│ 8회권이 3일 후 만료됩니다.             │
│ 2회가 남아있어요.                      │
└─────────────────────────────────────┘

[D-1 알림]
┌─────────────────────────────────────┐
│ 레슨앱                        오전 9:00 │
│ 🚨 수강권 내일 만료                    │
│ 8회권이 내일 만료됩니다.               │
│ 미사용 횟수가 소멸됩니다.               │
└─────────────────────────────────────┘

[잔여 1회 알림]
┌─────────────────────────────────────┐
│ 레슨앱                        레슨 후   │
│ 📢 마지막 수강권                       │
│ 수강권이 1회 남았습니다.               │
│ 갱신을 준비해주세요.                    │
└─────────────────────────────────────┘

[회차권 다음 레슨 제안 - 선생님]
┌─────────────────────────────────────┐
│ 레슨앱                        레슨 후   │
│ 📅 다음 레슨 예약                      │
│ 김서연 학생 레슨이 완료되었습니다.       │
│ 다음 레슨 시간을 제안해주세요. (3회 남음) │
└─────────────────────────────────────┘

[시간 제안 알림 - 학생]
┌─────────────────────────────────────┐
│ 레슨앱                          지금   │
│ 🎻 레슨 시간 제안                      │
│ 김선생님이 다음 레슨 시간을 제안했습니다  │
│ [시간 선택하기]                        │
└─────────────────────────────────────┘
```

→ 수강권 시스템 상세: [subscription_system_spec.md](../subscription/subscription_system_spec.md#59-수강권-만료-알림-시스템)

### 4. 노쇼/취소 관련 알림

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `NOSHOW_WARNING` | 노쇼 경고 | 학생 | 레슨 시작 시 | ✓ | ✓ |
| `NOSHOW_CONFIRMED` | 노쇼 확정 | 학생/선생님 | 15분 후 | ✓ | ✓ |
| `TEACHER_NOSHOW` | 선생님 노쇼 | 학생 | 신고 확정 시 | ✓ | ✓ |
| `COMPENSATION_APPLIED` | 보상 적용 | 학생 | 처리 완료 시 | ✓ | ✓ |
| `CANCELLATION_DEADLINE` | 취소 마감 임박 | 학생 | 마감 2시간 전 | ✓ | ✓ |

### 5. 관계/팔로우 관련 알림

> **참조**: [수강권 중심 관계 모델](../lesson/invite/subscription_based_relationship.md)
>
> 선생님-학생 관계는 **수강권 기반**으로 자동 관리됩니다.
> **팔로우**는 소식 구독 용도로 분리되었습니다.

#### 5.1 관계 상태 변경 알림 (RelationshipStatus)

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `TRIAL_BOOKED` | 체험 예약됨 | 선생님 | 예약 시 | ✓ | ✓ |
| `RELATIONSHIP_ACTIVATED` | 관계 활성화 | 양쪽 | 수강권 발급 시 | ✓ | ✓ |
| `SUBSCRIPTION_EXPIRED_NOTICE` | 수강권 만료 알림 | 양쪽 | 만료 시 | ✓ | ✓ |
| `EXPIRED_WARNING_7D` | 이전 레슨 전환 예정 | 선생님 | 만료 후 23일 | ✗ | ✓ |
| `RELATIONSHIP_TO_PAST` | 이전 레슨 전환됨 | 선생님 | 만료 후 30일 | ✗ | ✓ |

#### 5.2 팔로우 알림 (소식 구독)

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `NEW_FOLLOWER` | 새 팔로워 | 선생님/학원 | 팔로우 시 | ✗ | ✓ |
| `TEACHER_NEWS` | 선생님 소식 | 팔로워 | 소식 등록 시 | ✓ | ✓ |
| `ACADEMY_NEWS` | 학원 소식 | 팔로워 | 소식 등록 시 | ✓ | ✓ |
| `PERFORMANCE_NOTICE` | 공연/발표회 안내 | 팔로워 | 등록 시 | ✓ | ✓ |

#### 관계/팔로우 알림 상세

```
[체험 예약 - 선생님]
┌─────────────────────────────────────┐
│ 레슨앱                          지금   │
│ 🎻 체험 레슨 예약                      │
│ 김서연 학생이 체험을 예약했습니다        │
│ 1/30 (화) 14:00                      │
│ [예약 확인하기]                        │
└─────────────────────────────────────┘

[수강권 발급 → 관계 활성화 - 학생]
┌─────────────────────────────────────┐
│ 레슨앱                          지금   │
│ ✅ 수강 시작                           │
│ 김선생님과 정규 레슨이 시작됩니다!       │
│ 수강권: 8회권                         │
│ [레슨 예약하기]                        │
└─────────────────────────────────────┘

[수강권 만료 - 선생님]
┌─────────────────────────────────────┐
│ 레슨앱                          지금   │
│ 📋 수강권 만료                         │
│ 김서연 학생 수강권이 만료되었습니다      │
│ 30일 후 '이전 레슨'으로 이동합니다       │
│ [수강권 제안하기]                      │
└─────────────────────────────────────┘

[공연 안내 - 팔로워]
┌─────────────────────────────────────┐
│ 레슨앱                          지금   │
│ 🎵 공연 안내                           │
│ 김선생님의 연말 발표회                  │
│ 12/25 15:00 예술의전당                 │
│ [자세히 보기]                          │
└─────────────────────────────────────┘
```

### 6. 관리 알림 (선생님용)

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `NEW_STUDENT_REGISTERED` | 새 학생 등록 | 선생님 | 등록 시 | ✓ | ✓ |
| `TRIAL_BOOKING_REQUEST` | 체험레슨 요청 | 선생님 | 요청 시 | ✓ | ✓ |
| `STUDENT_PRACTICE_REPORT` | 학생 연습 현황 | 선생님 | 주간 | ✗ | ✓ |
| `REVIEW_RECEIVED` | 리뷰 작성됨 | 선생님 | 작성 시 | ✓ | ✓ |

### 7. 학원 관련 알림

> 학원-선생님 관계 알림. 자세한 내용은 [초대 시스템 v2](../lesson/invite/invite_system_v2.md#학원-선생님-초대-시스템) 참조.

| 알림 ID | 유형 | 수신자 | 타이밍 | 푸시 | 인앱 |
|---------|------|--------|--------|------|------|
| `ACADEMY_INVITE_RECEIVED` | 학원 강사 초대 | 선생님 | 초대 시 | ✓ | ✓ |
| `ACADEMY_INVITE_ACCEPTED` | 초대 수락 | 학원 관리자 | 수락 시 | ✓ | ✓ |
| `ACADEMY_INVITE_DECLINED` | 초대 거절 | 학원 관리자 | 거절 시 | ✗ | ✓ |
| `ACADEMY_JOIN_REQUEST` | 가입 요청 | 학원 관리자 | 요청 시 | ✓ | ✓ |
| `ACADEMY_JOIN_APPROVED` | 가입 승인 | 선생님 | 승인 시 | ✓ | ✓ |
| `ACADEMY_JOIN_REJECTED` | 가입 거절 | 선생님 | 거절 시 | ✓ | ✓ |
| `ACADEMY_MEMBER_LEFT` | 강사 탈퇴 | 학원 관리자 | 탈퇴 시 | ✓ | ✓ |
| `ACADEMY_MEMBER_REMOVED` | 강사 제명 | 선생님 | 제명 시 | ✓ | ✓ |

---

## 알림 타이밍

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

### 연습 리마인더 스케줄링 로직

```dart
void scheduleReminders(PracticeReminderSettings settings) {
  // 1. 고정 시간 리마인더
  if (settings.dailyReminderEnabled) {
    scheduleAt(
      settings.dailyReminderTime,
      NotificationType.practiceReminder,
    );
  }

  // 2. 스트릭 위험 알림 (오늘 연습 안 했을 때만)
  if (settings.streakWarningEnabled && !todayPracticeCompleted) {
    scheduleAt(
      settings.streakWarningTime,
      NotificationType.streakWarning,
    );
  }
}
```

---

## 사용자 설정

> 설정 엔티티 정의: [NotificationSettings](../../schema/entities/notification.md#notificationsettings)

### 방해금지(DND) 처리 로직

```dart
bool shouldSendNotification(
  DateTime now,
  NotificationSettings settings,
) {
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

### DND 중 긴급 알림 처리

| 알림 유형 | DND 중 처리 |
|----------|------------|
| 일반 알림 | 지연 발송 (DND 종료 후) |
| 레슨 시작 알림 | 즉시 발송 |
| 취소/변경 알림 | 즉시 발송 |
| 노쇼 관련 알림 | 즉시 발송 |

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
│  입금 상태 알림                           │
│  ┌─────────────────────────────────┐│
│  │ 입금 확인 대기 알림        [ON] ││
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

### 알림 서비스 인터페이스

```dart
abstract class NotificationService {
  Future<void> initialize();
  Future<void> requestPermission();
  Future<void> scheduleNotification(AppNotification notification);
  Future<void> cancelNotification(String id);
  Future<void> cancelAllNotifications();
  Stream<AppNotification> get onNotificationTapped;
}
```

### FCM + Local Notification 구현

```dart
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

### 연습 리마인더 스케줄러 구현

```dart
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
        today.year,
        today.month,
        today.day,
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
        today.year,
        today.month,
        today.day,
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
        condition: () async {
          return !await _practiceRepository.hasPracticedToday(userId);
        },
      );
    }
  }
}
```

### 백엔드 연동 (추후)

```dart
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

## 구현 현황 ✅

### 완료된 구현 (2026-01-27)

#### 알림 UI 컴포넌트

| 파일 | 설명 | 상태 |
|------|------|:----:|
| `NotificationBellIcon` | 앱바용 종 아이콘 (뱃지 포함) | ✅ |
| `NotificationListScreen` | 알림 목록 화면 (날짜별 그룹핑) | ✅ |
| `NotificationItem` | 개별 알림 항목 위젯 | ✅ |
| `notification_providers.dart` | 알림 상태 관리 Provider | ✅ |
| `notification_routes.dart` | 알림 라우트 정의 | ✅ |

#### 알림 아이콘 UX 패턴

```
앱바 (모든 화면)
├── NotificationBellIcon (우측 상단)
│   ├── 종 아이콘 (Icons.notifications_outlined)
│   ├── 읽지 않은 알림 수 뱃지 (빨간색)
│   └── 탭 → /notifications로 이동
```

#### 알림 목록 화면 구조

```
┌─────────────────────────────────────┐
│  ← 알림                    [모두 읽음] │
├─────────────────────────────────────┤
│  오늘                               │
│  ┌─────────────────────────────────┐│
│  │ ✅ 연결 완료              5분 전 ││
│  │ 김선생님과 연결되었습니다!       ●││
│  │ [선생님 보기]                   ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ 🎻 레슨 알림            2시간 전 ││
│  │ 내일 오후 3시 김선생님과 레슨     ││
│  └─────────────────────────────────┘│
│                                     │
│  어제                               │
│  ┌─────────────────────────────────┐│
│  │ 🎯 연습 시간이에요!       어제   ││
│  │ 오늘의 연습 목표를 달성해보세요   ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

#### Provider 구성

| Provider | 용도 |
|----------|------|
| `userNotificationsProvider` | 사용자 알림 목록 (AsyncValue) |
| `unreadNotificationCountProvider` | 읽지 않은 알림 수 (뱃지용) |
| `notificationActionsProvider` | markAsRead, markAllAsRead 액션 |
| `connectionNotificationServiceProvider` | 연결 알림 발송 서비스 |

#### 사용 방법

```dart
// 앱바에 알림 아이콘 추가
AppBar(
  actions: [
    NotificationBellIcon(),  // 뱃지 자동 표시
  ],
)

// 알림 목록 화면으로 이동
context.push(AppRoutes.notifications);
```

---

## 구현 우선순위

### Phase 1 (MVP)

1. ~~인앱 알림센터~~ ✅ 완료
2. 푸시 알림 기본 인프라 (FCM + Local)
3. 레슨 리마인더 (24시간 전)
4. 연습 리마인더 (고정 시간)

### Phase 2

1. 스트릭 위험 알림
2. 입금 상태 알림
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
