// Group class booking entity for individual student bookings

import 'package:json_annotation/json_annotation.dart';

part 'group_class_booking.g.dart';

/// Booking status for group class bookings
enum GroupBookingStatus {
  confirmed, // Booking confirmed

  waitlist, // On waitlist

  attended, // Student attended the class

  noShow, // Student didn't show up

  cancelled, // Booking was cancelled

  autoCancelled, // Auto-cancelled (class started while on waitlist)
}

/// Individual booking for a group class schedule
@JsonSerializable()
class GroupClassBooking {
  final String id;

  final String scheduleId; // References GroupClassSchedule

  final String studentId;

  final String? subscriptionId; // For lesson deduction

  final GroupBookingStatus status;

  final int? waitlistPosition; // Position in waitlist (null if confirmed)

  final DateTime? attendedAt; // When attendance was marked

  final bool subscriptionDeducted; // Whether lesson was deducted

  final String? cancelReason;

  final DateTime? cancelledAt;

  final DateTime? promotedAt; // When promoted from waitlist to confirmed

  final DateTime createdAt;

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
}
