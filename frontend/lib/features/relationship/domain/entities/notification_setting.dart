import 'package:json_annotation/json_annotation.dart';

part 'notification_setting.g.dart';

/// Lesson notification and sharing settings.
///
/// Separate from relationship status - user-controlled settings.
/// See: docs/specs/invite/subscription_based_relationship.md
@JsonSerializable()
class NotificationSetting {
  final String id;

  final String userId;

  /// Target user ID (the other party in the relationship)
  final String targetUserId;

  /// Push notification enabled
  final bool pushEnabled;

  /// Practice status sharing (student only)
  /// - Only shared when relationship is active
  /// - Not shared when expired/past regardless of this setting
  final bool practiceShareEnabled;

  /// Lesson reminder notification
  final bool lessonReminderEnabled;

  /// Payment notification
  final bool paymentReminderEnabled;

  final DateTime createdAt;

  final DateTime updatedAt;

  NotificationSetting({
    required this.id,
    required this.userId,
    required this.targetUserId,
    this.pushEnabled = true,
    this.practiceShareEnabled = true,
    this.lessonReminderEnabled = true,
    this.paymentReminderEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create with default settings
  factory NotificationSetting.defaultSetting({
    required String userId,
    required String targetUserId,
  }) {
    final now = DateTime.now();
    return NotificationSetting(
      id: 'ns_${now.millisecondsSinceEpoch}',
      userId: userId,
      targetUserId: targetUserId,
      pushEnabled: true,
      practiceShareEnabled: true,
      lessonReminderEnabled: true,
      paymentReminderEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  NotificationSetting copyWith({
    String? id,
    String? userId,
    String? targetUserId,
    bool? pushEnabled,
    bool? practiceShareEnabled,
    bool? lessonReminderEnabled,
    bool? paymentReminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSetting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetUserId: targetUserId ?? this.targetUserId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      practiceShareEnabled: practiceShareEnabled ?? this.practiceShareEnabled,
      lessonReminderEnabled:
          lessonReminderEnabled ?? this.lessonReminderEnabled,
      paymentReminderEnabled:
          paymentReminderEnabled ?? this.paymentReminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationSetting.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSettingToJson(this);

  @override
  String toString() {
    return 'NotificationSetting(id: $id, userId: $userId, '
        'targetUserId: $targetUserId, pushEnabled: $pushEnabled)';
  }
}
