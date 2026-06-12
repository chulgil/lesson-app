// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_freeze.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StreakFreeze _$StreakFreezeFromJson(Map<String, dynamic> json) => StreakFreeze(
      studentId: json['student_id'] as String,
      balance: (json['balance'] as num).toInt(),
      usedAt: (json['used_at'] as List<dynamic>)
          .map((e) => DateTime.parse(e as String))
          .toList(),
      examModeUntil: json['exam_mode_until'] == null
          ? null
          : DateTime.parse(json['exam_mode_until'] as String),
      lastGrantedAt: json['last_granted_at'] == null
          ? null
          : DateTime.parse(json['last_granted_at'] as String),
    );

Map<String, dynamic> _$StreakFreezeToJson(StreakFreeze instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'balance': instance.balance,
      'used_at': instance.usedAt.map((e) => e.toIso8601String()).toList(),
      'exam_mode_until': instance.examModeUntil?.toIso8601String(),
      'last_granted_at': instance.lastGrantedAt?.toIso8601String(),
    };
