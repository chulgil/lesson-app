// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class_booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupClassBooking _$GroupClassBookingFromJson(Map<String, dynamic> json) =>
    GroupClassBooking(
      id: json['id'] as String,
      scheduleId: json['schedule_id'] as String,
      studentId: json['student_id'] as String,
      subscriptionId: json['subscription_id'] as String?,
      status: $enumDecode(_$GroupBookingStatusEnumMap, json['status']),
      waitlistPosition: (json['waitlist_position'] as num?)?.toInt(),
      attendedAt: json['attended_at'] == null
          ? null
          : DateTime.parse(json['attended_at'] as String),
      subscriptionDeducted: json['subscription_deducted'] as bool? ?? false,
      cancelReason: json['cancel_reason'] as String?,
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      promotedAt: json['promoted_at'] == null
          ? null
          : DateTime.parse(json['promoted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$GroupClassBookingToJson(GroupClassBooking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'schedule_id': instance.scheduleId,
      'student_id': instance.studentId,
      'subscription_id': instance.subscriptionId,
      'status': _$GroupBookingStatusEnumMap[instance.status]!,
      'waitlist_position': instance.waitlistPosition,
      'attended_at': instance.attendedAt?.toIso8601String(),
      'subscription_deducted': instance.subscriptionDeducted,
      'cancel_reason': instance.cancelReason,
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
      'promoted_at': instance.promotedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$GroupBookingStatusEnumMap = {
  GroupBookingStatus.confirmed: 'confirmed',
  GroupBookingStatus.waitlist: 'waitlist',
  GroupBookingStatus.attended: 'attended',
  GroupBookingStatus.noShow: 'noShow',
  GroupBookingStatus.cancelled: 'cancelled',
  GroupBookingStatus.autoCancelled: 'autoCancelled',
};
