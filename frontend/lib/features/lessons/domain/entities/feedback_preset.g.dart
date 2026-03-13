// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_preset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedbackPresetAdapter extends TypeAdapter<FeedbackPreset> {
  @override
  final int typeId = 111;

  @override
  FeedbackPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedbackPreset(
      id: fields[0] as String,
      text: fields[1] as String,
      teacherId: fields[2] as String?,
      sortOrder: fields[3] as int,
      isDefault: fields[4] as bool,
      isHidden: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FeedbackPreset obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.teacherId)
      ..writeByte(3)
      ..write(obj.sortOrder)
      ..writeByte(4)
      ..write(obj.isDefault)
      ..writeByte(5)
      ..write(obj.isHidden)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedbackPresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
