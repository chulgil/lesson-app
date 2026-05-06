// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeGoal _$PracticeGoalFromJson(Map<String, dynamic> json) => PracticeGoal(
  id: json['id'] as String,
  studentId: json['student_id'] as String,
  dailyTimeMinutes: (json['daily_time_minutes'] as num?)?.toInt(),
  dailySectionCount: (json['daily_section_count'] as num?)?.toInt(),
  weeklyTimeMinutes: (json['weekly_time_minutes'] as num?)?.toInt(),
  weeklyDayCount: (json['weekly_day_count'] as num?)?.toInt(),
  isActive: json['is_active'] as bool? ?? true,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PracticeGoalToJson(PracticeGoal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'daily_time_minutes': instance.dailyTimeMinutes,
      'daily_section_count': instance.dailySectionCount,
      'weekly_time_minutes': instance.weeklyTimeMinutes,
      'weekly_day_count': instance.weeklyDayCount,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
