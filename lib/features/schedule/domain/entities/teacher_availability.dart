import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teacher_availability.g.dart';

/// Type of availability slot
@HiveType(typeId: 70)
enum AvailabilityType {
  @HiveField(0)
  regular, // Weekly recurring

  @HiveField(1)
  oneTime, // One-time slot
}

/// Status of a time slot
@HiveType(typeId: 71)
enum SlotStatus {
  @HiveField(0)
  available, // Can be booked

  @HiveField(1)
  booked, // Already booked

  @HiveField(2)
  cancelled, // Cancelled (holiday, etc.)
}

/// Teacher availability settings
///
/// Root entity for managing teacher's available time slots.
/// Contains weekly schedules and exceptions (holidays, etc.).
@HiveType(typeId: 72)
@JsonSerializable()
class TeacherAvailability extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  /// Default lesson duration in minutes (30, 45, 60)
  @HiveField(2)
  final int slotDurationMinutes;

  /// Weekly recurring schedules
  @HiveField(3)
  final List<WeeklySchedule> weeklySchedules;

  /// Exceptions (holidays, special closures)
  @HiveField(4)
  final List<TimeException> exceptions;

  /// Number of weeks to auto-generate slots
  @HiveField(5)
  final int autoGenerateWeeks;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  TeacherAvailability({
    required this.id,
    required this.teacherId,
    this.slotDurationMinutes = 60,
    this.weeklySchedules = const [],
    this.exceptions = const [],
    this.autoGenerateWeeks = 4,
    required this.createdAt,
    this.updatedAt,
  });

  factory TeacherAvailability.fromJson(Map<String, dynamic> json) =>
      _$TeacherAvailabilityFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherAvailabilityToJson(this);

  TeacherAvailability copyWith({
    String? id,
    String? teacherId,
    int? slotDurationMinutes,
    List<WeeklySchedule>? weeklySchedules,
    List<TimeException>? exceptions,
    int? autoGenerateWeeks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherAvailability(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      weeklySchedules: weeklySchedules ?? this.weeklySchedules,
      exceptions: exceptions ?? this.exceptions,
      autoGenerateWeeks: autoGenerateWeeks ?? this.autoGenerateWeeks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Weekly recurring schedule template
@HiveType(typeId: 73)
@JsonSerializable()
class WeeklySchedule extends HiveObject {
  @HiveField(0)
  final String id;

  /// Day of week (0=Monday, 6=Sunday)
  @HiveField(1)
  final int dayOfWeek;

  /// Start time in "HH:mm" format (e.g., "14:00")
  @HiveField(2)
  final String startTime;

  /// End time in "HH:mm" format (e.g., "18:00")
  @HiveField(3)
  final String endTime;

  /// Whether this schedule is active
  @HiveField(4)
  final bool isActive;

  @HiveField(5)
  final DateTime createdAt;

  WeeklySchedule({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    required this.createdAt,
  });

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) =>
      _$WeeklyScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyScheduleToJson(this);

  WeeklySchedule copyWith({
    String? id,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return WeeklySchedule(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get day name in Korean
  String get dayName {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    if (dayOfWeek >= 0 && dayOfWeek < 7) {
      return days[dayOfWeek];
    }
    return '';
  }
}

/// Exception type for time exceptions
@HiveType(typeId: 74)
enum ExceptionType {
  @HiveField(0)
  holiday, // Single day holiday

  @HiveField(1)
  vacation, // Multi-day vacation

  @HiveField(2)
  additionalSlot, // Extra one-time slot
}

/// Extension for ExceptionType display names
extension ExceptionTypeExtension on ExceptionType {
  String get displayName {
    switch (this) {
      case ExceptionType.holiday:
        return '휴무';
      case ExceptionType.vacation:
        return '휴가';
      case ExceptionType.additionalSlot:
        return '추가 오픈';
    }
  }
}

/// Time exception (holiday, vacation, or additional slot)
@HiveType(typeId: 75)
@JsonSerializable()
class TimeException extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ExceptionType type;

  /// Start date of exception
  @HiveField(2)
  final DateTime startDate;

  /// End date (same as startDate for single day)
  @HiveField(3)
  final DateTime endDate;

  /// Optional specific time for additionalSlot type
  @HiveField(4)
  final String? startTime;

  @HiveField(5)
  final String? endTime;

  /// Reason for the exception
  @HiveField(6)
  final String? reason;

  @HiveField(7)
  final DateTime createdAt;

  TimeException({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    this.reason,
    required this.createdAt,
  });

  factory TimeException.fromJson(Map<String, dynamic> json) =>
      _$TimeExceptionFromJson(json);

  Map<String, dynamic> toJson() => _$TimeExceptionToJson(this);

  TimeException copyWith({
    String? id,
    ExceptionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? reason,
    DateTime? createdAt,
  }) {
    return TimeException(
      id: id ?? this.id,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if a date falls within this exception
  bool containsDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly =
        DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }
}
