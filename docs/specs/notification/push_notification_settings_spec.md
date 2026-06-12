# 세밀한 푸시 알림 설정 (Granular Push Notification Settings) Spec

> 버전: 1.1
> 작성일: 2026-05-07
> 최종 수정: 2026-06-12 (출시 준비도 감사 P1-1 — Phase 1.5 승격 반영)
> 상태: Draft
> 관련 스펙: [notification_master.md](notification_master.md)

---

## 1. 개요

### 1.1 문제 정의

현재 레슨앱의 알림 설정은 전체 ON/OFF 단일 토글만 존재한다. 결과적으로:

- 공지 알림이 많아 불편한 사용자가 **모든 알림**을 꺼버린다
- 레슨 시작 리마인더, 수강권 만료 같은 **중요 알림**도 함께 차단된다
- 경쟁 앱 대비 알림 개인화가 부재하여 사용자 이탈을 유발한다

### 1.2 해결 방향

카테고리별 ON/OFF 토글 + 방해금지 시간대로 알림 피로도를 낮추면서 중요 알림 수신율은 유지한다.

우체국 사서함에 비유하면, 지금은 "우편물 전체 수령 or 전체 거부" 둘뿐이다. 이 기능은 "일반 우편은 거부, 등기와 특급만 수령" 같은 **선별 수령**을 가능하게 한다.

### 1.3 범위

| 포함 | 제외 |
|------|------|
| 카테고리별 푸시 알림 ON/OFF | 인앱 알림 센터 표시 여부 |
| 방해금지 시간대 설정 | 알림 빈도 조절 (단계별 슬라이더) |
| 전체 끄기 마스터 스위치 | 알림 톤/진동 설정 (OS 위임) |
| FCM 토픽 구독 관리 | 카테고리별 리마인더 시간 세부 조정 |

---

## 2. 알림 카테고리 정의

기존 `notification_master.md` §2.2의 알림 유형을 6개 사용자 대면 카테고리로 묶는다.

### 2.1 카테고리 매핑 테이블

| 카테고리 키 | 표시명 | 포함 알림 타입 | 기본값 | DND 우회 허용 |
|-------------|--------|---------------|--------|--------------|
| `lesson` | 레슨 알림 | `lessonBooked`, `lessonReminder`, `lessonStarting`, `lessonCompleted`, `lessonCancelled`, `lessonRescheduled`, `lessonNoteShared`, `noshowWarning`, `noshowConfirmed`, `teacherNoshow`, `compensationApplied`, `cancellationDeadline` | ON | 일부 (lessonStarting, lessonCancelled) |
| `schedule` | 스케줄 변경 | `scheduleChangeRequested`, `scheduleChangeApproved`, `scheduleChangeRejected`, `scheduleChangeAlternative`, `makeupLessonCreated`, `makeupLessonExpiring`, `makeupLessonExpired`, `rescheduleAllowanceUsed`, `rescheduleAllowanceDepleted` | ON | 없음 |
| `subscription` | 수강권 | `paymentRequested`, `paymentReminder`, `paymentReceived`, `paymentConfirmed`, `lessonsRunningLow`, `subscriptionExpiringSoon`, `subscriptionExpired`, `proposalReceived`, `proposalReminder24h`, `proposalReminder48h`, `proposalReminder72h`, `proposalAccepted`, `proposalExpired` | ON | 없음 |
| `announcement` | 공지 | `newStudentRegistered`, `trialBookingRequest`, `reviewReceived`, `connectionRequestReceived`, `connectionRequestAccepted`, `connectionRequestRejected`, `connectionEstablished`, `connectionDisconnected`, `generalAnnouncement`, `studentPracticeReport` | ON | 없음 |
| `practice` | 연습 리마인더 | `practiceReminder`, `practiceAssigned`, `streakWarning`, `streakMilestone`, `weeklyGoalAchieved`, `recordingFeedbackReceived`, `inactivityReminder7d`, `inactivityReminder14d` | ON | 없음 |
| `marketing` | 마케팅 | `winBackOffer30d`, 신규 기능 안내, 이벤트 알림 | **OFF** | 없음 |

