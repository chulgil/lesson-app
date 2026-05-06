// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_policy.dart';

LessonPolicy _$LessonPolicyFromJson(Map<String, dynamic> json) => LessonPolicy(
  id: json['id'] as String,
  lessonClassId: json['lesson_class_id'] as String?,
  teacherId: json['teacher_id'] as String,
  minCancelHours: (json['min_cancel_hours'] as num?)?.toInt() ?? 4,
  maxChangesPerMonth: (json['max_changes_per_month'] as num?)?.toInt() ?? 2,
  allowSameDayCancel: json['allow_same_day_cancel'] as bool? ?? false,
  lateCancelDeadline: json['late_cancel_deadline'] as String?,
  deductLessonOnNoShow: json['deduct_lesson_on_no_show'] as bool? ?? true,
  gracePeriodMinutes: (json['grace_period_minutes'] as num?)?.toInt() ?? 15,
  allowCarryover: json['allow_carryover'] as bool? ?? true,
  maxCarryoverLessons: (json['max_carryover_lessons'] as num?)?.toInt() ?? 1,
  carryoverPeriodMonths:
      (json['carryover_period_months'] as num?)?.toInt() ?? 1,
  fullRefundDays: (json['full_refund_days'] as num?)?.toInt() ?? 1,
  partialRefundRatio:
      (json['partial_refund_ratio'] as num?)?.toDouble() ?? 0.67,
  halfwayRefundRatio: (json['halfway_refund_ratio'] as num?)?.toDouble() ?? 0.0,
  noShowRefundRatio: (json['no_show_refund_ratio'] as num?)?.toDouble() ?? 0.67,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$LessonPolicyToJson(LessonPolicy instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lesson_class_id': instance.lessonClassId,
      'teacher_id': instance.teacherId,
      'min_cancel_hours': instance.minCancelHours,
      'max_changes_per_month': instance.maxChangesPerMonth,
      'allow_same_day_cancel': instance.allowSameDayCancel,
      'late_cancel_deadline': instance.lateCancelDeadline,
      'deduct_lesson_on_no_show': instance.deductLessonOnNoShow,
      'grace_period_minutes': instance.gracePeriodMinutes,
      'allow_carryover': instance.allowCarryover,
      'max_carryover_lessons': instance.maxCarryoverLessons,
      'carryover_period_months': instance.carryoverPeriodMonths,
      'full_refund_days': instance.fullRefundDays,
      'partial_refund_ratio': instance.partialRefundRatio,
      'halfway_refund_ratio': instance.halfwayRefundRatio,
      'no_show_refund_ratio': instance.noShowRefundRatio,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
