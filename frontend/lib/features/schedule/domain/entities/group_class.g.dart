// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupClass _$GroupClassFromJson(Map<String, dynamic> json) => GroupClass(
  id: json['id'] as String,
  teacherId: json['teacher_id'] as String,
  organizationId: json['organization_id'] as String?,
  name: json['name'] as String,
  description: json['description'] as String?,
  type: $enumDecode(_$GroupClassTypeEnumMap, json['type']),
  maxCapacity: (json['max_capacity'] as num).toInt(),
  waitlistCapacity: (json['waitlist_capacity'] as num?)?.toInt(),
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  bookingDeadlineMinutes:
      (json['booking_deadline_minutes'] as num?)?.toInt() ?? 60,
  cancelDeadlineMinutes:
      (json['cancel_deadline_minutes'] as num?)?.toInt() ?? 1440,
  noShowPolicy:
      $enumDecodeNullable(_$NoShowPolicyEnumMap, json['no_show_policy']) ??
      NoShowPolicy.deduct,
  maxNoShowCount: (json['max_no_show_count'] as num?)?.toInt(),
  repeatDaysOfWeek:
      (json['repeat_days_of_week'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
  repeatTimeOfDay: json['repeat_time_of_day'] as String?,
  instrument: json['instrument'] as String?,
  pricePerSession: (json['price_per_session'] as num?)?.toInt(),
  isActive: json['is_active'] as bool? ?? true,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$GroupClassToJson(GroupClass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacher_id': instance.teacherId,
      'organization_id': instance.organizationId,
      'name': instance.name,
      'description': instance.description,
      'type': _$GroupClassTypeEnumMap[instance.type]!,
      'max_capacity': instance.maxCapacity,
      'waitlist_capacity': instance.waitlistCapacity,
      'duration_minutes': instance.durationMinutes,
      'booking_deadline_minutes': instance.bookingDeadlineMinutes,
      'cancel_deadline_minutes': instance.cancelDeadlineMinutes,
      'no_show_policy': _$NoShowPolicyEnumMap[instance.noShowPolicy]!,
      'max_no_show_count': instance.maxNoShowCount,
      'repeat_days_of_week': instance.repeatDaysOfWeek,
      'repeat_time_of_day': instance.repeatTimeOfDay,
      'instrument': instance.instrument,
      'price_per_session': instance.pricePerSession,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$GroupClassTypeEnumMap = {
  GroupClassType.regular: 'regular',
  GroupClassType.dropIn: 'dropIn',
};

const _$NoShowPolicyEnumMap = {
  NoShowPolicy.deduct: 'deduct',
  NoShowPolicy.noDeduct: 'noDeduct',
};
