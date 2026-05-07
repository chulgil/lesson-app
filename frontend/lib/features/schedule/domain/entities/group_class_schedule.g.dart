// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupClassSchedule _$GroupClassScheduleFromJson(Map<String, dynamic> json) =>
    GroupClassSchedule(
      id: json['id'] as String,
      groupClassId: json['group_class_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: $enumDecodeNullable(_$ScheduleStatusEnumMap, json['status']) ??
          ScheduleStatus.open,
      currentBookings: (json['current_bookings'] as num?)?.toInt() ?? 0,
      waitlistCount: (json['waitlist_count'] as num?)?.toInt() ?? 0,
      maxCapacity: (json['max_capacity'] as num).toInt(),
      waitlistCapacity: (json['waitlist_capacity'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$GroupClassScheduleToJson(GroupClassSchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_class_id': instance.groupClassId,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime.toIso8601String(),
      'status': _$ScheduleStatusEnumMap[instance.status]!,
      'current_bookings': instance.currentBookings,
      'waitlist_count': instance.waitlistCount,
      'max_capacity': instance.maxCapacity,
      'waitlist_capacity': instance.waitlistCapacity,
      'notes': instance.notes,
      'cancel_reason': instance.cancelReason,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$ScheduleStatusEnumMap = {
  ScheduleStatus.open: 'open',
  ScheduleStatus.full: 'full',
  ScheduleStatus.closed: 'closed',
  ScheduleStatus.cancelled: 'cancelled',
  ScheduleStatus.completed: 'completed',
  ScheduleStatus.inProgress: 'inProgress',
};
