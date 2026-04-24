/// 수강권 만료 알림 설정
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §3.4
///
/// 선생님 기준: 활성 수강권의 만료일을 기준으로 D-14 / D-7 / D-1 / D-0 시점에
/// in-app + push 알림을 트리거한다. master 토글과 개별 offset 토글로 제어한다.
class SubscriptionExpiryReminderSettings {
  /// 마스터 스위치 — OFF 이면 모든 offset 무시
  final bool enabled;

  /// D-14 (만료 14일 전)
  final bool remindAtD14;

  /// D-7 (만료 7일 전)
  final bool remindAtD7;

  /// D-1 (만료 하루 전)
  final bool remindAtD1;

  /// D-0 (만료 당일)
  final bool remindAtD0;

  const SubscriptionExpiryReminderSettings({
    this.enabled = true,
    this.remindAtD14 = true,
    this.remindAtD7 = true,
    this.remindAtD1 = true,
    this.remindAtD0 = true,
  });

  static const defaults = SubscriptionExpiryReminderSettings();

  SubscriptionExpiryReminderSettings copyWith({
    bool? enabled,
    bool? remindAtD14,
    bool? remindAtD7,
    bool? remindAtD1,
    bool? remindAtD0,
  }) {
    return SubscriptionExpiryReminderSettings(
      enabled: enabled ?? this.enabled,
      remindAtD14: remindAtD14 ?? this.remindAtD14,
      remindAtD7: remindAtD7 ?? this.remindAtD7,
      remindAtD1: remindAtD1 ?? this.remindAtD1,
      remindAtD0: remindAtD0 ?? this.remindAtD0,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'remindAtD14': remindAtD14,
    'remindAtD7': remindAtD7,
    'remindAtD1': remindAtD1,
    'remindAtD0': remindAtD0,
  };

  factory SubscriptionExpiryReminderSettings.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubscriptionExpiryReminderSettings(
      enabled: json['enabled'] ?? true,
      remindAtD14: json['remindAtD14'] ?? true,
      remindAtD7: json['remindAtD7'] ?? true,
      remindAtD1: json['remindAtD1'] ?? true,
      remindAtD0: json['remindAtD0'] ?? true,
    );
  }
}
