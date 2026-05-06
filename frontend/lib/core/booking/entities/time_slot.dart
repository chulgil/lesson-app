// Time slot domain entity
// Moved from lib/features/schedule/domain/entities/time_slot.dart for Clean Architecture

import '../../domain/value_objects/clock_time.dart';

/// Represents a time slot for lesson availability
class TimeSlot {
  final String id;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final ClockTime startTime;
  final ClockTime endTime;
  final bool isActive;
  final DateTime? specificDate; // For custom date-specific slots

  const TimeSlot({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.specificDate,
  });

  /// Calculate duration in minutes
  int get durationMinutes {
    return endTime.inMinutes - startTime.inMinutes;
  }

  /// Check if a time falls within this slot
  bool containsTime(ClockTime time) {
    return time.inMinutes >= startTime.inMinutes &&
        time.inMinutes < endTime.inMinutes;
  }

  TimeSlot copyWith({
    String? id,
    int? dayOfWeek,
    ClockTime? startTime,
    ClockTime? endTime,
    bool? isActive,
    DateTime? specificDate,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      specificDate: specificDate ?? this.specificDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Default time slots for a week (Mon-Sat, 14:00-21:00)
List<TimeSlot> getDefaultTimeSlots() {
  return List.generate(6, (index) {
    return TimeSlot(
      id: 'slot_${index + 1}',
      dayOfWeek: index + 1, // Monday to Saturday
      startTime: const ClockTime(hour: 14, minute: 0),
      endTime: const ClockTime(hour: 21, minute: 0),
      isActive: true,
    );
  });
}