> **설계 결정**: `marketing` 카테고리만 기본 OFF. 나머지 5개는 기본 ON.
> 마케팅 카테고리는 사용자가 명시적으로 동의한 경우에만 ON 전환 가능 (GDPR/개인정보보호법 대응).

### 2.2 DND 우회 예외 알림

카테고리를 꺼도 방해금지 시간대에도 **반드시 전달**되는 알림:

| 알림 타입 | 이유 |
|-----------|------|
| `lessonStarting` | 실시간 알림, 놓치면 레슨 시작 불가 |
| `lessonCancelled` | 헛걸음 방지, 이동 중 취소 전달 필수 |
| `noshowWarning` | 노쇼 확정 전 마지막 경고 |
| `noshowConfirmed` | 패널티 발생 전 알림 |

> 이 알림들은 `lesson` 카테고리를 꺼도 **항상 전송**된다. UI에서 "일부 레슨 알림은 끌 수 없어요" 안내 문구 표시.

---

## 3. 데이터 모델

### 3.1 NotificationPreferences (백엔드 모델)

```python
# backend/app/models/notification_preferences.py

class NotificationPreferences(Base):
    __tablename__ = "notification_preferences"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True, nullable=False)

    # 마스터 스위치
    all_push_enabled: Mapped[bool] = mapped_column(Boolean, default=True)

    # 카테고리별 토글
    lesson_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    schedule_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    subscription_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    announcement_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    practice_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    marketing_enabled: Mapped[bool] = mapped_column(Boolean, default=False)

    # 방해금지 시간대
    quiet_hours_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    quiet_hours_start: Mapped[time] = mapped_column(Time, default=time(22, 0))  # 22:00
    quiet_hours_end: Mapped[time] = mapped_column(Time, default=time(8, 0))    # 08:00

    created_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, onupdate=func.now())
```

> 일일 발송 한도(역할별 최대 알림 수)는 [notification_master.md §2.5.2 일일 한도](notification_master.md)를 따른다.

### 3.2 NotificationPreferencesSchema (Pydantic)

```python
# backend/app/schemas/notification_preferences.py

class NotificationPreferencesBase(BaseModel):
    all_push_enabled: bool = True
    lesson_enabled: bool = True
    schedule_enabled: bool = True
    subscription_enabled: bool = True
    announcement_enabled: bool = True
    practice_enabled: bool = True
    marketing_enabled: bool = False
    quiet_hours_enabled: bool = True
    quiet_hours_start: time = time(22, 0)
    quiet_hours_end: time = time(8, 0)

class NotificationPreferencesRead(NotificationPreferencesBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime | None

    model_config = ConfigDict(from_attributes=True)

class NotificationPreferencesUpdate(BaseModel):
    """PATCH 용. 모든 필드 optional."""
    all_push_enabled: bool | None = None
    lesson_enabled: bool | None = None
    schedule_enabled: bool | None = None
    subscription_enabled: bool | None = None
    announcement_enabled: bool | None = None
    practice_enabled: bool | None = None
    marketing_enabled: bool | None = None
    quiet_hours_enabled: bool | None = None
    quiet_hours_start: time | None = None
    quiet_hours_end: time | None = None
```

### 3.3 Flutter 엔티티

```dart
// frontend/lib/features/notifications/domain/entities/notification_preferences.dart

@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    // 마스터 스위치
    @Default(true) bool allPushEnabled,

    // 카테고리별 토글
    @Default(true) bool lessonEnabled,
    @Default(true) bool scheduleEnabled,
    @Default(true) bool subscriptionEnabled,
    @Default(true) bool announcementEnabled,
    @Default(true) bool practiceEnabled,
    @Default(false) bool marketingEnabled,

    // 방해금지 시간대
    @Default(true) bool quietHoursEnabled,
    @Default(TimeOfDayValue(hour: 22, minute: 0)) TimeOfDayValue quietHoursStart,
    @Default(TimeOfDayValue(hour: 8, minute: 0)) TimeOfDayValue quietHoursEnd,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  /// 기본값 생성자
  factory NotificationPreferences.defaults() => const NotificationPreferences();
}

/// TimeOfDay는 freezed/json_serializable 비호환. 래퍼 사용.
@freezed
class TimeOfDayValue with _$TimeOfDayValue {
  const factory TimeOfDayValue({
    required int hour,
    required int minute,
  }) = _TimeOfDayValue;

  factory TimeOfDayValue.fromJson(Map<String, dynamic> json) =>
      _$TimeOfDayValueFromJson(json);
}

extension TimeOfDayValueX on TimeOfDayValue {
  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);
  String format() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
```

