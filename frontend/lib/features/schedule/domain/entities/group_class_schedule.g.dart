// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class_schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupClassScheduleAdapter extends TypeAdapter<GroupClassSchedule> {
  @override
  final int typeId = 83;

  @override
  GroupClassSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupClassSchedule(
      id: fields[0] as String,
      groupClassId: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime,
      status: fields[4] as ScheduleStatus,
      currentBookings: fields[5] as int,
      waitlistCount: fields[6] as int,
      maxCapacity: fields[7] as int,
      waitlistCapacity: fields[8] as int?,
      notes: fields[9] as String?,
      cancelReason: fields[10] as String?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupClassSchedule obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupClassId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.currentBookings)
      ..writeByte(6)
      ..write(obj.waitlistCount)
      ..writeByte(7)
      ..write(obj.maxCapacity)
      ..writeByte(8)
      ..write(obj.waitlistCapacity)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.cancelReason)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupClassScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleStatusAdapter extends TypeAdapter<ScheduleStatus> {
  @override
  final int typeId = 82;

  @override
  ScheduleStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduleStatus.open;
      case 1:
        return ScheduleStatus.full;
      case 2:
        return ScheduleStatus.closed;
      case 3:
        return ScheduleStatus.cancelled;
      case 4:
        return ScheduleStatus.completed;
      case 5:
        return ScheduleStatus.inProgress;
      default:
        return ScheduleStatus.open;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduleStatus obj) {
    switch (obj) {
      case ScheduleStatus.open:
        writer.writeByte(0);
        break;
      case ScheduleStatus.full:
        writer.writeByte(1);
        break;
      case ScheduleStatus.closed:
        writer.writeByte(2);
        break;
      case ScheduleStatus.cancelled:
        writer.writeByte(3);
        break;
      case ScheduleStatus.completed:
        writer.writeByte(4);
        break;
      case ScheduleStatus.inProgress:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupClassSchedule _$GroupClassScheduleFromJson(Map<String, dynamic> json) =>
    GroupClassSchedule(
      id: json['id'] as String,
      groupClassId: json['groupClassId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: $enumDecodeNullable(_$ScheduleStatusEnumMap, json['status']) ??
          ScheduleStatus.open,
      currentBookings: (json['currentBookings'] as num?)?.toInt() ?? 0,
      waitlistCount: (json['waitlistCount'] as num?)?.toInt() ?? 0,
      maxCapacity: (json['maxCapacity'] as num).toInt(),
      waitlistCapacity: (json['waitlistCapacity'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      cancelReason: json['cancelReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$GroupClassScheduleToJson(GroupClassSchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupClassId': instance.groupClassId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'status': _$ScheduleStatusEnumMap[instance.status]!,
      'currentBookings': instance.currentBookings,
      'waitlistCount': instance.waitlistCount,
      'maxCapacity': instance.maxCapacity,
      'waitlistCapacity': instance.waitlistCapacity,
      'notes': instance.notes,
      'cancelReason': instance.cancelReason,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$ScheduleStatusEnumMap = {
  ScheduleStatus.open: 'open',
  ScheduleStatus.full: 'full',
  ScheduleStatus.closed: 'closed',
  ScheduleStatus.cancelled: 'cancelled',
  ScheduleStatus.completed: 'completed',
  ScheduleStatus.inProgress: 'inProgress',
};
