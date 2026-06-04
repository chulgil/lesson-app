// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
      id: json['id'] as String,
      name: json['name'] as String,
      instrument: json['instrument'] as String,
      level: $enumDecodeNullable(_$StudentLevelEnumMap, json['level']) ??
          StudentLevel.intermediate,
      status: $enumDecodeNullable(_$StudentStatusEnumMap, json['status']) ??
          StudentStatus.trial,
      monthlyFee: (json['monthly_fee'] as num?)?.toInt() ?? 200000,
      lessonsPerWeek: (json['lessons_per_week'] as num?)?.toInt() ?? 1,
      phone: json['phone'] as String?,
      parentName: json['parent_name'] as String?,
      parentPhone: json['parent_phone'] as String?,
      email: json['email'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      backgroundImageUrl: json['background_image_url'] as String?,
      lessonSlots: (json['lesson_slots'] as List<dynamic>?)
              ?.map((e) => LessonSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lessonDuration: (json['lesson_duration'] as num?)?.toInt() ?? 60,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      monthlyLessons: (json['monthly_lessons'] as num?)?.toInt() ?? 0,
      practiceStatus: $enumDecodeNullable(
              _$PracticeStatusEnumMap, json['practice_status']) ??
          PracticeStatus.normal,
      practiceRate: (json['practice_rate'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      manualAgeGroup:
          $enumDecodeNullable(_$AgeGroupEnumMap, json['manual_age_group']),
      connectedAt: json['connected_at'] == null
          ? null
          : DateTime.parse(json['connected_at'] as String),
      breakReason: json['break_reason'] as String?,
      expectedReturnDate: json['expected_return_date'] == null
          ? null
          : DateTime.parse(json['expected_return_date'] as String),
      practiceLevel:
          $enumDecodeNullable(_$PracticeLevelEnumMap, json['practice_level']),
      postalCode: json['postal_code'] as String?,
      address: json['address'] as String?,
      addressDetail: json['address_detail'] as String?,
      district: json['district'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.parse(json['archived_at'] as String),
    );

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'instrument': instance.instrument,
      'level': _$StudentLevelEnumMap[instance.level]!,
      'status': _$StudentStatusEnumMap[instance.status]!,
      'monthly_fee': instance.monthlyFee,
      'lessons_per_week': instance.lessonsPerWeek,
      'phone': instance.phone,
      'parent_name': instance.parentName,
      'parent_phone': instance.parentPhone,
      'email': instance.email,
      'profile_image_url': instance.profileImageUrl,
      'background_image_url': instance.backgroundImageUrl,
      'lesson_slots': instance.lessonSlots.map((e) => e.toJson()).toList(),
      'lesson_duration': instance.lessonDuration,
      'total_lessons': instance.totalLessons,
      'monthly_lessons': instance.monthlyLessons,
      'practice_status': _$PracticeStatusEnumMap[instance.practiceStatus]!,
      'practice_rate': instance.practiceRate,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'is_active': instance.isActive,
      'birth_date': instance.birthDate?.toIso8601String(),
      'manual_age_group': _$AgeGroupEnumMap[instance.manualAgeGroup],
      'connected_at': instance.connectedAt?.toIso8601String(),
      'break_reason': instance.breakReason,
      'expected_return_date': instance.expectedReturnDate?.toIso8601String(),
      'practice_level': _$PracticeLevelEnumMap[instance.practiceLevel],
      'postal_code': instance.postalCode,
      'address': instance.address,
      'address_detail': instance.addressDetail,
      'district': instance.district,
      'is_archived': instance.isArchived,
      'archived_at': instance.archivedAt?.toIso8601String(),
    };

const _$StudentLevelEnumMap = {
  StudentLevel.beginner: 'beginner',
  StudentLevel.elementary: 'elementary',
  StudentLevel.intermediate: 'intermediate',
  StudentLevel.advanced: 'advanced',
};

const _$StudentStatusEnumMap = {
  StudentStatus.trial: 'trial',
  StudentStatus.active: 'active',
  StudentStatus.paused: 'paused',
  StudentStatus.inactive: 'inactive',
};

const _$PracticeStatusEnumMap = {
  PracticeStatus.good: 'good',
  PracticeStatus.normal: 'normal',
  PracticeStatus.poor: 'poor',
  PracticeStatus.paused: 'paused',
};

const _$AgeGroupEnumMap = {
  AgeGroup.child: 'child',
  AgeGroup.student: 'student',
  AgeGroup.adult: 'adult',
};

const _$PracticeLevelEnumMap = {
  PracticeLevel.newStudent: 'newStudent',
  PracticeLevel.excellent: 'excellent',
  PracticeLevel.average: 'average',
  PracticeLevel.poor: 'poor',
  PracticeLevel.onBreak: 'onBreak',
};
