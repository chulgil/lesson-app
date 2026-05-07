// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSetting _$NotificationSettingFromJson(Map<String, dynamic> json) =>
    NotificationSetting(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      targetUserId: json['target_user_id'] as String,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      practiceShareEnabled: json['practice_share_enabled'] as bool? ?? true,
      lessonReminderEnabled: json['lesson_reminder_enabled'] as bool? ?? true,
      paymentReminderEnabled: json['payment_reminder_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$NotificationSettingToJson(
        NotificationSetting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'target_user_id': instance.targetUserId,
      'push_enabled': instance.pushEnabled,
      'practice_share_enabled': instance.practiceShareEnabled,
      'lesson_reminder_enabled': instance.lessonReminderEnabled,
      'payment_reminder_enabled': instance.paymentReminderEnabled,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
