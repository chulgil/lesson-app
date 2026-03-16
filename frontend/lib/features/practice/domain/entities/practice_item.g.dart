// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeItem _$PracticeItemFromJson(Map<String, dynamic> json) => PracticeItem(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      type: $enumDecode(_$PracticeTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String?,
      repertoireId: json['repertoire_id'] as String?,
      sectionId: json['section_id'] as String?,
      resourceIds: (json['resource_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      priority:
          $enumDecodeNullable(_$PracticePriorityEnumMap, json['priority']) ??
              PracticePriority.should,
      isCompleted: json['is_completed'] as bool? ?? false,
      practiceCount: (json['practice_count'] as num?)?.toInt() ?? 0,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      hasLike: json['has_like'] as bool? ?? false,
      likedAt: json['liked_at'] == null
          ? null
          : DateTime.parse(json['liked_at'] as String),
      teacherReaction:
          $enumDecodeNullable(_$QuickReactionEnumMap, json['teacher_reaction']),
      teacherReactionAt: json['teacher_reaction_at'] == null
          ? null
          : DateTime.parse(json['teacher_reaction_at'] as String),
      studentResponse: $enumDecodeNullable(
          _$StudentResponseEnumMap, json['student_response']),
      studentResponseAt: json['student_response_at'] == null
          ? null
          : DateTime.parse(json['student_response_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PracticeItemToJson(PracticeItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lesson_id': instance.lessonId,
      'student_id': instance.studentId,
      'teacher_id': instance.teacherId,
      'type': _$PracticeTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'repertoire_id': instance.repertoireId,
      'section_id': instance.sectionId,
      'priority': _$PracticePriorityEnumMap[instance.priority]!,
      'resource_ids': instance.resourceIds,
      'is_completed': instance.isCompleted,
      'practice_count': instance.practiceCount,
      'completed_at': instance.completedAt?.toIso8601String(),
      'has_like': instance.hasLike,
      'liked_at': instance.likedAt?.toIso8601String(),
      'teacher_reaction': _$QuickReactionEnumMap[instance.teacherReaction],
      'teacher_reaction_at': instance.teacherReactionAt?.toIso8601String(),
      'student_response': _$StudentResponseEnumMap[instance.studentResponse],
      'student_response_at': instance.studentResponseAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$PracticeTypeEnumMap = {
  PracticeType.repertoire: 'repertoire',
  PracticeType.technique: 'technique',
  PracticeType.theory: 'theory',
  PracticeType.custom: 'custom',
};

const _$PracticePriorityEnumMap = {
  PracticePriority.must: 'must',
  PracticePriority.should: 'should',
  PracticePriority.could: 'could',
};

const _$QuickReactionEnumMap = {
  QuickReaction.good: 'good',
  QuickReaction.excellent: 'excellent',
  QuickReaction.tryHarder: 'tryHarder',
};

const _$StudentResponseEnumMap = {
  StudentResponse.thanks: 'thanks',
  StudentResponse.question: 'question',
};
