import 'package:hive/hive.dart';

import '../../domain/entities/practice_repertoire.dart';

class PracticeRecordingAdapter extends TypeAdapter<PracticeRecording> {
  @override
  final int typeId = 30;

  @override
  PracticeRecording read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PracticeRecording(
      id: fields[0] as String,
      sectionId: fields[1] as String,
      filePath: fields[2] as String,
      durationSeconds: fields[3] as int,
      bpm: fields[4] as int?,
      isRepresentative: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PracticeRecording obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sectionId)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.bpm)
      ..writeByte(5)
      ..write(obj.isRepresentative)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeRecordingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
