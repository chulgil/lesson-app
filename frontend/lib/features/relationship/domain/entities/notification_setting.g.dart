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
      userId: json['userId'] as String,
      targetUserId: json['targetUserId'] as String,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      practiceShareEnabled: json['practiceShareEnabled'] as bool? ?? true,
      lessonReminderEnabled: json['lessonReminderEnabled'] as bool? ?? true,
      paymentReminderEnabled: json['paymentReminderEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$NotificationSettingToJson(
        NotificationSetting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'targetUserId': instance.targetUserId,
      'pushEnabled': instance.pushEnabled,
      'practiceShareEnabled': instance.practiceShareEnabled,
      'lessonReminderEnabled': instance.lessonReminderEnabled,
      'paymentReminderEnabled': instance.paymentReminderEnabled,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
