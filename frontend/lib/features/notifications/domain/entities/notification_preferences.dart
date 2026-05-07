/// Per-category notification toggle preferences.
///
/// Stores the user's fine-grained push notification settings
/// as defined in `docs/specs/notification/push_notification_settings_spec.md`.
class NotificationPreferences {
  /// Global kill switch — when false, all category toggles are ignored.
  final bool masterEnabled;

  /// 레슨 알림: 레슨 시작, 완료, 예약, 취소.
  final bool lessonEnabled;

  /// 스케줄 변경: 시간 변경 요청, 승인/거절.
  final bool scheduleEnabled;

  /// 수강권: 만료 임박, 갱신 제안, 입금.
  final bool subscriptionEnabled;

  /// 공지: 선생님 휴강, 일반 공지.
  final bool announcementEnabled;

  /// 연습 리마인더: 연습 알림, 목표 달성.
  final bool practiceEnabled;

  /// 마케팅: 새 기능 안내, 이벤트. Default OFF per spec.
  final bool marketingEnabled;

  /// Do-Not-Disturb start hour (0–23). Null = DND disabled.
  final int? quietStartHour;

  /// Do-Not-Disturb end hour (0–23). Null = DND disabled.
  final int? quietEndHour;

  const NotificationPreferences({
    this.masterEnabled = true,
    this.lessonEnabled = true,
    this.scheduleEnabled = true,
    this.subscriptionEnabled = true,
    this.announcementEnabled = true,
    this.practiceEnabled = true,
    this.marketingEnabled = false,
    this.quietStartHour,
    this.quietEndHour,
  });

  /// Default preferences for a new user.
  static const defaults = NotificationPreferences();

  NotificationPreferences copyWith({
    bool? masterEnabled,
    bool? lessonEnabled,
    bool? scheduleEnabled,
    bool? subscriptionEnabled,
    bool? announcementEnabled,
    bool? practiceEnabled,
    bool? marketingEnabled,
    Object? quietStartHour = _absent,
    Object? quietEndHour = _absent,
  }) {
    return NotificationPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      lessonEnabled: lessonEnabled ?? this.lessonEnabled,
      scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
      subscriptionEnabled: subscriptionEnabled ?? this.subscriptionEnabled,
      announcementEnabled: announcementEnabled ?? this.announcementEnabled,
      practiceEnabled: practiceEnabled ?? this.practiceEnabled,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
      quietStartHour: identical(quietStartHour, _absent)
          ? this.quietStartHour
          : quietStartHour as int?,
      quietEndHour: identical(quietEndHour, _absent)
          ? this.quietEndHour
          : quietEndHour as int?,
    );
  }

  /// Whether DND is currently enabled (both hours set).
  bool get isDndEnabled => quietStartHour != null && quietEndHour != null;

  /// Whether the current time falls within the DND window.
  bool get isCurrentlyInDnd {
    if (!isDndEnabled) return false;
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = quietStartHour! * 60;
    final endMinutes = quietEndHour! * 60;
    // Handle midnight crossover (e.g., 22:00–08:00)
    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  /// Returns true if the given category is effectively enabled
  /// (master switch AND category switch both on).
  bool isCategoryEnabled(NotificationCategory category) {
    if (!masterEnabled) return false;
    return switch (category) {
      NotificationCategory.lesson => lessonEnabled,
      NotificationCategory.schedule => scheduleEnabled,
      NotificationCategory.subscription => subscriptionEnabled,
      NotificationCategory.announcement => announcementEnabled,
      NotificationCategory.practice => practiceEnabled,
      NotificationCategory.marketing => marketingEnabled,
    };
  }

  Map<String, dynamic> toJson() => {
        'masterEnabled': masterEnabled,
        'lessonEnabled': lessonEnabled,
        'scheduleEnabled': scheduleEnabled,
        'subscriptionEnabled': subscriptionEnabled,
        'announcementEnabled': announcementEnabled,
        'practiceEnabled': practiceEnabled,
        'marketingEnabled': marketingEnabled,
        'quietStartHour': quietStartHour,
        'quietEndHour': quietEndHour,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      masterEnabled: (json['masterEnabled'] as bool?) ?? true,
      lessonEnabled: (json['lessonEnabled'] as bool?) ?? true,
      scheduleEnabled: (json['scheduleEnabled'] as bool?) ?? true,
      subscriptionEnabled: (json['subscriptionEnabled'] as bool?) ?? true,
      announcementEnabled: (json['announcementEnabled'] as bool?) ?? true,
      practiceEnabled: (json['practiceEnabled'] as bool?) ?? true,
      marketingEnabled: (json['marketingEnabled'] as bool?) ?? false,
      quietStartHour: json['quietStartHour'] as int?,
      quietEndHour: json['quietEndHour'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          masterEnabled == other.masterEnabled &&
          lessonEnabled == other.lessonEnabled &&
          scheduleEnabled == other.scheduleEnabled &&
          subscriptionEnabled == other.subscriptionEnabled &&
          announcementEnabled == other.announcementEnabled &&
          practiceEnabled == other.practiceEnabled &&
          marketingEnabled == other.marketingEnabled &&
          quietStartHour == other.quietStartHour &&
          quietEndHour == other.quietEndHour;

  @override
  int get hashCode => Object.hash(
        masterEnabled,
        lessonEnabled,
        scheduleEnabled,
        subscriptionEnabled,
        announcementEnabled,
        practiceEnabled,
        marketingEnabled,
        quietStartHour,
        quietEndHour,
      );
}

/// Notification categories shown to the user.
enum NotificationCategory {
  lesson,
  schedule,
  subscription,
  announcement,
  practice,
  marketing,
}

// Sentinel value for nullable copyWith fields.
const _absent = Object();
