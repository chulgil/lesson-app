// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_setting.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSettingAdapter extends TypeAdapter<NotificationSetting> {
  @override
  final int typeId = 92;

  @override
  NotificationSetting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSetting(
      id: fields[0] as String,
      userId: fields[1] as String,
      targetUserId: fields[2] as String,
      pushEnabled: fields[3] as bool,
      practiceShareEnabled: fields[4] as bool,
      lessonReminderEnabled: fields[5] as bool,
      paymentReminderEnabled: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSetting obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.targetUserId)
      ..writeByte(3)
      ..write(obj.pushEnabled)
      ..writeByte(4)
      ..write(obj.practiceShareEnabled)
      ..writeByte(5)
      ..write(obj.lessonReminderEnabled)
      ..writeByte(6)
      ..write(obj.paymentReminderEnabled)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
