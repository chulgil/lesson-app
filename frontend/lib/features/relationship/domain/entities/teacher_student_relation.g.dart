// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_student_relation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TeacherStudentRelationAdapter
    extends TypeAdapter<TeacherStudentRelation> {
  @override
  final int typeId = 90;

  @override
  TeacherStudentRelation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TeacherStudentRelation(
      id: fields[0] as String,
      teacherId: fields[1] as String,
      studentId: fields[2] as String,
      status: fields[3] as RelationshipStatus,
      activeSubscriptionId: fields[4] as String?,
      lastSubscriptionExpiredAt: fields[5] as DateTime?,
      expiredUntil: fields[6] as DateTime?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      trialBookingId: fields[9] as String?,
      totalLessonCount: fields[10] as int,
      lastLessonAt: fields[11] as DateTime?,
      terminatedBy: fields[12] as String?,
      terminationReason: fields[13] as String?,
      isManuallyRegistered: fields[14] as bool,
      isAppConnected: fields[15] as bool,
      appConnectedAt: fields[16] as DateTime?,
      lastLessonDay: fields[17] as int?,
      lastLessonTime: fields[18] as String?,
      lastLessonDuration: fields[19] as int?,
      lastScheduleRecordedAt: fields[20] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TeacherStudentRelation obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teacherId)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.activeSubscriptionId)
      ..writeByte(5)
      ..write(obj.lastSubscriptionExpiredAt)
      ..writeByte(6)
      ..write(obj.expiredUntil)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.trialBookingId)
      ..writeByte(10)
      ..write(obj.totalLessonCount)
      ..writeByte(11)
      ..write(obj.lastLessonAt)
      ..writeByte(12)
      ..write(obj.terminatedBy)
      ..writeByte(13)
      ..write(obj.terminationReason)
      ..writeByte(14)
      ..write(obj.isManuallyRegistered)
      ..writeByte(15)
      ..write(obj.isAppConnected)
      ..writeByte(16)
      ..write(obj.appConnectedAt)
      ..writeByte(17)
      ..write(obj.lastLessonDay)
      ..writeByte(18)
      ..write(obj.lastLessonTime)
      ..writeByte(19)
      ..write(obj.lastLessonDuration)
      ..writeByte(20)
      ..write(obj.lastScheduleRecordedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherStudentRelationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherStudentRelation _$TeacherStudentRelationFromJson(
        Map<String, dynamic> json) =>
    TeacherStudentRelation(
      id: json['id'] as String,
      teacherId: json['teacherId'] as String,
      studentId: json['studentId'] as String,
      status: $enumDecode(_$RelationshipStatusEnumMap, json['status']),
      activeSubscriptionId: json['activeSubscriptionId'] as String?,
      lastSubscriptionExpiredAt: json['lastSubscriptionExpiredAt'] == null
          ? null
          : DateTime.parse(json['lastSubscriptionExpiredAt'] as String),
      expiredUntil: json['expiredUntil'] == null
          ? null
          : DateTime.parse(json['expiredUntil'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      trialBookingId: json['trialBookingId'] as String?,
      totalLessonCount: (json['totalLessonCount'] as num?)?.toInt() ?? 0,
      lastLessonAt: json['lastLessonAt'] == null
          ? null
          : DateTime.parse(json['lastLessonAt'] as String),
      terminatedBy: json['terminatedBy'] as String?,
      terminationReason: json['terminationReason'] as String?,
      isManuallyRegistered: json['isManuallyRegistered'] as bool? ?? false,
      isAppConnected: json['isAppConnected'] as bool? ?? true,
      appConnectedAt: json['appConnectedAt'] == null
          ? null
          : DateTime.parse(json['appConnectedAt'] as String),
      lastLessonDay: (json['lastLessonDay'] as num?)?.toInt(),
      lastLessonTime: json['lastLessonTime'] as String?,
      lastLessonDuration: (json['lastLessonDuration'] as num?)?.toInt(),
      lastScheduleRecordedAt: json['lastScheduleRecordedAt'] == null
          ? null
          : DateTime.parse(json['lastScheduleRecordedAt'] as String),
    );

Map<String, dynamic> _$TeacherStudentRelationToJson(
        TeacherStudentRelation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacherId': instance.teacherId,
      'studentId': instance.studentId,
      'status': _$RelationshipStatusEnumMap[instance.status]!,
      'activeSubscriptionId': instance.activeSubscriptionId,
      'lastSubscriptionExpiredAt':
          instance.lastSubscriptionExpiredAt?.toIso8601String(),
      'expiredUntil': instance.expiredUntil?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'trialBookingId': instance.trialBookingId,
      'totalLessonCount': instance.totalLessonCount,
      'lastLessonAt': instance.lastLessonAt?.toIso8601String(),
      'terminatedBy': instance.terminatedBy,
      'terminationReason': instance.terminationReason,
      'isManuallyRegistered': instance.isManuallyRegistered,
      'isAppConnected': instance.isAppConnected,
      'appConnectedAt': instance.appConnectedAt?.toIso8601String(),
      'lastLessonDay': instance.lastLessonDay,
      'lastLessonTime': instance.lastLessonTime,
      'lastLessonDuration': instance.lastLessonDuration,
      'lastScheduleRecordedAt':
          instance.lastScheduleRecordedAt?.toIso8601String(),
    };

const _$RelationshipStatusEnumMap = {
  RelationshipStatus.trialBooked: 'trialBooked',
  RelationshipStatus.active: 'active',
  RelationshipStatus.expired: 'expired',
  RelationshipStatus.past: 'past',
};