### 3.4 NotificationCategory 열거형

```dart
// frontend/lib/features/notifications/domain/entities/notification_category.dart

enum NotificationCategory {
  lesson,
  schedule,
  subscription,
  announcement,
  practice,
  marketing;

  String get displayName => switch (this) {
    lesson       => AppStrings.notifCategoryLesson,
    schedule     => AppStrings.notifCategorySchedule,
    subscription => AppStrings.notifCategorySubscription,
    announcement => AppStrings.notifCategoryAnnouncement,
    practice     => AppStrings.notifCategoryPractice,
    marketing    => AppStrings.notifCategoryMarketing,
  };

  String get description => switch (this) {
    lesson       => AppStrings.notifCategoryLessonDesc,
    schedule     => AppStrings.notifCategoryScheduleDesc,
    subscription => AppStrings.notifCategorySubscriptionDesc,
    announcement => AppStrings.notifCategoryAnnouncementDesc,
    practice     => AppStrings.notifCategoryPracticeDesc,
    marketing    => AppStrings.notifCategoryMarketingDesc,
  };

  /// 기본 활성화 여부
  bool get defaultEnabled => this != marketing;

  /// FCM 토픽 키 (user_id 와 조합: "lesson_{userId}")
  String get topicKey => name;
}
```

---

## 4. API 계약

### 4.1 엔드포인트

```
GET  /api/v1/users/me/notification-preferences
PUT  /api/v1/users/me/notification-preferences
```

### 4.2 GET — 알림 설정 조회

**Request**
```http
GET /api/v1/users/me/notification-preferences
Authorization: Bearer {token}
```

**Response 200**
```json
{
  "id": 42,
  "user_id": 123,
  "all_push_enabled": true,
  "lesson_enabled": true,
  "schedule_enabled": true,
  "subscription_enabled": true,
  "announcement_enabled": false,
  "practice_enabled": true,
  "marketing_enabled": false,
  "quiet_hours_enabled": true,
  "quiet_hours_start": "22:00:00",
  "quiet_hours_end": "08:00:00",
  "created_at": "2026-05-01T09:00:00Z",
  "updated_at": "2026-05-07T14:30:00Z"
}
```

**신규 사용자 처리**: 설정 레코드가 없으면 기본값으로 자동 생성 후 반환 (404 반환 안 함).

### 4.3 PUT — 알림 설정 수정

전체 교체(PUT). 일부 필드만 변경할 때도 전체 객체를 전송한다.

**Request**
```http
PUT /api/v1/users/me/notification-preferences
Authorization: Bearer {token}
Content-Type: application/json

{
  "all_push_enabled": true,
  "lesson_enabled": true,
  "schedule_enabled": true,
  "subscription_enabled": true,
  "announcement_enabled": false,
  "practice_enabled": true,
  "marketing_enabled": false,
  "quiet_hours_enabled": true,
  "quiet_hours_start": "22:00:00",
  "quiet_hours_end": "08:00:00"
}
```

**Response 200**: 업데이트된 `NotificationPreferencesRead` 객체 반환.

**Response 422**: `quiet_hours_start == quiet_hours_end` 등 유효성 오류.

### 4.4 서버사이드 전송 필터링 로직

