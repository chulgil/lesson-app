// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'makeup_lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MakeupLesson _$MakeupLessonFromJson(Map<String, dynamic> json) => MakeupLesson(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      originalLessonId: json['original_lesson_id'] as String?,
      scheduledLessonId: json['scheduled_lesson_id'] as String?,
      status: $enumDecodeNullable(_$MakeupStatusEnumMap, json['status']) ??
          MakeupStatus.pending,
      reason: $enumDecode(_$MakeupReasonEnumMap, json['reason']),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.parse(json['scheduled_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$MakeupLessonToJson(MakeupLesson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'teacher_id': instance.teacherId,
      'original_lesson_id': instance.originalLessonId,
      'scheduled_lesson_id': instance.scheduledLessonId,
      'status': _$MakeupStatusEnumMap[instance.status]!,
      'reason': _$MakeupReasonEnumMap[instance.reason]!,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'scheduled_at': instance.scheduledAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'note': instance.note,
    };

const _$MakeupStatusEnumMap = {
  MakeupStatus.pending: 'pending',
  MakeupStatus.scheduled: 'scheduled',
  MakeupStatus.completed: 'completed',
  MakeupStatus.expired: 'expired',
  MakeupStatus.waived: 'waived',
};

const _$MakeupReasonEnumMap = {
  MakeupReason.studentCancellation: 'studentCancellation',
  MakeupReason.teacherCancellation: 'teacherCancellation',
  MakeupReason.noShowReschedule: 'noShowReschedule',
  MakeupReason.other: 'other',
};
