import '../../../../core/domain/value_objects/clock_time.dart';

/// Computed availability slot for UI display
///
/// This is a UI-focused model computed from TeacherAvailability.
/// Not persisted to Hive - computed on demand.
class AvailabilitySlot {
  final String id;
  final String teacherId;
  final DateTime date;
  final ClockTime startTime;
  final ClockTime endTime;
  final int durationMinutes;
  final AvailabilitySlotStatus status;

  /// Student ID if booked
  final String? bookedByStudentId;

  /// Student name if booked
  final String? bookedByStudentName;

  /// Lesson ID if linked
  final String? lessonId;

  /// Whether this is a recommended time (student's usual time)
  final bool isRecommended;

  /// Travel time for the booked student (copied from ClassMembership)
  final int travelTimeMinutes;

  const AvailabilitySlot({
    required this.id,
    required this.teacherId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.status = AvailabilitySlotStatus.available,
    this.bookedByStudentId,
    this.bookedByStudentName,
    this.lessonId,
    this.isRecommended = false,
    this.travelTimeMinutes = 0,
  });

  AvailabilitySlot copyWith({
    String? id,
    String? teacherId,
    DateTime? date,
    ClockTime? startTime,
    ClockTime? endTime,
    int? durationMinutes,
    AvailabilitySlotStatus? status,
    String? bookedByStudentId,
    String? bookedByStudentName,
    String? lessonId,
    bool? isRecommended,
    int? travelTimeMinutes,
  }) {
    return AvailabilitySlot(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      bookedByStudentId: bookedByStudentId ?? this.bookedByStudentId,
      bookedByStudentName: bookedByStudentName ?? this.bookedByStudentName,
      lessonId: lessonId ?? this.lessonId,
      isRecommended: isRecommended ?? this.isRecommended,
      travelTimeMinutes: travelTimeMinutes ?? this.travelTimeMinutes,
    );
  }

  /// Get formatted start time string (e.g., "14:00")
  String get formattedStartTime {
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get formatted end time string
  String get formattedEndTime {
    final hour = endTime.hour.toString().padLeft(2, '0');
    final minute = endTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get formatted time range string (e.g., "14:00~14:50")
  String get formattedTimeRange => '$formattedStartTime~$formattedEndTime';

  /// Get short formatted time range (e.g., "14:00~50")
  /// Shows full start time but abbreviated end time (minutes only if same hour)
  String get formattedTimeRangeShort {
    if (startTime.hour == endTime.hour) {
      // Same hour: "14:00~30"
      final endMinute = endTime.minute.toString().padLeft(2, '0');
      return '$formattedStartTime~:$endMinute';
    }
    // Different hour: "14:30~15:20"
    return formattedTimeRange;
  }

  /// Get formatted date string (e.g., "2/18(화)")
  String get formattedDate {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}/${date.day}($weekday)';
  }

  /// Check if this slot is in the morning (before 12:00)
  bool get isMorning => startTime.hour < 12;

  /// Check if this slot is in the afternoon (12:00 or later)
  bool get isAfternoon => startTime.hour >= 12;

  /// Get DateTime for the start of this slot
  DateTime get startDateTime => DateTime(
    date.year,
    date.month,
    date.day,
    startTime.hour,
    startTime.minute,
  );

  /// Get DateTime for the end of this slot
  DateTime get endDateTime =>
      DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilitySlot &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Status of an availability slot
enum AvailabilitySlotStatus {
  /// Slot is available for booking
  available,

  /// Slot is booked by a student
  booked,

  /// Slot is booked by the current user
  myBooking,

  /// Slot is cancelled (holiday, etc.)
  cancelled,

  /// Slot has passed
  past,
}
