// Group class schedule entity for individual class sessions

import 'package:json_annotation/json_annotation.dart';

part 'group_class_schedule.g.dart';

/// Schedule status for group class sessions
enum ScheduleStatus {
  open, // Available for booking

  full, // At capacity, waitlist may be available

  closed, // No longer accepting bookings

  cancelled, // Class was cancelled

  completed, // Class has finished

  inProgress, // Class is currently in session
}

/// Individual group class schedule (session)
@JsonSerializable()
class GroupClassSchedule {
  final String id;

  final String groupClassId;

  final DateTime startTime;

  final DateTime endTime;

  final ScheduleStatus status;

  final int currentBookings; // Current confirmed bookings

  final int waitlistCount; // Current waitlist count

  final int maxCapacity; // Copied from GroupClass for convenience

  final int? waitlistCapacity; // Copied from GroupClass

  final String? notes; // Any notes for this specific session

  final String? cancelReason; // Reason if cancelled

  final DateTime createdAt;

  final DateTime? updatedAt;

  GroupClassSchedule({
    required this.id,
    required this.groupClassId,
    required this.startTime,
    required this.endTime,
    this.status = ScheduleStatus.open,
    this.currentBookings = 0,
    this.waitlistCount = 0,
    required this.maxCapacity,
    this.waitlistCapacity,
    this.notes,
    this.cancelReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory GroupClassSchedule.fromJson(Map<String, dynamic> json) =>
      _$GroupClassScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$GroupClassScheduleToJson(this);

  GroupClassSchedule copyWith({
    String? id,
    String? groupClassId,
    DateTime? startTime,
    DateTime? endTime,
    ScheduleStatus? status,
    int? currentBookings,
    int? waitlistCount,
    int? maxCapacity,
    int? waitlistCapacity,
    String? notes,
    String? cancelReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupClassSchedule(
      id: id ?? this.id,
      groupClassId: groupClassId ?? this.groupClassId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      currentBookings: currentBookings ?? this.currentBookings,
      waitlistCount: waitlistCount ?? this.waitlistCount,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      waitlistCapacity: waitlistCapacity ?? this.waitlistCapacity,
      notes: notes ?? this.notes,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if booking is allowed
  bool get canBook =>
      status == ScheduleStatus.open && currentBookings < maxCapacity;

  /// Check if waitlist is allowed
  bool get canWaitlist {
    if (status != ScheduleStatus.open && status != ScheduleStatus.full) {
      return false;
    }
    if (currentBookings < maxCapacity) {
      return false; // Can still book directly
    }
    if (waitlistCapacity == null) {
      return true; // Unlimited waitlist
    }
    return waitlistCount < waitlistCapacity!;
  }

  /// Get available spots
  int get availableSpots => maxCapacity - currentBookings;

  /// Check if class is full (no direct booking possible)
  bool get isFull => currentBookings >= maxCapacity;

  /// Check if class has started
  bool get hasStarted => DateTime.now().isAfter(startTime);

  /// Check if class has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Get capacity text (e.g., "4/6명")
  String get capacityText => '$currentBookings/$maxCapacity명';

  /// Get status display text
  String get statusText {
    switch (status) {
      case ScheduleStatus.open:
        if (isFull) return '만석';
        if (availableSpots <= 2) return '마감임박';
        return '예약가능';
      case ScheduleStatus.full:
        return '만석';
      case ScheduleStatus.closed:
        return '마감';
      case ScheduleStatus.cancelled:
        return '취소됨';
      case ScheduleStatus.completed:
        return '완료';
      case ScheduleStatus.inProgress:
        return '수업중';
    }
  }

  /// Get formatted date text
  String get dateText {
    final weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
    return '${startTime.month}/${startTime.day}(${weekdays[startTime.weekday]})';
  }

  /// Get formatted time text
  String get timeText {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMin = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMin = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMin ~ $endHour:$endMin';
  }
}
