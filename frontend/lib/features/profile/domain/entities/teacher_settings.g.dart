// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherSettings _$TeacherSettingsFromJson(Map<String, dynamic> json) =>
    TeacherSettings(
      id: json['id'] as String,
      instruments: (json['instruments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      defaultLessonDuration: (json['default_lesson_duration'] as num?)?.toInt(),
      lessonDurationMinutes: (json['lesson_duration_minutes'] as num?)?.toInt(),
      customLessonDurations: (json['custom_lesson_durations'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      disabledDurations: (json['disabled_durations'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      breakTimeBetweenLessons:
          (json['break_time_between_lessons'] as num?)?.toInt() ?? 0,
      minBookingHours: (json['min_booking_hours'] as num?)?.toInt() ?? 0,
      lessonPriceTable:
          (json['lesson_price_table'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Map<String, int>.from(e as Map)),
      ),
      trialLessonFree: json['trial_lesson_free'] as bool? ?? false,
      bookingGuidanceMessage: json['booking_guidance_message'] as String?,
    );

Map<String, dynamic> _$TeacherSettingsToJson(TeacherSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'instruments': instance.instruments,
      'default_lesson_duration': instance.defaultLessonDuration,
      'custom_lesson_durations': instance.customLessonDurations,
      'disabled_durations': instance.disabledDurations,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'break_time_between_lessons': instance.breakTimeBetweenLessons,
      'min_booking_hours': instance.minBookingHours,
      'lesson_price_table': instance.lessonPriceTable,
      'trial_lesson_free': instance.trialLessonFree,
      'booking_guidance_message': instance.bookingGuidanceMessage,
      'lesson_duration_minutes': instance.lessonDurationMinutes,
    };
