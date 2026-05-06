// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_teacher.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManualTeacher _$ManualTeacherFromJson(Map<String, dynamic> json) =>
    ManualTeacher(
      id: json['id'] as String,
      name: json['name'] as String,
      instrument: json['instrument'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      profileColorValue: (json['profile_color_value'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ManualTeacherToJson(ManualTeacher instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'instrument': instance.instrument,
      'phone': instance.phone,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'profile_color_value': instance.profileColorValue,
    };
