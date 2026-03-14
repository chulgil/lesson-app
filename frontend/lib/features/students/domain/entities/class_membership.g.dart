// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_membership.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassMembershipAdapter extends TypeAdapter<ClassMembership> {
  @override
  final int typeId = 54;

  @override
  ClassMembership read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassMembership(
      id: fields[0] as String,
      lessonClassId: fields[1] as String,
      studentId: fields[2] as String,
      instrument: fields[3] as String,
      status: fields[4] as MembershipStatus,
      level: fields[5] as String?,
      monthlyFee: fields[6] as int,
      lessonsPerWeek: fields[7] as int,
      lessonDay: fields[8] as String?,
      lessonTime: fields[9] as String?,
      lessonDuration: fields[10] as int,
      notes: fields[11] as String?,
      lessonLocationId: fields[14] as String?,
      travelTimeMinutes: fields[15] as int,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ClassMembership obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lessonClassId)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.instrument)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.monthlyFee)
      ..writeByte(7)
      ..write(obj.lessonsPerWeek)
      ..writeByte(8)
      ..write(obj.lessonDay)
      ..writeByte(9)
      ..write(obj.lessonTime)
      ..writeByte(10)
      ..write(obj.lessonDuration)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.lessonLocationId)
      ..writeByte(15)
      ..write(obj.travelTimeMinutes)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassMembershipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MembershipStatusAdapter extends TypeAdapter<MembershipStatus> {
  @override
  final int typeId = 53;

  @override
  MembershipStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MembershipStatus.trial;
      case 1:
        return MembershipStatus.active;
      case 2:
        return MembershipStatus.paused;
      case 3:
        return MembershipStatus.terminated;
      default:
        return MembershipStatus.trial;
    }
  }

  @override
  void write(BinaryWriter writer, MembershipStatus obj) {
    switch (obj) {
      case MembershipStatus.trial:
        writer.writeByte(0);
        break;
      case MembershipStatus.active:
        writer.writeByte(1);
        break;
      case MembershipStatus.paused:
        writer.writeByte(2);
        break;
      case MembershipStatus.terminated:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MembershipStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassMembership _$ClassMembershipFromJson(Map<String, dynamic> json) =>
    ClassMembership(
      id: json['id'] as String,
      lessonClassId: json['lesson_class_id'] as String,
      studentId: json['student_id'] as String,
      instrument: json['instrument'] as String,
      status: $enumDecode(_$MembershipStatusEnumMap, json['status']),
      level: json['level'] as String?,
      monthlyFee: (json['monthly_fee'] as num).toInt(),
      lessonsPerWeek: (json['lessons_per_week'] as num?)?.toInt() ?? 1,
      lessonDay: json['lesson_day'] as String?,
      lessonTime: json['lesson_time'] as String?,
      lessonDuration: (json['lesson_duration'] as num?)?.toInt() ?? 60,
      notes: json['notes'] as String?,
      lessonLocationId: json['lesson_location_id'] as String?,
      travelTimeMinutes: (json['travel_time_minutes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ClassMembershipToJson(ClassMembership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lesson_class_id': instance.lessonClassId,
      'student_id': instance.studentId,
      'instrument': instance.instrument,
      'status': _$MembershipStatusEnumMap[instance.status]!,
      'level': instance.level,
      'monthly_fee': instance.monthlyFee,
      'lessons_per_week': instance.lessonsPerWeek,
      'lesson_day': instance.lessonDay,
      'lesson_time': instance.lessonTime,
      'lesson_duration': instance.lessonDuration,
      'notes': instance.notes,
      'lesson_location_id': instance.lessonLocationId,
      'travel_time_minutes': instance.travelTimeMinutes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$MembershipStatusEnumMap = {
  MembershipStatus.trial: 'trial',
  MembershipStatus.active: 'active',
  MembershipStatus.paused: 'paused',
  MembershipStatus.terminated: 'terminated',
};
