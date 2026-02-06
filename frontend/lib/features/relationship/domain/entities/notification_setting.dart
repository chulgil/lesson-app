import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_setting.g.dart';

/// Lesson notification and sharing settings.
///
/// Separate from relationship status - user-controlled settings.
/// See: docs/specs/invite/subscription_based_relationship.md
@HiveType(typeId: 92)
@JsonSerializable()
class NotificationSetting extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  /// Target user ID (the other party in the relationship)
  @HiveField(2)
  final String targetUserId;

  /// Push notification enabled
  @HiveField(3)
  final bool pushEnabled;

  /// Practice status sharing (student only)
  /// - Only shared when relationship is active
  /// - Not shared when expired/past regardless of this setting
  @HiveField(4)
  final bool practiceShareEnabled;

  /// Lesson reminder notification
  @HiveField(5)
  final bool lessonReminderEnabled;

  /// Payment notification
  @HiveField(6)
  final bool paymentReminderEnabled;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
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
