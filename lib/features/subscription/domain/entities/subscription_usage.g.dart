// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_usage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionUsageAdapter extends TypeAdapter<SubscriptionUsage> {
  @override
  final int typeId = 63;

  @override
  SubscriptionUsage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionUsage(
      id: fields[0] as String,
      subscriptionId: fields[1] as String,
      lessonId: fields[2] as String?,
      usedAt: fields[3] as DateTime,
      teacherName: fields[4] as String?,
      instrument: fields[5] as String?,
      note: fields[6] as String?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionUsage obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subscriptionId)
      ..writeByte(2)
      ..write(obj.lessonId)
      ..writeByte(3)
      ..write(obj.usedAt)
      ..writeByte(4)
      ..write(obj.teacherName)
      ..writeByte(5)
      ..write(obj.instrument)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionUsageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionUsage _$SubscriptionUsageFromJson(Map<String, dynamic> json) =>
    SubscriptionUsage(
      id: json['id'] as String,
      subscriptionId: json['subscriptionId'] as String,
      lessonId: json['lessonId'] as String?,
      usedAt: DateTime.parse(json['usedAt'] as String),
      teacherName: json['teacherName'] as String?,
      instrument: json['instrument'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SubscriptionUsageToJson(SubscriptionUsage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subscriptionId': instance.subscriptionId,
      'lessonId': instance.lessonId,
      'usedAt': instance.usedAt.toIso8601String(),
      'teacherName': instance.teacherName,
      'instrument': instance.instrument,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
    };
