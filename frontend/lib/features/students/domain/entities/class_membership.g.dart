// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_membership.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassMembership _$ClassMembershipFromJson(Map<String, dynamic> json) =>
    ClassMembership(
      id: json['id'] as String,
      lessonClassId: json['lesson_class_id'] as String,
      studentId: json['student_id'] as String,
      instrument: json['instrument'] as String,
      status: $enumDecode(_$MembershipStatusEnumMap, json['status']),
      level: json['level'] as String?,
      monthlyFee: (json['monthly_fee'] as num).toInt(),
      lessonsPerWeek: (json['lessons_per_week'] as num?)?.toInt() ?? 1,
      lessonSlots: (json['lesson_slots'] as List<dynamic>?)
              ?.map((e) => LessonSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lessonDuration: (json['lesson_duration'] as num?)?.toInt() ?? 60,
      notes: json['notes'] as String?,
      lessonLocationId: json['lesson_location_id'] as String?,
      travelTimeMinutes: (json['travel_time_minutes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ClassMembershipToJson(ClassMembership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lesson_class_id': instance.lessonClassId,
      'student_id': instance.studentId,
      'instrument': instance.instrument,
      'status': _$MembershipStatusEnumMap[instance.status]!,
      'level': instance.level,
      'monthly_fee': instance.monthlyFee,
      'lessons_per_week': instance.lessonsPerWeek,
      'lesson_slots': instance.lessonSlots.map((e) => e.toJson()).toList(),
      'lesson_duration': instance.lessonDuration,
      'notes': instance.notes,
      'lesson_location_id': instance.lessonLocationId,
      'travel_time_minutes': instance.travelTimeMinutes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$MembershipStatusEnumMap = {
  MembershipStatus.trial: 'trial',
  MembershipStatus.active: 'active',
  MembershipStatus.paused: 'paused',
  MembershipStatus.terminated: 'terminated',
};
