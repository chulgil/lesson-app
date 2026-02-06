// Group class schedule entity for individual class sessions

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_class_schedule.g.dart';

/// Schedule status for group class sessions
@HiveType(typeId: 82)
enum ScheduleStatus {
  @HiveField(0)
  open, // Available for booking

  @HiveField(1)
  full, // At capacity, waitlist may be available

  @HiveField(2)
  closed, // No longer accepting bookings

  @HiveField(3)
  cancelled, // Class was cancelled

  @HiveField(4)
  completed, // Class has finished

  @HiveField(5)
  inProgress, // Class is currently in session
}

/// Individual group class schedule (session)
@HiveType(typeId: 83)
@JsonSerializable()
class GroupClassSchedule extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String groupClassId;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  final DateTime endTime;

  @HiveField(4)
  final ScheduleStatus status;

  @HiveField(5)
  final int currentBookings; // Current confirmed bookings

  @HiveField(6)
  final int waitlistCount; // Current waitlist count

  @HiveField(7)
  final int maxCapacity; // Copied from GroupClass for convenience

  @HiveField(8)
  final int? waitlistCapacity; // Copied from GroupClass

  @HiveField(9)
  final String? notes; // Any notes for this specific session

  @HiveField(10)
  final String? cancelReason; // Reason if cancelled

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
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
