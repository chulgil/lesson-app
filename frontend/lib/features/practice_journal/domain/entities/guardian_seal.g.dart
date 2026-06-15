// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guardian_seal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GuardianSeal _$GuardianSealFromJson(Map<String, dynamic> json) => GuardianSeal(
      weekStart: DateTime.parse(json['week_start'] as String),
      guardianUserId: json['guardian_user_id'] as String,
      cheerNote: json['cheer_note'] as String?,
    );

Map<String, dynamic> _$GuardianSealToJson(GuardianSeal instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart.toIso8601String(),
      'guardian_user_id': instance.guardianUserId,
      'cheer_note': instance.cheerNote,
    };
