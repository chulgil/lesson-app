// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Teacher _$TeacherFromJson(Map<String, dynamic> json) => Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      instruments: (json['instruments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      bio: json['bio'] as String?,
      education: json['education'] as String?,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      trialLessonFee: (json['trial_lesson_fee'] as num?)?.toInt() ?? 30000,
      regularLessonFee: (json['regular_lesson_fee'] as num?)?.toInt() ?? 60000,
      location: json['location'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TeacherToJson(Teacher instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nickname': instance.nickname,
      'profile_image_url': instance.profileImageUrl,
      'instruments': instance.instruments,
      'bio': instance.bio,
      'education': instance.education,
      'experience_years': instance.experienceYears,
      'rating': instance.rating,
      'review_count': instance.reviewCount,
      'trial_lesson_fee': instance.trialLessonFee,
      'regular_lesson_fee': instance.regularLessonFee,
      'location': instance.location,
      'is_available': instance.isAvailable,
      'created_at': instance.createdAt.toIso8601String(),
    };
