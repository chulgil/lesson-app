// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_streak.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeStreak _$PracticeStreakFromJson(Map<String, dynamic> json) =>
    PracticeStreak(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      lastPracticeDate: json['last_practice_date'] == null
          ? null
          : DateTime.parse(json['last_practice_date'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PracticeStreakToJson(PracticeStreak instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'last_practice_date': instance.lastPracticeDate?.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
