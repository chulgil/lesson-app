// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_confirmation_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleConfirmationCardAdapter
    extends TypeAdapter<ScheduleConfirmationCard> {
  @override
  final int typeId = 102;

  @override
  ScheduleConfirmationCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleConfirmationCard(
      id: fields[0] as String,
      studentId: fields[1] as String,
      teacherId: fields[2] as String,
      teacherName: fields[3] as String,
      instrument: fields[4] as String?,
      subscriptionId: fields[5] as String,
      suggestedDay: fields[6] as int?,
      suggestedTime: fields[7] as String?,
      lessonDuration: fields[8] as int?,
      cardType: fields[9] as ScheduleCardType,
      status: fields[10] as ScheduleCardStatus,
      createdAt: fields[11] as DateTime,
      respondedAt: fields[12] as DateTime?,
      totalLessons: fields[13] as int?,
      lessonRequestId: fields[14] as String?,
      suggestedDay2: fields[15] as int?,
      suggestedTime2: fields[16] as String?,
      suggestedDay3: fields[17] as int?,
      suggestedTime3: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleConfirmationCard obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.teacherId)
      ..writeByte(3)
      ..write(obj.teacherName)
      ..writeByte(4)
      ..write(obj.instrument)
      ..writeByte(5)
      ..write(obj.subscriptionId)
      ..writeByte(6)
      ..write(obj.suggestedDay)
      ..writeByte(7)
      ..write(obj.suggestedTime)
      ..writeByte(8)
      ..write(obj.lessonDuration)
      ..writeByte(9)
      ..write(obj.cardType)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.respondedAt)
      ..writeByte(13)
      ..write(obj.totalLessons)
      ..writeByte(14)
      ..write(obj.lessonRequestId)
      ..writeByte(15)
      ..write(obj.suggestedDay2)
      ..writeByte(16)
      ..write(obj.suggestedTime2)
      ..writeByte(17)
      ..write(obj.suggestedDay3)
      ..writeByte(18)
      ..write(obj.suggestedTime3);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleConfirmationCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleCardTypeAdapter extends TypeAdapter<ScheduleCardType> {
  @override
  final int typeId = 100;

  @override
  ScheduleCardType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduleCardType.afterTrial;
      case 1:
        return ScheduleCardType.reEnrollment;
      case 2:
        return ScheduleCardType.additionalInstrument;
      default:
        return ScheduleCardType.afterTrial;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduleCardType obj) {
    switch (obj) {
      case ScheduleCardType.afterTrial:
        writer.writeByte(0);
        break;
      case ScheduleCardType.reEnrollment:
        writer.writeByte(1);
        break;
      case ScheduleCardType.additionalInstrument:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleCardTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleCardStatusAdapter extends TypeAdapter<ScheduleCardStatus> {
  @override
  final int typeId = 101;

  @override
  ScheduleCardStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduleCardStatus.pending;
      case 1:
        return ScheduleCardStatus.confirmed;
      case 2:
        return ScheduleCardStatus.changedTime;
      case 3:
        return ScheduleCardStatus.dismissed;
      default:
        return ScheduleCardStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduleCardStatus obj) {
    switch (obj) {
      case ScheduleCardStatus.pending:
        writer.writeByte(0);
        break;
      case ScheduleCardStatus.confirmed:
        writer.writeByte(1);
        break;
      case ScheduleCardStatus.changedTime:
        writer.writeByte(2);
        break;
      case ScheduleCardStatus.dismissed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleCardStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleConfirmationCard _$ScheduleConfirmationCardFromJson(
        Map<String, dynamic> json) =>
    ScheduleConfirmationCard(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      instrument: json['instrument'] as String?,
      subscriptionId: json['subscription_id'] as String,
      suggestedDay: (json['suggested_day'] as num?)?.toInt(),
      suggestedTime: json['suggested_time'] as String?,
      lessonDuration: (json['lesson_duration'] as num?)?.toInt(),
      cardType: $enumDecode(_$ScheduleCardTypeEnumMap, json['card_type']),
      status:
          $enumDecodeNullable(_$ScheduleCardStatusEnumMap, json['status']) ??
              ScheduleCardStatus.pending,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] == null
          ? null
          : DateTime.parse(json['responded_at'] as String),
      totalLessons: (json['total_lessons'] as num?)?.toInt(),
      lessonRequestId: json['lesson_request_id'] as String?,
      suggestedDay2: (json['suggested_day2'] as num?)?.toInt(),
      suggestedTime2: json['suggested_time2'] as String?,
      suggestedDay3: (json['suggested_day3'] as num?)?.toInt(),
      suggestedTime3: json['suggested_time3'] as String?,
    );

Map<String, dynamic> _$ScheduleConfirmationCardToJson(
        ScheduleConfirmationCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'teacher_id': instance.teacherId,
      'teacher_name': instance.teacherName,
      'instrument': instance.instrument,
      'subscription_id': instance.subscriptionId,
      'suggested_day': instance.suggestedDay,
      'suggested_time': instance.suggestedTime,
      'lesson_duration': instance.lessonDuration,
      'card_type': _$ScheduleCardTypeEnumMap[instance.cardType]!,
      'status': _$ScheduleCardStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'responded_at': instance.respondedAt?.toIso8601String(),
      'total_lessons': instance.totalLessons,
      'lesson_request_id': instance.lessonRequestId,
      'suggested_day2': instance.suggestedDay2,
      'suggested_time2': instance.suggestedTime2,
      'suggested_day3': instance.suggestedDay3,
      'suggested_time3': instance.suggestedTime3,
    };

const _$ScheduleCardTypeEnumMap = {
  ScheduleCardType.afterTrial: 'afterTrial',
  ScheduleCardType.reEnrollment: 'reEnrollment',
  ScheduleCardType.additionalInstrument: 'additionalInstrument',
};

const _$ScheduleCardStatusEnumMap = {
  ScheduleCardStatus.pending: 'pending',
  ScheduleCardStatus.confirmed: 'confirmed',
  ScheduleCardStatus.changedTime: 'changedTime',
  ScheduleCardStatus.dismissed: 'dismissed',
};
