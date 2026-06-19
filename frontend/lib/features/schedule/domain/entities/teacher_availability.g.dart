// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_availability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherAvailability _$TeacherAvailabilityFromJson(Map<String, dynamic> json) =>
    TeacherAvailability(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      slotDurationMinutes:
          (json['slot_duration_minutes'] as num?)?.toInt() ?? 50,
      weeklySchedules: (json['weekly_schedules'] as List<dynamic>?)
              ?.map((e) => WeeklySchedule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      exceptions: (json['exceptions'] as List<dynamic>?)
              ?.map((e) => TimeException.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      autoGenerateWeeks: (json['auto_generate_weeks'] as num?)?.toInt() ?? 4,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      slotStartInterval: (json['slot_start_interval'] as num?)?.toInt() ?? 60,
      breakTimeBetweenLessons:
          (json['break_time_between_lessons'] as num?)?.toInt() ?? 10,
      minBookingHours: (json['min_booking_hours'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TeacherAvailabilityToJson(
        TeacherAvailability instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacher_id': instance.teacherId,
      'slot_duration_minutes': instance.slotDurationMinutes,
      'weekly_schedules':
          instance.weeklySchedules.map((e) => e.toJson()).toList(),
      'exceptions': instance.exceptions.map((e) => e.toJson()).toList(),
      'auto_generate_weeks': instance.autoGenerateWeeks,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'slot_start_interval': instance.slotStartInterval,
      'break_time_between_lessons': instance.breakTimeBetweenLessons,
      'min_booking_hours': instance.minBookingHours,
    };

WeeklySchedule _$WeeklyScheduleFromJson(Map<String, dynamic> json) =>
    WeeklySchedule(
      id: json['id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$WeeklyScheduleToJson(WeeklySchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };

TimeException _$TimeExceptionFromJson(Map<String, dynamic> json) =>
    TimeException(
      id: json['id'] as String,
      type: $enumDecode(_$ExceptionTypeEnumMap, json['type']),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TimeExceptionToJson(TimeException instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ExceptionTypeEnumMap[instance.type]!,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'reason': instance.reason,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ExceptionTypeEnumMap = {
  ExceptionType.holiday: 'holiday',
  ExceptionType.vacation: 'vacation',
  ExceptionType.additionalSlot: 'additionalSlot',
};