```python
# backend/app/services/notification_service.py

async def should_send_push(
    notification_type: NotificationType,
    user_id: int,
    db: AsyncSession,
) -> bool:
    prefs = await get_or_create_preferences(user_id, db)

    # 마스터 스위치
    if not prefs.all_push_enabled:
        # DND 우회 알림은 마스터 스위치도 무시
        if notification_type not in DND_BYPASS_TYPES:
            return False

    # 카테고리 필터
    category = NOTIFICATION_TYPE_CATEGORY_MAP[notification_type]
    if not getattr(prefs, f"{category.value}_enabled", True):
        # DND 우회 알림은 카테고리 설정도 무시
        if notification_type not in DND_BYPASS_TYPES:
            return False

    # 방해금지 시간대 (DND 우회 타입 제외)
    if prefs.quiet_hours_enabled and notification_type not in DND_BYPASS_TYPES:
        now_local = get_user_local_time(user_id)  # 사용자 타임존 고려
        if is_within_quiet_hours(now_local, prefs.quiet_hours_start, prefs.quiet_hours_end):
            return False

    return True

# 알림 타입 → 카테고리 매핑
NOTIFICATION_TYPE_CATEGORY_MAP: dict[NotificationType, NotificationCategory] = {
    NotificationType.lesson_booked:           NotificationCategory.lesson,
    NotificationType.lesson_reminder:         NotificationCategory.lesson,
    NotificationType.lesson_starting:         NotificationCategory.lesson,
    NotificationType.lesson_completed:        NotificationCategory.lesson,
    NotificationType.lesson_cancelled:        NotificationCategory.lesson,
    NotificationType.lesson_rescheduled:      NotificationCategory.lesson,
    NotificationType.lesson_note_shared:      NotificationCategory.lesson,
    NotificationType.noshow_warning:          NotificationCategory.lesson,
    NotificationType.noshow_confirmed:        NotificationCategory.lesson,
    NotificationType.teacher_noshow:          NotificationCategory.lesson,
    NotificationType.compensation_applied:    NotificationCategory.lesson,
    NotificationType.cancellation_deadline:   NotificationCategory.lesson,
    NotificationType.schedule_change_requested:   NotificationCategory.schedule,
    NotificationType.schedule_change_approved:    NotificationCategory.schedule,
    NotificationType.schedule_change_rejected:    NotificationCategory.schedule,
    NotificationType.schedule_change_alternative: NotificationCategory.schedule,
    NotificationType.makeup_lesson_created:       NotificationCategory.schedule,
    NotificationType.makeup_lesson_expiring:      NotificationCategory.schedule,
    NotificationType.makeup_lesson_expired:       NotificationCategory.schedule,
    NotificationType.reschedule_allowance_used:   NotificationCategory.schedule,
    NotificationType.reschedule_allowance_depleted: NotificationCategory.schedule,
    NotificationType.payment_requested:       NotificationCategory.subscription,
    NotificationType.payment_reminder:        NotificationCategory.subscription,
    NotificationType.payment_received:        NotificationCategory.subscription,
    NotificationType.payment_confirmed:       NotificationCategory.subscription,
    NotificationType.lessons_running_low:     NotificationCategory.subscription,
    NotificationType.subscription_expiring_soon: NotificationCategory.subscription,
    NotificationType.subscription_expired:    NotificationCategory.subscription,
    NotificationType.proposal_received:       NotificationCategory.subscription,
    NotificationType.proposal_reminder_24h:   NotificationCategory.subscription,
    NotificationType.proposal_reminder_48h:   NotificationCategory.subscription,
    NotificationType.proposal_reminder_72h:   NotificationCategory.subscription,
    NotificationType.proposal_accepted:       NotificationCategory.subscription,
    NotificationType.proposal_expired:        NotificationCategory.subscription,
    NotificationType.new_student_registered:  NotificationCategory.announcement,
    NotificationType.trial_booking_request:   NotificationCategory.announcement,
    NotificationType.review_received:         NotificationCategory.announcement,
    NotificationType.connection_request_received: NotificationCategory.announcement,
    NotificationType.connection_request_accepted: NotificationCategory.announcement,
    NotificationType.connection_request_rejected: NotificationCategory.announcement,
    NotificationType.connection_established:  NotificationCategory.announcement,
    NotificationType.connection_disconnected: NotificationCategory.announcement,
    NotificationType.general_announcement:    NotificationCategory.announcement,
    NotificationType.student_practice_report: NotificationCategory.announcement,
    NotificationType.practice_reminder:       NotificationCategory.practice,
    NotificationType.practice_assigned:       NotificationCategory.practice,
    NotificationType.streak_warning:          NotificationCategory.practice,
    NotificationType.streak_milestone:        NotificationCategory.practice,
    NotificationType.weekly_goal_achieved:    NotificationCategory.practice,
    NotificationType.recording_feedback_received: NotificationCategory.practice,
    NotificationType.inactivity_reminder_7d:  NotificationCategory.practice,
    NotificationType.inactivity_reminder_14d: NotificationCategory.practice,
    NotificationType.win_back_offer_30d:      NotificationCategory.marketing,
}

# DND 우회 알림 (카테고리·마스터 스위치·방해금지 모두 무시)
DND_BYPASS_TYPES: set[NotificationType] = {
    NotificationType.lesson_starting,
    NotificationType.lesson_cancelled,
    NotificationType.noshow_warning,
    NotificationType.noshow_confirmed,
}
```

