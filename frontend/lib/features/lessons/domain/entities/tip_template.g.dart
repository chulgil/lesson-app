// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tip_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TipTemplate _$TipTemplateFromJson(Map<String, dynamic> json) => TipTemplate(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      content: json['content'] as String,
      category: $enumDecodeNullable(_$TipCategoryEnumMap, json['category']) ??
          TipCategory.general,
      instrument: json['instrument'] as String?,
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: json['last_used_at'] == null
          ? null
          : DateTime.parse(json['last_used_at'] as String),
    );

Map<String, dynamic> _$TipTemplateToJson(TipTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacher_id': instance.teacherId,
      'content': instance.content,
      'category': _$TipCategoryEnumMap[instance.category]!,
      'instrument': instance.instrument,
      'usage_count': instance.usageCount,
      'created_at': instance.createdAt.toIso8601String(),
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
    };

const _$TipCategoryEnumMap = {
  TipCategory.technique: 'technique',
  TipCategory.musicality: 'musicality',
  TipCategory.practice: 'practice',
  TipCategory.mindset: 'mindset',
  TipCategory.general: 'general',
};
