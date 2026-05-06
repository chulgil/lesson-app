import 'package:hive/hive.dart';

import '../../domain/entities/recording.dart';

class RecordingAdapter extends TypeAdapter<Recording> {
  @override
  final int typeId = 22;

  @override
  Recording read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recording(
      id: fields[0] as String,
      repertoireId: fields[1] as String,
      studentId: fields[2] as String,
      type: fields[3] as RecordingType,
      localPath: fields[4] as String,
      durationSeconds: fields[6] as int,
      recordedAt: fields[8] as DateTime,
      serverUrl: fields[5] as String?,
      isRepresentative: fields[7] as bool,
      sharedAt: fields[9] as DateTime?,
      storageStatus: fields[10] as StorageStatus,
      title: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Recording obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.repertoireId)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.localPath)
      ..writeByte(5)
      ..write(obj.serverUrl)
      ..writeByte(6)
      ..write(obj.durationSeconds)
      ..writeByte(7)
      ..write(obj.isRepresentative)
      ..writeByte(8)
      ..write(obj.recordedAt)
      ..writeByte(9)
      ..write(obj.sharedAt)
      ..writeByte(10)
      ..write(obj.storageStatus)
      ..writeByte(11)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecordingTypeAdapter extends TypeAdapter<RecordingType> {
  @override
  final int typeId = 20;

  @override
  RecordingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecordingType.student;
      case 1:
        return RecordingType.teacher;
      case 2:
        return RecordingType.feedback;
      default:
        return RecordingType.student;
    }
  }

  @override
  void write(BinaryWriter writer, RecordingType obj) {
    switch (obj) {
      case RecordingType.student:
        writer.writeByte(0);
        break;
      case RecordingType.teacher:
        writer.writeByte(1);
        break;
      case RecordingType.feedback:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StorageStatusAdapter extends TypeAdapter<StorageStatus> {
  @override
  final int typeId = 21;

  @override
  StorageStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StorageStatus.local;
      case 1:
        return StorageStatus.active;
      case 2:
        return StorageStatus.archived;
      case 3:
        return StorageStatus.deleted;
      default:
        return StorageStatus.local;
    }
  }

  @override
  void write(BinaryWriter writer, StorageStatus obj) {
    switch (obj) {
      case StorageStatus.local:
        writer.writeByte(0);
        break;
      case StorageStatus.active:
        writer.writeByte(1);
        break;
      case StorageStatus.archived:
        writer.writeByte(2);
        break;
      case StorageStatus.deleted:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