---

## 5. FCM 토픽 관리

### 5.1 토픽 명명 규칙

```
{category}_{userId}

예시:
  lesson_123
  schedule_123
  subscription_123
  announcement_123
  practice_123
  marketing_123
```

### 5.2 토픽 구독 관리 흐름

```
설정 저장 시:
  카테고리 ON → FCM.subscribeToTopic("{category}_{userId}")
  카테고리 OFF → FCM.unsubscribeFromTopic("{category}_{userId}")
  마스터 OFF → 모든 카테고리 토픽 구독 해제
  마스터 ON → 개별 카테고리 설정에 따라 재구독

앱 최초 설치 / 로그인 시:
  기본값으로 lesson/schedule/subscription/announcement/practice 구독
  marketing은 구독 안 함
```

### 5.3 Flutter FCM 토픽 유틸리티

```dart
// frontend/lib/features/notifications/domain/services/fcm_topic_manager.dart

class FcmTopicManager {
  static Future<void> syncTopics(
    String userId,
    NotificationPreferences prefs,
  ) async {
    for (final category in NotificationCategory.values) {
      final topicName = '${category.topicKey}_$userId';
      final isEnabled = prefs.allPushEnabled && _isCategoryEnabled(prefs, category);

      if (isEnabled) {
        await FirebaseMessaging.instance.subscribeToTopic(topicName);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topicName);
      }
    }
  }

  static bool _isCategoryEnabled(
    NotificationPreferences prefs,
    NotificationCategory category,
  ) => switch (category) {
    NotificationCategory.lesson       => prefs.lessonEnabled,
    NotificationCategory.schedule     => prefs.scheduleEnabled,
    NotificationCategory.subscription => prefs.subscriptionEnabled,
    NotificationCategory.announcement => prefs.announcementEnabled,
    NotificationCategory.practice     => prefs.practiceEnabled,
    NotificationCategory.marketing    => prefs.marketingEnabled,
  };
}
```

---

## 6. UI 설계

### 6.1 화면 진입 경로

```
프로필 탭 → 설정 → 알림 설정
```

라우터 경로: `/settings/notifications`

### 6.2 화면 구조 와이어프레임

