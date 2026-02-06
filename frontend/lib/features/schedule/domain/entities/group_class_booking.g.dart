// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class_booking.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupClassBookingAdapter extends TypeAdapter<GroupClassBooking> {
  @override
  final int typeId = 85;

  @override
  GroupClassBooking read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupClassBooking(
      id: fields[0] as String,
      scheduleId: fields[1] as String,
      studentId: fields[2] as String,
      subscriptionId: fields[3] as String?,
      status: fields[4] as GroupBookingStatus,
      waitlistPosition: fields[5] as int?,
      attendedAt: fields[6] as DateTime?,
      subscriptionDeducted: fields[7] as bool,
      cancelReason: fields[8] as String?,
      cancelledAt: fields[9] as DateTime?,
      promotedAt: fields[10] as DateTime?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupClassBooking obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scheduleId)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.subscriptionId)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.waitlistPosition)
      ..writeByte(6)
      ..write(obj.attendedAt)
      ..writeByte(7)
      ..write(obj.subscriptionDeducted)
      ..writeByte(8)
      ..write(obj.cancelReason)
      ..writeByte(9)
      ..write(obj.cancelledAt)
      ..writeByte(10)
      ..write(obj.promotedAt)
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
      other is GroupClassBookingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupBookingStatusAdapter extends TypeAdapter<GroupBookingStatus> {
  @override
  final int typeId = 84;

  @override
  GroupBookingStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GroupBookingStatus.confirmed;
      case 1:
        return GroupBookingStatus.waitlist;
      case 2:
        return GroupBookingStatus.attended;
      case 3:
        return GroupBookingStatus.noShow;
      case 4:
        return GroupBookingStatus.cancelled;
      case 5:
        return GroupBookingStatus.autoCancelled;
      default:
        return GroupBookingStatus.confirmed;
    }
  }

  @override
  void write(BinaryWriter writer, GroupBookingStatus obj) {
    switch (obj) {
      case GroupBookingStatus.confirmed:
        writer.writeByte(0);
        break;
      case GroupBookingStatus.waitlist:
        writer.writeByte(1);
        break;
      case GroupBookingStatus.attended:
        writer.writeByte(2);
        break;
      case GroupBookingStatus.noShow:
        writer.writeByte(3);
        break;
      case GroupBookingStatus.cancelled:
        writer.writeByte(4);
        break;
      case GroupBookingStatus.autoCancelled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupBookingStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupClassBooking _$GroupClassBookingFromJson(Map<String, dynamic> json) =>
    GroupClassBooking(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      studentId: json['studentId'] as String,
      subscriptionId: json['subscriptionId'] as String?,
      status: $enumDecode(_$GroupBookingStatusEnumMap, json['status']),
      waitlistPosition: (json['waitlistPosition'] as num?)?.toInt(),
      attendedAt: json['attendedAt'] == null
          ? null
          : DateTime.parse(json['attendedAt'] as String),
      subscriptionDeducted: json['subscriptionDeducted'] as bool? ?? false,
      cancelReason: json['cancelReason'] as String?,
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      promotedAt: json['promotedAt'] == null
          ? null
          : DateTime.parse(json['promotedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$GroupClassBookingToJson(GroupClassBooking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheduleId': instance.scheduleId,
      'studentId': instance.studentId,
      'subscriptionId': instance.subscriptionId,
      'status': _$GroupBookingStatusEnumMap[instance.status]!,
      'waitlistPosition': instance.waitlistPosition,
      'attendedAt': instance.attendedAt?.toIso8601String(),
      'subscriptionDeducted': instance.subscriptionDeducted,
      'cancelReason': instance.cancelReason,
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
      'promotedAt': instance.promotedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$GroupBookingStatusEnumMap = {
  GroupBookingStatus.confirmed: 'confirmed',
  GroupBookingStatus.waitlist: 'waitlist',
  GroupBookingStatus.attended: 'attended',
  GroupBookingStatus.noShow: 'noShow',
  GroupBookingStatus.cancelled: 'cancelled',
  GroupBookingStatus.autoCancelled: 'autoCancelled',
};
