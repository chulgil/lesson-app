// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PracticeGoalAdapter extends TypeAdapter<PracticeGoal> {
  @override
  final int typeId = 32;

  @override
  PracticeGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PracticeGoal(
      id: fields[0] as String,
      studentId: fields[1] as String,
      dailyTimeMinutes: fields[2] as int?,
      dailySectionCount: fields[3] as int?,
      weeklyTimeMinutes: fields[4] as int?,
      weeklyDayCount: fields[5] as int?,
      isActive: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PracticeGoal obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.dailyTimeMinutes)
      ..writeByte(3)
      ..write(obj.dailySectionCount)
      ..writeByte(4)
      ..write(obj.weeklyTimeMinutes)
      ..writeByte(5)
      ..write(obj.weeklyDayCount)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
