// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackPreset _$FeedbackPresetFromJson(Map<String, dynamic> json) =>
    FeedbackPreset(
      id: json['id'] as String,
      text: json['text'] as String,
      teacherId: json['teacher_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FeedbackPresetToJson(FeedbackPreset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'teacher_id': instance.teacherId,
      'sort_order': instance.sortOrder,
      'is_default': instance.isDefault,
      'is_hidden': instance.isHidden,
      'created_at': instance.createdAt.toIso8601String(),
    };
