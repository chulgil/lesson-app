// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_teacher.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ManualTeacherAdapter extends TypeAdapter<ManualTeacher> {
  @override
  final int typeId = 110;

  @override
  ManualTeacher read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ManualTeacher(
      id: fields[0] as String,
      name: fields[1] as String,
      instrument: fields[2] as String?,
      phone: fields[3] as String?,
      notes: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      profileColorValue: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ManualTeacher obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.instrument)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.profileColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualTeacherAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManualTeacher _$ManualTeacherFromJson(Map<String, dynamic> json) =>
    ManualTeacher(
      id: json['id'] as String,
      name: json['name'] as String,
      instrument: json['instrument'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      profileColorValue: (json['profile_color_value'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ManualTeacherToJson(ManualTeacher instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'instrument': instance.instrument,
      'phone': instance.phone,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'profile_color_value': instance.profileColorValue,
    };
