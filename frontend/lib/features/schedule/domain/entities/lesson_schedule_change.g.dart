// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_schedule_change.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonScheduleChangeAdapter extends TypeAdapter<LessonScheduleChange> {
  @override
  final int typeId = 92;

  @override
  LessonScheduleChange read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonScheduleChange(
      id: fields[0] as String,
      studentId: fields[1] as String,
      teacherId: fields[2] as String,
      changeType: fields[3] as ScheduleChangeType,
      previousDayOfWeek: fields[4] as int?,
      previousTime: fields[5] as String?,
      newDayOfWeek: fields[6] as int?,
      newTime: fields[7] as String?,
      effectiveFrom: fields[8] as DateTime,
      status: fields[9] as ScheduleChangeStatus,
      requestedAt: fields[10] as DateTime,
      processedAt: fields[11] as DateTime?,
      requestReason: fields[12] as String?,
      responseMessage: fields[13] as String?,
      alternativeTimes: (fields[14] as List?)?.cast<String>(),
      requestedBy: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LessonScheduleChange obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.teacherId)
      ..writeByte(3)
      ..write(obj.changeType)
      ..writeByte(4)
      ..write(obj.previousDayOfWeek)
      ..writeByte(5)
      ..write(obj.previousTime)
      ..writeByte(6)
      ..write(obj.newDayOfWeek)
      ..writeByte(7)
      ..write(obj.newTime)
      ..writeByte(8)
      ..write(obj.effectiveFrom)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.requestedAt)
      ..writeByte(11)
      ..write(obj.processedAt)
      ..writeByte(12)
      ..write(obj.requestReason)
      ..writeByte(13)
      ..write(obj.responseMessage)
      ..writeByte(14)
      ..write(obj.alternativeTimes)
      ..writeByte(15)
      ..write(obj.requestedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonScheduleChangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleChangeTypeAdapter extends TypeAdapter<ScheduleChangeType> {
  @override
  final int typeId = 90;

  @override
  ScheduleChangeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduleChangeType.singleLesson;
      case 1:
        return ScheduleChangeType.bulkChange;
      default:
        return ScheduleChangeType.singleLesson;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduleChangeType obj) {
    switch (obj) {
      case ScheduleChangeType.singleLesson:
        writer.writeByte(0);
        break;
      case ScheduleChangeType.bulkChange:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleChangeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleChangeStatusAdapter extends TypeAdapter<ScheduleChangeStatus> {
  @override
  final int typeId = 91;

  @override
  ScheduleChangeStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduleChangeStatus.pending;
      case 1:
        return ScheduleChangeStatus.approved;
      case 2:
        return ScheduleChangeStatus.rejected;
      case 3:
        return ScheduleChangeStatus.alternativeProposed;
      case 4:
        return ScheduleChangeStatus.cancelled;
      default:
        return ScheduleChangeStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduleChangeStatus obj) {
    switch (obj) {
      case ScheduleChangeStatus.pending:
        writer.writeByte(0);
        break;
      case ScheduleChangeStatus.approved:
        writer.writeByte(1);
        break;
      case ScheduleChangeStatus.rejected:
        writer.writeByte(2);
        break;
      case ScheduleChangeStatus.alternativeProposed:
        writer.writeByte(3);
        break;
      case ScheduleChangeStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleChangeStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonScheduleChange _$LessonScheduleChangeFromJson(
        Map<String, dynamic> json) =>
    LessonScheduleChange(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      teacherId: json['teacherId'] as String,
      changeType: $enumDecode(_$ScheduleChangeTypeEnumMap, json['changeType']),
      previousDayOfWeek: (json['previousDayOfWeek'] as num?)?.toInt(),
      previousTime: json['previousTime'] as String?,
      newDayOfWeek: (json['newDayOfWeek'] as num?)?.toInt(),
      newTime: json['newTime'] as String?,
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      status:
          $enumDecodeNullable(_$ScheduleChangeStatusEnumMap, json['status']) ??
              ScheduleChangeStatus.pending,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      requestReason: json['requestReason'] as String?,
      responseMessage: json['responseMessage'] as String?,
      alternativeTimes: (json['alternativeTimes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      requestedBy: json['requestedBy'] as String,
    );

Map<String, dynamic> _$LessonScheduleChangeToJson(
        LessonScheduleChange instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'teacherId': instance.teacherId,
      'changeType': _$ScheduleChangeTypeEnumMap[instance.changeType]!,
      'previousDayOfWeek': instance.previousDayOfWeek,
      'previousTime': instance.previousTime,
      'newDayOfWeek': instance.newDayOfWeek,
      'newTime': instance.newTime,
      'effectiveFrom': instance.effectiveFrom.toIso8601String(),
      'status': _$ScheduleChangeStatusEnumMap[instance.status]!,
      'requestedAt': instance.requestedAt.toIso8601String(),
      'processedAt': instance.processedAt?.toIso8601String(),
      'requestReason': instance.requestReason,
      'responseMessage': instance.responseMessage,
      'alternativeTimes': instance.alternativeTimes,
      'requestedBy': instance.requestedBy,
    };

const _$ScheduleChangeTypeEnumMap = {
  ScheduleChangeType.singleLesson: 'singleLesson',
  ScheduleChangeType.bulkChange: 'bulkChange',
};

const _$ScheduleChangeStatusEnumMap = {
  ScheduleChangeStatus.pending: 'pending',
  ScheduleChangeStatus.approved: 'approved',
  ScheduleChangeStatus.rejected: 'rejected',
  ScheduleChangeStatus.alternativeProposed: 'alternativeProposed',
  ScheduleChangeStatus.cancelled: 'cancelled',
};