```
┌─────────────────────────────────────┐
│  ← 알림 설정                          │
├─────────────────────────────────────┤
│                                     │
│  ┌── 전체 설정 ───────────────────┐  │
│  │  푸시 알림 전체              ●  │  │  ← 마스터 스위치 (기본 ON)
│  └───────────────────────────────┘  │
│                                     │
│  ─────────────────────────────────  │
│  알림 카테고리                        │
│  ─────────────────────────────────  │
│                                     │
│  ┌── 레슨 알림 ──────────────────┐  │
│  │  레슨 시작 전 알림, 완료 확인   │  │  ← 설명 텍스트
│  │                           ●  │  │  ← 카테고리 토글
│  │  ⓘ 레슨 시작/취소 알림은      │  │
│  │    항상 수신됩니다             │  │  ← DND 우회 안내 (lesson만)
│  └───────────────────────────────┘  │
│                                     │
│  ┌── 스케줄 변경 ─────────────────┐  │
│  │  시간 변경 요청, 승인/거절      │  │
│  │                           ●  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌── 수강권 ──────────────────────┐  │
│  │  만료 임박, 갱신 제안, 입금 확인 │  │
│  │                           ●  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌── 공지 ────────────────────────┐  │
│  │  선생님 공지, 연결 요청         │  │
│  │                           ●  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌── 연습 리마인더 ───────────────┐  │
│  │  연습 알림, 목표 달성          │  │
│  │                           ●  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌── 마케팅 ──────────────────────┐  │
│  │  새 기능 안내, 이벤트          │  │
│  │                           ○  │  │  ← 기본 OFF
│  └───────────────────────────────┘  │
│                                     │
│  ─────────────────────────────────  │
│  방해금지 시간대                      │
│  ─────────────────────────────────  │
│                                     │
│  ┌── 방해금지 ────────────────────┐  │
│  │  방해금지 시간대              ●  │  │  ← DND 마스터 토글
│  │  ─────────────────────────── │  │
│  │  시작  [22:00]                │  │  ← 시간 선택 (탭하면 타임피커)
│  │  종료  [08:00]                │  │
│  │                              │  │
│  │  ⓘ 레슨 시작, 취소 알림은     │  │
│  │    방해금지 시간에도 수신됩니다  │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

### 6.3 마스터 스위치 동작

| 상태 | 카테고리 토글 | DND 섹션 |
|------|-------------|---------|
| 마스터 ON | 활성화 (개별 조작 가능) | 표시 |
| 마스터 OFF | 비활성화 (회색 처리) | 숨김 |

마스터 OFF 시 카테고리 개별 상태는 **메모리에 유지**. 마스터 ON 복귀 시 이전 설정 복원.

### 6.4 UX 규칙

- **Notebook × Score 스타일**: `SwitchListTile` + `NotebookGlyph` 아이콘 조합
- **즉시 저장**: 토글 변경 즉시 API 호출 (디바운스 300ms)
- **낙관적 업데이트**: UI를 먼저 반영, 실패 시 롤백 + snackbar 오류 표시
- **AppColors만 사용**: 활성 토글 = `AppColors.primary`, 비활성 = `AppColors.surfaceVariant`
- **AppStrings 텍스트**: 모든 UI 문자열 상수화

---

## 7. Provider 설계

```dart
// frontend/lib/features/notifications/presentation/providers/notification_preferences_providers.dart

@riverpod
Future<NotificationPreferences> notificationPreferences(Ref ref) async {
  final repo = ref.watch(notificationPreferencesRepositoryProvider);
  return repo.getPreferences();
}

@riverpod
class NotificationPreferencesNotifier extends _$NotificationPreferencesNotifier {
  @override
  Future<NotificationPreferences> build() async {
    final repo = ref.read(notificationPreferencesRepositoryProvider);
    return repo.getPreferences();
  }

  /// 단일 카테고리 토글
  Future<void> toggleCategory(NotificationCategory category, bool enabled) async {
    final current = await future;
    final updated = _applyCategory(current, category, enabled);
    state = AsyncData(updated);  // 낙관적 업데이트
    try {
      final repo = ref.read(notificationPreferencesRepositoryProvider);
      final saved = await repo.updatePreferences(updated);
      state = AsyncData(saved);
      await FcmTopicManager.syncTopics(ref.read(currentUserIdProvider), saved);
    } catch (e) {
      state = AsyncData(current);  // 롤백
      rethrow;
    }
  }

