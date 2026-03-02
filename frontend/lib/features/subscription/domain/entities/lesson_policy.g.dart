// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_policy.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonPolicyAdapter extends TypeAdapter<LessonPolicy> {
  @override
  final int typeId = 70;

  @override
  LessonPolicy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonPolicy(
      id: fields[0] as String,
      lessonClassId: fields[1] as String?,
      teacherId: fields[2] as String,
      minCancelHours: fields[3] as int,
      maxChangesPerMonth: fields[4] as int,
      allowSameDayCancel: fields[5] as bool,
      lateCancelDeadline: fields[6] as String?,
      deductLessonOnNoShow: fields[7] as bool,
      gracePeriodMinutes: fields[8] as int,
      allowCarryover: fields[9] as bool,
      maxCarryoverLessons: fields[10] as int,
      carryoverPeriodMonths: fields[11] as int,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonPolicy obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lessonClassId)
      ..writeByte(2)
      ..write(obj.teacherId)
      ..writeByte(3)
      ..write(obj.minCancelHours)
      ..writeByte(4)
      ..write(obj.maxChangesPerMonth)
      ..writeByte(5)
      ..write(obj.allowSameDayCancel)
      ..writeByte(6)
      ..write(obj.lateCancelDeadline)
      ..writeByte(7)
      ..write(obj.deductLessonOnNoShow)
      ..writeByte(8)
      ..write(obj.gracePeriodMinutes)
      ..writeByte(9)
      ..write(obj.allowCarryover)
      ..writeByte(10)
      ..write(obj.maxCarryoverLessons)
      ..writeByte(11)
      ..write(obj.carryoverPeriodMonths)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonPolicyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      maxCarryoverLessons:
          (json['max_carryover_lessons'] as num?)?.toInt() ?? 1,
      carryoverPeriodMonths:
          (json['carryover_period_months'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
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
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
