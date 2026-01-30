// Group class booking entity for individual student bookings

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_class_booking.g.dart';

/// Booking status for group class bookings
@HiveType(typeId: 84)
enum GroupBookingStatus {
  @HiveField(0)
  confirmed, // Booking confirmed

  @HiveField(1)
  waitlist, // On waitlist

  @HiveField(2)
  attended, // Student attended the class

  @HiveField(3)
  noShow, // Student didn't show up

  @HiveField(4)
  cancelled, // Booking was cancelled

  @HiveField(5)
  autoCancelled, // Auto-cancelled (class started while on waitlist)
}

/// Individual booking for a group class schedule
@HiveType(typeId: 85)
@JsonSerializable()
class GroupClassBooking extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String scheduleId; // References GroupClassSchedule

  @HiveField(2)
  final String studentId;

  @HiveField(3)
  final String? subscriptionId; // For lesson deduction

  @HiveField(4)
  final GroupBookingStatus status;

  @HiveField(5)
  final int? waitlistPosition; // Position in waitlist (null if confirmed)

  @HiveField(6)
  final DateTime? attendedAt; // When attendance was marked

  @HiveField(7)
  final bool subscriptionDeducted; // Whether lesson was deducted

  @HiveField(8)
  final String? cancelReason;

  @HiveField(9)
  final DateTime? cancelledAt;

  @HiveField(10)
  final DateTime? promotedAt; // When promoted from waitlist to confirmed

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime? updatedAt;

  GroupClassBooking({
    required this.id,
    required this.scheduleId,
    required this.studentId,
    this.subscriptionId,
    required this.status,
    this.waitlistPosition,
    this.attendedAt,
    this.subscriptionDeducted = false,
    this.cancelReason,
    this.cancelledAt,
    this.promotedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory GroupClassBooking.fromJson(Map<String, dynamic> json) =>
      _$GroupClassBookingFromJson(json);

  Map<String, dynamic> toJson() => _$GroupClassBookingToJson(this);

  GroupClassBooking copyWith({
    String? id,
    String? scheduleId,
    String? studentId,
    String? subscriptionId,
    GroupBookingStatus? status,
    int? waitlistPosition,
    DateTime? attendedAt,
    bool? subscriptionDeducted,
    String? cancelReason,
    DateTime? cancelledAt,
    DateTime? promotedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupClassBooking(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      studentId: studentId ?? this.studentId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      status: status ?? this.status,
      waitlistPosition: waitlistPosition ?? this.waitlistPosition,
      attendedAt: attendedAt ?? this.attendedAt,
      subscriptionDeducted: subscriptionDeducted ?? this.subscriptionDeducted,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      promotedAt: promotedAt ?? this.promotedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if booking is on waitlist
  bool get isOnWaitlist => status == GroupBookingStatus.waitlist;

  /// Check if booking is confirmed
  bool get isConfirmed =>
      status == GroupBookingStatus.confirmed ||
      status == GroupBookingStatus.attended;

  /// Check if booking is active (not cancelled)
  bool get isActive =>
      status != GroupBookingStatus.cancelled &&
      status != GroupBookingStatus.autoCancelled;

  /// Check if booking can be cancelled
  bool get canCancel =>
      status == GroupBookingStatus.confirmed ||
      status == GroupBookingStatus.waitlist;

  /// Get status display text
  String get statusText {
    switch (status) {
      case GroupBookingStatus.confirmed:
        return '예약 확정';
      case GroupBookingStatus.waitlist:
        return '대기 ${waitlistPosition ?? ''}번';
      case GroupBookingStatus.attended:
        return '출석';
      case GroupBookingStatus.noShow:
        return '미참석';
      case GroupBookingStatus.cancelled:
        return '취소됨';
      case GroupBookingStatus.autoCancelled:
        return '자동 취소';
    }
  }

  /// Get status icon
  String get statusIcon {
    switch (status) {
      case GroupBookingStatus.confirmed:
        return '✅';
      case GroupBookingStatus.waitlist:
        return '⏳';
      case GroupBookingStatus.attended:
        return '🟢';
      case GroupBookingStatus.noShow:
        return '🔴';
      case GroupBookingStatus.cancelled:
        return '❌';
      case GroupBookingStatus.autoCancelled:
        return '⚠️';
    }
  }
}
