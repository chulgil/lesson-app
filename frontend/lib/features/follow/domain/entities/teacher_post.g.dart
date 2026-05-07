// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherPost _$TeacherPostFromJson(Map<String, dynamic> json) => TeacherPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      postType: $enumDecode(_$PostTypeEnumMap, json['post_type']),
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TeacherPostToJson(TeacherPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'author_name': instance.authorName,
      'post_type': _$PostTypeEnumMap[instance.postType]!,
      'title': instance.title,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$PostTypeEnumMap = {
  PostType.performance: 'performance',
  PostType.event: 'event',
  PostType.notice: 'notice',
};
