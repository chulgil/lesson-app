// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupClassAdapter extends TypeAdapter<GroupClass> {
  @override
  final int typeId = 81;

  @override
  GroupClass read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupClass(
      id: fields[0] as String,
      teacherId: fields[1] as String,
      organizationId: fields[2] as String?,
      name: fields[3] as String,
      description: fields[4] as String?,
      type: fields[5] as GroupClassType,
      maxCapacity: fields[6] as int,
      waitlistCapacity: fields[7] as int?,
      durationMinutes: fields[8] as int,
      bookingDeadlineMinutes: fields[9] as int,
      cancelDeadlineMinutes: fields[10] as int,
      noShowPolicy: fields[11] as NoShowPolicy,
      maxNoShowCount: fields[12] as int?,
      repeatDaysOfWeek: (fields[13] as List?)?.cast<int>(),
      repeatTimeOfDay: fields[14] as String?,
      instrument: fields[15] as String?,
      pricePerSession: fields[16] as int?,
      isActive: fields[17] as bool,
      createdAt: fields[18] as DateTime,
      updatedAt: fields[19] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupClass obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teacherId)
      ..writeByte(2)
      ..write(obj.organizationId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.maxCapacity)
      ..writeByte(7)
      ..write(obj.waitlistCapacity)
      ..writeByte(8)
      ..write(obj.durationMinutes)
      ..writeByte(9)
      ..write(obj.bookingDeadlineMinutes)
      ..writeByte(10)
      ..write(obj.cancelDeadlineMinutes)
      ..writeByte(11)
      ..write(obj.noShowPolicy)
      ..writeByte(12)
      ..write(obj.maxNoShowCount)
      ..writeByte(13)
      ..write(obj.repeatDaysOfWeek)
      ..writeByte(14)
      ..write(obj.repeatTimeOfDay)
      ..writeByte(15)
      ..write(obj.instrument)
      ..writeByte(16)
      ..write(obj.pricePerSession)
      ..writeByte(17)
      ..write(obj.isActive)
      ..writeByte(18)
      ..write(obj.createdAt)
      ..writeByte(19)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupClassAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupClassTypeAdapter extends TypeAdapter<GroupClassType> {
  @override
  final int typeId = 80;

  @override
  GroupClassType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GroupClassType.regular;
      case 1:
        return GroupClassType.dropIn;
      default:
        return GroupClassType.regular;
    }
  }

  @override
  void write(BinaryWriter writer, GroupClassType obj) {
    switch (obj) {
      case GroupClassType.regular:
        writer.writeByte(0);
        break;
      case GroupClassType.dropIn:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupClassTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoShowPolicyAdapter extends TypeAdapter<NoShowPolicy> {
  @override
  final int typeId = 86;

  @override
  NoShowPolicy read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NoShowPolicy.deduct;
      case 1:
        return NoShowPolicy.noDeduct;
      default:
        return NoShowPolicy.deduct;
    }
  }

  @override
  void write(BinaryWriter writer, NoShowPolicy obj) {
    switch (obj) {
      case NoShowPolicy.deduct:
        writer.writeByte(0);
        break;
      case NoShowPolicy.noDeduct:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoShowPolicyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupClass _$GroupClassFromJson(Map<String, dynamic> json) => GroupClass(
      id: json['id'] as String,
      teacherId: json['teacherId'] as String,
      organizationId: json['organizationId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: $enumDecode(_$GroupClassTypeEnumMap, json['type']),
      maxCapacity: (json['maxCapacity'] as num).toInt(),
      waitlistCapacity: (json['waitlistCapacity'] as num?)?.toInt(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      bookingDeadlineMinutes:
          (json['bookingDeadlineMinutes'] as num?)?.toInt() ?? 60,
      cancelDeadlineMinutes:
          (json['cancelDeadlineMinutes'] as num?)?.toInt() ?? 1440,
      noShowPolicy:
          $enumDecodeNullable(_$NoShowPolicyEnumMap, json['noShowPolicy']) ??
              NoShowPolicy.deduct,
      maxNoShowCount: (json['maxNoShowCount'] as num?)?.toInt(),
      repeatDaysOfWeek: (json['repeatDaysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      repeatTimeOfDay: json['repeatTimeOfDay'] as String?,
      instrument: json['instrument'] as String?,
      pricePerSession: (json['pricePerSession'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$GroupClassToJson(GroupClass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacherId': instance.teacherId,
      'organizationId': instance.organizationId,
      'name': instance.name,
      'description': instance.description,
      'type': _$GroupClassTypeEnumMap[instance.type]!,
      'maxCapacity': instance.maxCapacity,
      'waitlistCapacity': instance.waitlistCapacity,
      'durationMinutes': instance.durationMinutes,
      'bookingDeadlineMinutes': instance.bookingDeadlineMinutes,
      'cancelDeadlineMinutes': instance.cancelDeadlineMinutes,
      'noShowPolicy': _$NoShowPolicyEnumMap[instance.noShowPolicy]!,
      'maxNoShowCount': instance.maxNoShowCount,
      'repeatDaysOfWeek': instance.repeatDaysOfWeek,
      'repeatTimeOfDay': instance.repeatTimeOfDay,
      'instrument': instance.instrument,
      'pricePerSession': instance.pricePerSession,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$GroupClassTypeEnumMap = {
  GroupClassType.regular: 'regular',
  GroupClassType.dropIn: 'dropIn',
};

const _$NoShowPolicyEnumMap = {
  NoShowPolicy.deduct: 'deduct',
  NoShowPolicy.noDeduct: 'noDeduct',
};