  /// 마스터 스위치
  Future<void> toggleMaster(bool enabled) async {
    final current = await future;
    final updated = current.copyWith(allPushEnabled: enabled);
    state = AsyncData(updated);
    try {
      final repo = ref.read(notificationPreferencesRepositoryProvider);
      final saved = await repo.updatePreferences(updated);
      state = AsyncData(saved);
      await FcmTopicManager.syncTopics(ref.read(currentUserIdProvider), saved);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// 방해금지 시간대 업데이트
  Future<void> updateQuietHours({
    bool? enabled,
    TimeOfDayValue? start,
    TimeOfDayValue? end,
  }) async {
    final current = await future;
    final updated = current.copyWith(
      quietHoursEnabled: enabled ?? current.quietHoursEnabled,
      quietHoursStart: start ?? current.quietHoursStart,
      quietHoursEnd: end ?? current.quietHoursEnd,
    );
    state = AsyncData(updated);
    try {
      final repo = ref.read(notificationPreferencesRepositoryProvider);
      final saved = await repo.updatePreferences(updated);
      state = AsyncData(saved);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  NotificationPreferences _applyCategory(
    NotificationPreferences prefs,
    NotificationCategory category,
    bool enabled,
  ) => switch (category) {
    NotificationCategory.lesson       => prefs.copyWith(lessonEnabled: enabled),
    NotificationCategory.schedule     => prefs.copyWith(scheduleEnabled: enabled),
    NotificationCategory.subscription => prefs.copyWith(subscriptionEnabled: enabled),
    NotificationCategory.announcement => prefs.copyWith(announcementEnabled: enabled),
    NotificationCategory.practice     => prefs.copyWith(practiceEnabled: enabled),
    NotificationCategory.marketing    => prefs.copyWith(marketingEnabled: enabled),
  };
}
```

---

## 8. Repository 인터페이스

```dart
// frontend/lib/features/notifications/domain/repositories/notification_preferences_repository.dart

abstract class NotificationPreferencesRepository {
  Future<NotificationPreferences> getPreferences();
  Future<NotificationPreferences> updatePreferences(NotificationPreferences prefs);
}
```

구현체:
- `MockNotificationPreferencesRepository`: Hive 로컬 저장
- `RemoteNotificationPreferencesRepository`: API 호출

---

## 9. AppStrings 추가 항목

```dart
// 알림 설정 화면
static const notifSettingsTitle = '알림 설정';
static const notifMasterSwitch = '푸시 알림 전체';
static const notifCategorySection = '알림 카테고리';
static const notifQuietHoursSection = '방해금지 시간대';
static const notifQuietHoursLabel = '방해금지 시간대';
static const notifQuietHoursStart = '시작';
static const notifQuietHoursEnd = '종료';
static const notifQuietHoursBypassHint = '레슨 시작, 취소 알림은 방해금지 시간에도 수신됩니다';
static const notifCategoryLessonBypassHint = '레슨 시작/취소 알림은 항상 수신됩니다';

// 카테고리 이름
static const notifCategoryLesson = '레슨 알림';
static const notifCategorySchedule = '스케줄 변경';
static const notifCategorySubscription = '수강권';
static const notifCategoryAnnouncement = '공지';
static const notifCategoryPractice = '연습 리마인더';
static const notifCategoryMarketing = '마케팅';

// 카테고리 설명
static const notifCategoryLessonDesc = '레슨 시작 전 알림, 완료 확인';
static const notifCategoryScheduleDesc = '시간 변경 요청, 승인/거절';
static const notifCategorySubscriptionDesc = '만료 임박, 갱신 제안, 입금 확인';
static const notifCategoryAnnouncementDesc = '선생님 공지, 연결 요청';
static const notifCategoryPracticeDesc = '연습 알림, 목표 달성';
static const notifCategoryMarketingDesc = '새 기능 안내, 이벤트';
```

---

## 10. 구현 Phase

### Phase 결정 (2026-06-12 출시 준비도 감사 P1-1)

| 범위 | Phase | 사유 |
|------|-------|------|
| 마스터 토글 + 6 카테고리 토글 화면 | **Phase 1.5 (출시 전 필수)** | 설정 메뉴 진입점이 이미 앱에 노출되어 있으나 화면이 없어 #15 플레이스홀더 위반. 알림 폭주 시 사용자가 끌 수단이 푸시 전체 차단뿐이므로 채널 보호 원칙 위배 |
| 알림 설정 Hive 영속화 | Phase 1.5 | 설정 화면과 함께 구현 |
| DND/방해금지 시간대 직접 지정 | Phase 2 | 마스터+카테고리 토글과 분리하여 후속 구현 |
| 알림 빈도 조절 (단계별 슬라이더) | Phase 2 | |
| 카테고리별 리마인더 시간 세부 조정 | Phase 2 | |

### Phase 1.5 구현 단계 — 백엔드 (1-2일)

- [ ] `notification_preferences` DB 테이블 마이그레이션
- [ ] `NotificationPreferences` SQLAlchemy 모델
- [ ] `NotificationPreferencesSchema` Pydantic 스키마
- [ ] `GET /api/v1/users/me/notification-preferences` 엔드포인트
- [ ] `PUT /api/v1/users/me/notification-preferences` 엔드포인트
- [ ] `should_send_push()` 서비스 함수 + `NOTIFICATION_TYPE_CATEGORY_MAP` 등록
- [ ] 신규 사용자 기본값 자동 생성 로직
- [ ] 단위 테스트: GET/PUT API, DND 우회 로직, 방해금지 시간대 필터

### Phase 1.5 구현 단계 — Flutter 엔티티 및 Repository (1일)

- [ ] `NotificationPreferences` freezed 엔티티
- [ ] `NotificationCategory` 열거형
- [ ] `TimeOfDayValue` 래퍼
- [ ] `NotificationPreferencesRepository` 인터페이스
- [ ] `MockNotificationPreferencesRepository` (Hive 저장)
- [ ] `RemoteNotificationPreferencesRepository` (API 연동)
- [ ] `build_runner` 코드 생성

### Phase 1.5 구현 단계 — Provider 및 FCM 토픽 (1일)

- [ ] `notificationPreferencesProvider`
- [ ] `NotificationPreferencesNotifier`
- [ ] `FcmTopicManager.syncTopics()`
- [ ] 앱 최초 로그인 시 기본 토픽 구독 로직 연결

### Phase 1.5 구현 단계 — UI (1-2일)

- [ ] `NotificationSettingsScreen` 화면 생성
- [ ] 마스터 스위치 위젯 (비활성 시 카테고리 섹션 회색 처리)
- [ ] `NotificationCategoryTile` 재사용 위젯 (SwitchListTile + 설명 + DND 우회 안내)
- [ ] 방해금지 시간대 섹션은 Phase 2로 이월 — Phase 1.5 UI 범위에서 제외
- [ ] 라우터 `/settings/notifications` 경로 등록
- [ ] 프로필 탭 → 설정 메뉴에 '알림 설정' 항목 추가
- [ ] widget smoke test

### Phase 1.5 구현 단계 — 검증 (0.5일)

- [ ] 카테고리 OFF → 해당 FCM 토픽 구독 해제 확인
- [ ] 마스터 OFF → 모든 토픽 구독 해제 확인
- [ ] DND 우회 알림이 방해금지 시간에도 전송되는지 확인
- [ ] 신규 사용자 기본값 확인 (marketing OFF)
- [ ] `flutter analyze` 0 오류

---

## 11. 기존 스펙과의 관계

이 스펙은 `notification_master.md`의 **설정 섹션을 확장**한다.

| 기존 엔티티 | 이 스펙의 변경 |
|------------|--------------|
| `StudentNotificationSettings` | `NotificationPreferences`로 통합 대체 (카테고리 기반) |
| `TeacherNotificationSettings` | `NotificationPreferences`로 통합 대체 (역할 구분 없음) |
| `dndEnabled/dndStart/dndEnd` | `NotificationPreferences.quietHoursEnabled/Start/End`로 이전 |

> **마이그레이션 주의**: 기존 `StudentNotificationSettings`, `TeacherNotificationSettings` 엔티티는 이 스펙 구현 후 deprecated 처리. 이전 설정값을 `NotificationPreferences` 기본값으로 자동 마이그레이션한다.
