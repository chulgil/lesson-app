// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PracticeNoteAdapter extends TypeAdapter<PracticeNote> {
  @override
  final int typeId = 31;

  @override
  PracticeNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PracticeNote(
      id: fields[0] as String,
      sectionId: fields[1] as String,
      content: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PracticeNote obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sectionId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
