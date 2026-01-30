// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'no_show_policy.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoShowRecordAdapter extends TypeAdapter<NoShowRecord> {
  @override
  final int typeId = 89;

  @override
  NoShowRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoShowRecord(
      id: fields[0] as String,
      lessonId: fields[1] as String,
      studentId: fields[2] as String,
      teacherId: fields[3] as String,
      lessonDate: fields[4] as DateTime,
      appliedPolicy: fields[5] as NoShowPolicy,
      deductedCredits: fields[6] as double,
      makeupLessonId: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      processedBy: fields[9] as String,
      note: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NoShowRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lessonId)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.teacherId)
      ..writeByte(4)
      ..write(obj.lessonDate)
      ..writeByte(5)
      ..write(obj.appliedPolicy)
      ..writeByte(6)
      ..write(obj.deductedCredits)
      ..writeByte(7)
      ..write(obj.makeupLessonId)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.processedBy)
      ..writeByte(10)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoShowRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoShowPolicyAdapter extends TypeAdapter<NoShowPolicy> {
  @override
  final int typeId = 88;

  @override
  NoShowPolicy read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NoShowPolicy.deductCredit;
      case 1:
        return NoShowPolicy.halfCredit;
      case 2:
        return NoShowPolicy.noDeduction;
      case 3:
        return NoShowPolicy.reschedule;
      default:
        return NoShowPolicy.deductCredit;
    }
  }

  @override
  void write(BinaryWriter writer, NoShowPolicy obj) {
    switch (obj) {
      case NoShowPolicy.deductCredit:
        writer.writeByte(0);
        break;
      case NoShowPolicy.halfCredit:
        writer.writeByte(1);
        break;
      case NoShowPolicy.noDeduction:
        writer.writeByte(2);
        break;
      case NoShowPolicy.reschedule:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoShowPolicyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
