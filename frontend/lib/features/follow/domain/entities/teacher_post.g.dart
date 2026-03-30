// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_post.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TeacherPostAdapter extends TypeAdapter<TeacherPost> {
  @override
  final int typeId = 141;

  @override
  TeacherPost read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TeacherPost(
      id: fields[0] as String,
      authorId: fields[1] as String,
      authorName: fields[2] as String,
      postType: fields[3] as PostType,
      title: fields[4] as String,
      content: fields[5] as String,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TeacherPost obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.authorId)
      ..writeByte(2)
      ..write(obj.authorName)
      ..writeByte(3)
      ..write(obj.postType)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherPostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PostTypeAdapter extends TypeAdapter<PostType> {
  @override
  final int typeId = 140;

  @override
  PostType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PostType.performance;
      case 1:
        return PostType.event;
      case 2:
        return PostType.notice;
      default:
        return PostType.performance;
    }
  }

  @override
  void write(BinaryWriter writer, PostType obj) {
    switch (obj) {
      case PostType.performance:
        writer.writeByte(0);
        break;
      case PostType.event:
        writer.writeByte(1);
        break;
      case PostType.notice:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
