// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackTemplate _$FeedbackTemplateFromJson(Map<String, dynamic> json) =>
    FeedbackTemplate(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      category:
          $enumDecodeNullable(_$FeedbackCategoryEnumMap, json['category']) ??
              FeedbackCategory.general,
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: json['last_used_at'] == null
          ? null
          : DateTime.parse(json['last_used_at'] as String),
    );

Map<String, dynamic> _$FeedbackTemplateToJson(FeedbackTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacher_id': instance.teacherId,
      'title': instance.title,
      'body': instance.body,
      'tags': instance.tags,
      'category': _$FeedbackCategoryEnumMap[instance.category]!,
      'usage_count': instance.usageCount,
      'created_at': instance.createdAt.toIso8601String(),
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
    };

const _$FeedbackCategoryEnumMap = {
  FeedbackCategory.technique: 'technique',
  FeedbackCategory.musicality: 'musicality',
  FeedbackCategory.practice: 'practice',
  FeedbackCategory.attitude: 'attitude',
  FeedbackCategory.general: 'general',
};
