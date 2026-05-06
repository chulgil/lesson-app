// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonSlot _$LessonSlotFromJson(Map<String, dynamic> json) => LessonSlot(
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );

Map<String, dynamic> _$LessonSlotToJson(LessonSlot instance) =>
    <String, dynamic>{
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
    };
