// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_slot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonSlotAdapter extends TypeAdapter<LessonSlot> {
  @override
  final int typeId = 130;

  @override
  LessonSlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonSlot(
      dayOfWeek: fields[0] as int,
      startTime: fields[1] as String,
      endTime: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LessonSlot obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dayOfWeek)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonSlot _$LessonSlotFromJson(Map<String, dynamic> json) => LessonSlot(
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );

Map<String, dynamic> _$LessonSlotToJson(LessonSlot instance) =>
    <String, dynamic>{
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
    };
