// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'makeup_lesson.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MakeupLessonAdapter extends TypeAdapter<MakeupLesson> {
  @override
  final int typeId = 87;

  @override
  MakeupLesson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MakeupLesson(
      id: fields[0] as String,
      studentId: fields[1] as String,
      teacherId: fields[2] as String,
      originalLessonId: fields[3] as String?,
      scheduledLessonId: fields[4] as String?,
      status: fields[5] as MakeupStatus,
      reason: fields[6] as MakeupReason,
      createdAt: fields[7] as DateTime,
      expiresAt: fields[8] as DateTime,
      scheduledAt: fields[9] as DateTime?,
      completedAt: fields[10] as DateTime?,
      note: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MakeupLesson obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.teacherId)
      ..writeByte(3)
      ..write(obj.originalLessonId)
      ..writeByte(4)
      ..write(obj.scheduledLessonId)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.reason)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.expiresAt)
      ..writeByte(9)
      ..write(obj.scheduledAt)
      ..writeByte(10)
      ..write(obj.completedAt)
      ..writeByte(11)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MakeupLessonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MakeupStatusAdapter extends TypeAdapter<MakeupStatus> {
  @override
  final int typeId = 85;

  @override
  MakeupStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MakeupStatus.pending;
      case 1:
        return MakeupStatus.scheduled;
      case 2:
        return MakeupStatus.completed;
      case 3:
        return MakeupStatus.expired;
      case 4:
        return MakeupStatus.waived;
      default:
        return MakeupStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, MakeupStatus obj) {
    switch (obj) {
      case MakeupStatus.pending:
        writer.writeByte(0);
        break;
      case MakeupStatus.scheduled:
        writer.writeByte(1);
        break;
      case MakeupStatus.completed:
        writer.writeByte(2);
        break;
      case MakeupStatus.expired:
        writer.writeByte(3);
        break;
      case MakeupStatus.waived:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MakeupStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MakeupReasonAdapter extends TypeAdapter<MakeupReason> {
  @override
  final int typeId = 86;

  @override
  MakeupReason read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MakeupReason.studentCancellation;
      case 1:
        return MakeupReason.teacherCancellation;
      case 2:
        return MakeupReason.noShowReschedule;
      case 3:
        return MakeupReason.other;
      default:
        return MakeupReason.studentCancellation;
    }
  }

  @override
  void write(BinaryWriter writer, MakeupReason obj) {
    switch (obj) {
      case MakeupReason.studentCancellation:
        writer.writeByte(0);
        break;
      case MakeupReason.teacherCancellation:
        writer.writeByte(1);
        break;
      case MakeupReason.noShowReschedule:
        writer.writeByte(2);
        break;
      case MakeupReason.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MakeupReasonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MakeupLesson _$MakeupLessonFromJson(Map<String, dynamic> json) => MakeupLesson(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      teacherId: json['teacherId'] as String,
      originalLessonId: json['originalLessonId'] as String?,
      scheduledLessonId: json['scheduledLessonId'] as String?,
      status: $enumDecodeNullable(_$MakeupStatusEnumMap, json['status']) ??
          MakeupStatus.pending,
      reason: $enumDecode(_$MakeupReasonEnumMap, json['reason']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      scheduledAt: json['scheduledAt'] == null
          ? null
          : DateTime.parse(json['scheduledAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$MakeupLessonToJson(MakeupLesson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'teacherId': instance.teacherId,
      'originalLessonId': instance.originalLessonId,
      'scheduledLessonId': instance.scheduledLessonId,
      'status': _$MakeupStatusEnumMap[instance.status]!,
      'reason': _$MakeupReasonEnumMap[instance.reason]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'scheduledAt': instance.scheduledAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'note': instance.note,
    };

const _$MakeupStatusEnumMap = {
  MakeupStatus.pending: 'pending',
  MakeupStatus.scheduled: 'scheduled',
  MakeupStatus.completed: 'completed',
  MakeupStatus.expired: 'expired',
  MakeupStatus.waived: 'waived',
};

const _$MakeupReasonEnumMap = {
  MakeupReason.studentCancellation: 'studentCancellation',
  MakeupReason.teacherCancellation: 'teacherCancellation',
  MakeupReason.noShowReschedule: 'noShowReschedule',
  MakeupReason.other: 'other',
};
