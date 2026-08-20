// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupClassMember _$GroupClassMemberFromJson(Map<String, dynamic> json) =>
    GroupClassMember(
      id: json['id'] as String,
      groupClassId: json['group_class_id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$GroupClassMemberToJson(GroupClassMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_class_id': instance.groupClassId,
      'student_id': instance.studentId,
      'student_name': instance.studentName,
      'created_at': instance.createdAt.toIso8601String(),
    };
