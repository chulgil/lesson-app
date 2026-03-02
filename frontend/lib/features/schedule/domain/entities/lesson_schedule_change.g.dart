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
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      changeType: $enumDecode(_$ScheduleChangeTypeEnumMap, json['change_type']),
      previousDayOfWeek: (json['previous_day_of_week'] as num?)?.toInt(),
      previousTime: json['previous_time'] as String?,
      newDayOfWeek: (json['new_day_of_week'] as num?)?.toInt(),
      newTime: json['new_time'] as String?,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      status:
          $enumDecodeNullable(_$ScheduleChangeStatusEnumMap, json['status']) ??
              ScheduleChangeStatus.pending,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      processedAt: json['processed_at'] == null
          ? null
          : DateTime.parse(json['processed_at'] as String),
      requestReason: json['request_reason'] as String?,
      responseMessage: json['response_message'] as String?,
      alternativeTimes: (json['alternative_times'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      requestedBy: json['requested_by'] as String,
    );

Map<String, dynamic> _$LessonScheduleChangeToJson(
        LessonScheduleChange instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'teacher_id': instance.teacherId,
      'change_type': _$ScheduleChangeTypeEnumMap[instance.changeType]!,
      'previous_day_of_week': instance.previousDayOfWeek,
      'previous_time': instance.previousTime,
      'new_day_of_week': instance.newDayOfWeek,
      'new_time': instance.newTime,
      'effective_from': instance.effectiveFrom.toIso8601String(),
      'status': _$ScheduleChangeStatusEnumMap[instance.status]!,
      'requested_at': instance.requestedAt.toIso8601String(),
      'processed_at': instance.processedAt?.toIso8601String(),
      'request_reason': instance.requestReason,
      'response_message': instance.responseMessage,
      'alternative_times': instance.alternativeTimes,
      'requested_by': instance.requestedBy,
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
