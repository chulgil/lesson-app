// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeNote _$PracticeNoteFromJson(Map<String, dynamic> json) => PracticeNote(
  id: json['id'] as String,
  sectionId: json['section_id'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PracticeNoteToJson(PracticeNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'section_id': instance.sectionId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
