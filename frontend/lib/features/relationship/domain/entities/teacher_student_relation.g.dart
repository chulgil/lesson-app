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
      teacherId: json['teacher_id'] as String,
      studentId: json['student_id'] as String,
      status: $enumDecode(_$RelationshipStatusEnumMap, json['status']),
      activeSubscriptionId: json['active_subscription_id'] as String?,
      lastSubscriptionExpiredAt: json['last_subscription_expired_at'] == null
          ? null
          : DateTime.parse(json['last_subscription_expired_at'] as String),
      expiredUntil: json['expired_until'] == null
          ? null
          : DateTime.parse(json['expired_until'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      trialBookingId: json['trial_booking_id'] as String?,
      totalLessonCount: (json['total_lesson_count'] as num?)?.toInt() ?? 0,
      lastLessonAt: json['last_lesson_at'] == null
          ? null
          : DateTime.parse(json['last_lesson_at'] as String),
      terminatedBy: json['terminated_by'] as String?,
      terminationReason: json['termination_reason'] as String?,
      isManuallyRegistered: json['is_manually_registered'] as bool? ?? false,
      isAppConnected: json['is_app_connected'] as bool? ?? true,
      appConnectedAt: json['app_connected_at'] == null
          ? null
          : DateTime.parse(json['app_connected_at'] as String),
      lastLessonDay: (json['last_lesson_day'] as num?)?.toInt(),
      lastLessonTime: json['last_lesson_time'] as String?,
      lastLessonDuration: (json['last_lesson_duration'] as num?)?.toInt(),
      lastScheduleRecordedAt: json['last_schedule_recorded_at'] == null
          ? null
          : DateTime.parse(json['last_schedule_recorded_at'] as String),
    );

Map<String, dynamic> _$TeacherStudentRelationToJson(
        TeacherStudentRelation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacher_id': instance.teacherId,
      'student_id': instance.studentId,
      'status': _$RelationshipStatusEnumMap[instance.status]!,
      'active_subscription_id': instance.activeSubscriptionId,
      'last_subscription_expired_at':
          instance.lastSubscriptionExpiredAt?.toIso8601String(),
      'expired_until': instance.expiredUntil?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'trial_booking_id': instance.trialBookingId,
      'total_lesson_count': instance.totalLessonCount,
      'last_lesson_at': instance.lastLessonAt?.toIso8601String(),
      'terminated_by': instance.terminatedBy,
      'termination_reason': instance.terminationReason,
      'is_manually_registered': instance.isManuallyRegistered,
      'is_app_connected': instance.isAppConnected,
      'app_connected_at': instance.appConnectedAt?.toIso8601String(),
      'last_lesson_day': instance.lastLessonDay,
      'last_lesson_time': instance.lastLessonTime,
      'last_lesson_duration': instance.lastLessonDuration,
      'last_schedule_recorded_at':
          instance.lastScheduleRecordedAt?.toIso8601String(),
    };

const _$RelationshipStatusEnumMap = {
  RelationshipStatus.trialBooked: 'trialBooked',
  RelationshipStatus.active: 'active',
  RelationshipStatus.expired: 'expired',
  RelationshipStatus.past: 'past',
};
