import 'package:hive/hive.dart';

import '../../domain/entities/manual_teacher.dart';

class ManualTeacherHiveModel {
  final String id;
  final String name;
  final String? instrument;
  final String? phone;
  final String? notes;
  final DateTime createdAt;
  final int? profileColorValue;

  const ManualTeacherHiveModel({
    required this.id,
    required this.name,
    this.instrument,
    this.phone,
    this.notes,
    required this.createdAt,
    this.profileColorValue,
  });

  factory ManualTeacherHiveModel.fromDomain(ManualTeacher teacher) {
    return ManualTeacherHiveModel(
      id: teacher.id,
      name: teacher.name,
      instrument: teacher.instrument,
      phone: teacher.phone,
      notes: teacher.notes,
      createdAt: teacher.createdAt,
      profileColorValue: teacher.profileColorValue,
    );
  }

  ManualTeacher toDomain() {
    return ManualTeacher(
      id: id,
      name: name,
      instrument: instrument,
      phone: phone,
      notes: notes,
      createdAt: createdAt,
      profileColorValue: profileColorValue,
    );
  }
}

class ManualTeacherAdapter extends TypeAdapter<ManualTeacherHiveModel> {
  @override
  final int typeId = 110;

  @override
  ManualTeacherHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ManualTeacherHiveModel(
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
  void write(BinaryWriter writer, ManualTeacherHiveModel obj) {
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
