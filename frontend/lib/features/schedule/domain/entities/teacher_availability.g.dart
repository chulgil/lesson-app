// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_availability.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TeacherAvailabilityAdapter extends TypeAdapter<TeacherAvailability> {
  @override
  final int typeId = 72;

  @override
  TeacherAvailability read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TeacherAvailability(
      id: fields[0] as String,
      teacherId: fields[1] as String,
      slotDurationMinutes: fields[2] as int,
      weeklySchedules: (fields[3] as List).cast<WeeklySchedule>(),
      exceptions: (fields[4] as List).cast<TimeException>(),
      autoGenerateWeeks: fields[5] as int,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime?,
      slotStartInterval: fields[8] as int,
      breakTimeBetweenLessons: fields[9] as int,
      minBookingHours: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TeacherAvailability obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teacherId)
      ..writeByte(2)
      ..write(obj.slotDurationMinutes)
      ..writeByte(3)
      ..write(obj.weeklySchedules)
      ..writeByte(4)
      ..write(obj.exceptions)
      ..writeByte(5)
      ..write(obj.autoGenerateWeeks)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.slotStartInterval)
      ..writeByte(9)
      ..write(obj.breakTimeBetweenLessons)
      ..writeByte(10)
      ..write(obj.minBookingHours);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherAvailabilityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeeklyScheduleAdapter extends TypeAdapter<WeeklySchedule> {
  @override
  final int typeId = 73;

  @override
  WeeklySchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklySchedule(
      id: fields[0] as String,
      dayOfWeek: fields[1] as int,
      startTime: fields[2] as String,
      endTime: fields[3] as String,
      isActive: fields[4] as bool,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklySchedule obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dayOfWeek)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimeExceptionAdapter extends TypeAdapter<TimeException> {
  @override
  final int typeId = 75;

  @override
  TimeException read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeException(
      id: fields[0] as String,
      type: fields[1] as ExceptionType,
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime,
      startTime: fields[4] as String?,
      endTime: fields[5] as String?,
      reason: fields[6] as String?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TimeException obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.reason)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeExceptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AvailabilityTypeAdapter extends TypeAdapter<AvailabilityType> {
  @override
  final int typeId = 70;

  @override
  AvailabilityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AvailabilityType.regular;
      case 1:
        return AvailabilityType.oneTime;
      default:
        return AvailabilityType.regular;
    }
  }

  @override
  void write(BinaryWriter writer, AvailabilityType obj) {
    switch (obj) {
      case AvailabilityType.regular:
        writer.writeByte(0);
        break;
      case AvailabilityType.oneTime:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SlotStatusAdapter extends TypeAdapter<SlotStatus> {
  @override
  final int typeId = 71;

  @override
  SlotStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SlotStatus.available;
      case 1:
        return SlotStatus.booked;
      case 2:
        return SlotStatus.cancelled;
      default:
        return SlotStatus.available;
    }
  }

  @override
  void write(BinaryWriter writer, SlotStatus obj) {
    switch (obj) {
      case SlotStatus.available:
        writer.writeByte(0);
        break;
      case SlotStatus.booked:
        writer.writeByte(1);
        break;
      case SlotStatus.cancelled:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExceptionTypeAdapter extends TypeAdapter<ExceptionType> {
  @override
  final int typeId = 74;

  @override
  ExceptionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExceptionType.holiday;
      case 1:
        return ExceptionType.vacation;
      case 2:
        return ExceptionType.additionalSlot;
      default:
        return ExceptionType.holiday;
    }
  }

  @override
  void write(BinaryWriter writer, ExceptionType obj) {
    switch (obj) {
      case ExceptionType.holiday:
        writer.writeByte(0);
        break;
      case ExceptionType.vacation:
        writer.writeByte(1);
        break;
      case ExceptionType.additionalSlot:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExceptionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherAvailability _$TeacherAvailabilityFromJson(Map<String, dynamic> json) =>
    TeacherAvailability(
      id: json['id'] as String,
      teacherId: json['teacherId'] as String,
      slotDurationMinutes: (json['slotDurationMinutes'] as num?)?.toInt() ?? 60,
      weeklySchedules: (json['weeklySchedules'] as List<dynamic>?)
              ?.map((e) => WeeklySchedule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      exceptions: (json['exceptions'] as List<dynamic>?)
              ?.map((e) => TimeException.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      autoGenerateWeeks: (json['autoGenerateWeeks'] as num?)?.toInt() ?? 4,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      slotStartInterval: (json['slotStartInterval'] as num?)?.toInt() ?? 30,
      breakTimeBetweenLessons:
          (json['breakTimeBetweenLessons'] as num?)?.toInt() ?? 0,
      minBookingHours: (json['minBookingHours'] as num?)?.toInt() ?? 24,
    );

Map<String, dynamic> _$TeacherAvailabilityToJson(
        TeacherAvailability instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacherId': instance.teacherId,
      'slotDurationMinutes': instance.slotDurationMinutes,
      'weeklySchedules': instance.weeklySchedules,
      'exceptions': instance.exceptions,
      'autoGenerateWeeks': instance.autoGenerateWeeks,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'slotStartInterval': instance.slotStartInterval,
      'breakTimeBetweenLessons': instance.breakTimeBetweenLessons,
      'minBookingHours': instance.minBookingHours,
    };

WeeklySchedule _$WeeklyScheduleFromJson(Map<String, dynamic> json) =>
    WeeklySchedule(
      id: json['id'] as String,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WeeklyScheduleToJson(WeeklySchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dayOfWeek': instance.dayOfWeek,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

TimeException _$TimeExceptionFromJson(Map<String, dynamic> json) =>
    TimeException(
      id: json['id'] as String,
      type: $enumDecode(_$ExceptionTypeEnumMap, json['type']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TimeExceptionToJson(TimeException instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ExceptionTypeEnumMap[instance.type]!,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'reason': instance.reason,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ExceptionTypeEnumMap = {
  ExceptionType.holiday: 'holiday',
  ExceptionType.vacation: 'vacation',
  ExceptionType.additionalSlot: 'additionalSlot',
};
