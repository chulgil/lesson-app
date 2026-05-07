// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_usage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionUsage _$SubscriptionUsageFromJson(Map<String, dynamic> json) =>
    SubscriptionUsage(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      lessonId: json['lesson_id'] as String?,
      usedAt: DateTime.parse(json['used_at'] as String),
      teacherName: json['teacher_name'] as String?,
      instrument: json['instrument'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      usageType: $enumDecodeNullable(_$UsageTypeEnumMap, json['usage_type']) ??
          UsageType.normal,
      deducted: json['deducted'] as bool? ?? true,
    );

Map<String, dynamic> _$SubscriptionUsageToJson(SubscriptionUsage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subscription_id': instance.subscriptionId,
      'lesson_id': instance.lessonId,
      'used_at': instance.usedAt.toIso8601String(),
      'teacher_name': instance.teacherName,
      'instrument': instance.instrument,
      'note': instance.note,
      'created_at': instance.createdAt.toIso8601String(),
      'usage_type': _$UsageTypeEnumMap[instance.usageType]!,
      'deducted': instance.deducted,
    };

const _$UsageTypeEnumMap = {
  UsageType.normal: 'normal',
  UsageType.lateCancellation: 'lateCancellation',
  UsageType.studentAbsent: 'studentAbsent',
  UsageType.rescheduled: 'rescheduled',
};
