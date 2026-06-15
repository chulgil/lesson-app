// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'endorsement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Endorsement _$EndorsementFromJson(Map<String, dynamic> json) => Endorsement(
      by: $enumDecode(_$EndorsedByEnumMap, json['by']),
      date: DateTime.parse(json['date'] as String),
      authorUserId: json['author_user_id'] as String,
      assignmentRef: json['assignment_ref'] as String?,
      note: json['note'] as String,
    );

Map<String, dynamic> _$EndorsementToJson(Endorsement instance) =>
    <String, dynamic>{
      'by': _$EndorsedByEnumMap[instance.by]!,
      'date': instance.date.toIso8601String(),
      'author_user_id': instance.authorUserId,
      'assignment_ref': instance.assignmentRef,
      'note': instance.note,
    };

const _$EndorsedByEnumMap = {
  EndorsedBy.self: 'self',
  EndorsedBy.teacher: 'teacher',
};
