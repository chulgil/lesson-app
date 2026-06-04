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
      // 2026-06-04 추가 필드 (구 레코드는 null/false 로 자동 fallback)
      usedMetronome: (fields[7] as bool?) ?? false,
      timeSignatureIndex: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PracticeRecording obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.usedMetronome)
      ..writeByte(8)
      ..write(obj.timeSignatureIndex);
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
