// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonRequestAdapter extends TypeAdapter<LessonRequest> {
  @override
  final int typeId = 100;

  @override
  LessonRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonRequest(
      id: fields[0] as String,
      studentId: fields[1] as String,
      teacherId: fields[2] as String,
      message: fields[3] as String?,
      preferredTiming: fields[4] as PreferredStartTiming,
      keepPreviousSchedule: fields[5] as bool,
      previousLessonDay: fields[6] as int?,
      previousLessonTime: fields[7] as String?,
      previousLessonDuration: fields[8] as int?,
      status: fields[9] as LessonRequestStatus,
      createdAt: fields[10] as DateTime,
      expiresAt: fields[11] as DateTime,
      proposalId: fields[12] as String?,
      declineReason: fields[13] as String?,
      statusUpdatedAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonRequest obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.teacherId)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.preferredTiming)
      ..writeByte(5)
      ..write(obj.keepPreviousSchedule)
      ..writeByte(6)
      ..write(obj.previousLessonDay)
      ..writeByte(7)
      ..write(obj.previousLessonTime)
      ..writeByte(8)
      ..write(obj.previousLessonDuration)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.expiresAt)
      ..writeByte(12)
      ..write(obj.proposalId)
      ..writeByte(13)
      ..write(obj.declineReason)
      ..writeByte(14)
      ..write(obj.statusUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PreferredStartTimingAdapter extends TypeAdapter<PreferredStartTiming> {
  @override
  final int typeId = 98;

  @override
  PreferredStartTiming read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PreferredStartTiming.nextWeek;
      case 1:
        return PreferredStartTiming.nextMonth;
      case 2:
        return PreferredStartTiming.afterConsultation;
      default:
        return PreferredStartTiming.nextWeek;
    }
  }

  @override
  void write(BinaryWriter writer, PreferredStartTiming obj) {
    switch (obj) {
      case PreferredStartTiming.nextWeek:
        writer.writeByte(0);
        break;
      case PreferredStartTiming.nextMonth:
        writer.writeByte(1);
        break;
      case PreferredStartTiming.afterConsultation:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreferredStartTimingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LessonRequestStatusAdapter extends TypeAdapter<LessonRequestStatus> {
  @override
  final int typeId = 99;

  @override
  LessonRequestStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LessonRequestStatus.pending;
      case 1:
        return LessonRequestStatus.proposalSent;
      case 2:
        return LessonRequestStatus.accepted;
      case 3:
        return LessonRequestStatus.declined;
      case 4:
        return LessonRequestStatus.expired;
      case 5:
        return LessonRequestStatus.cancelled;
      default:
        return LessonRequestStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, LessonRequestStatus obj) {
    switch (obj) {
      case LessonRequestStatus.pending:
        writer.writeByte(0);
        break;
      case LessonRequestStatus.proposalSent:
        writer.writeByte(1);
        break;
      case LessonRequestStatus.accepted:
        writer.writeByte(2);
        break;
      case LessonRequestStatus.declined:
        writer.writeByte(3);
        break;
      case LessonRequestStatus.expired:
        writer.writeByte(4);
        break;
      case LessonRequestStatus.cancelled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonRequestStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonRequest _$LessonRequestFromJson(Map<String, dynamic> json) =>
    LessonRequest(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      teacherId: json['teacherId'] as String,
      message: json['message'] as String?,
      preferredTiming: $enumDecodeNullable(
              _$PreferredStartTimingEnumMap, json['preferredTiming']) ??
          PreferredStartTiming.nextWeek,
      keepPreviousSchedule: json['keepPreviousSchedule'] as bool? ?? true,
      previousLessonDay: (json['previousLessonDay'] as num?)?.toInt(),
      previousLessonTime: json['previousLessonTime'] as String?,
      previousLessonDuration: (json['previousLessonDuration'] as num?)?.toInt(),
      status:
          $enumDecodeNullable(_$LessonRequestStatusEnumMap, json['status']) ??
              LessonRequestStatus.pending,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      proposalId: json['proposalId'] as String?,
      declineReason: json['declineReason'] as String?,
      statusUpdatedAt: json['statusUpdatedAt'] == null
          ? null
          : DateTime.parse(json['statusUpdatedAt'] as String),
    );

Map<String, dynamic> _$LessonRequestToJson(LessonRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'teacherId': instance.teacherId,
      'message': instance.message,
      'preferredTiming':
          _$PreferredStartTimingEnumMap[instance.preferredTiming]!,
      'keepPreviousSchedule': instance.keepPreviousSchedule,
      'previousLessonDay': instance.previousLessonDay,
      'previousLessonTime': instance.previousLessonTime,
      'previousLessonDuration': instance.previousLessonDuration,
      'status': _$LessonRequestStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'proposalId': instance.proposalId,
      'declineReason': instance.declineReason,
      'statusUpdatedAt': instance.statusUpdatedAt?.toIso8601String(),
    };

const _$PreferredStartTimingEnumMap = {
  PreferredStartTiming.nextWeek: 'nextWeek',
  PreferredStartTiming.nextMonth: 'nextMonth',
  PreferredStartTiming.afterConsultation: 'afterConsultation',
};

const _$LessonRequestStatusEnumMap = {
  LessonRequestStatus.pending: 'pending',
  LessonRequestStatus.proposalSent: 'proposalSent',
  LessonRequestStatus.accepted: 'accepted',
  LessonRequestStatus.declined: 'declined',
  LessonRequestStatus.expired: 'expired',
  LessonRequestStatus.cancelled: 'cancelled',
};
