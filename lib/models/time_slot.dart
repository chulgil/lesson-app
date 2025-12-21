import 'package:flutter/material.dart';

/// Represents a time slot for lesson availability
class TimeSlot {
  final String id;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
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

  /// Get day name in Korean
  String get dayName {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[dayOfWeek - 1];
  }

  /// Get full day name in Korean
  String get fullDayName {
    const days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return days[dayOfWeek - 1];
  }

  /// Get formatted display string (with specific date if available)
  String get displayLabel {
    if (specificDate != null) {
      return '${specificDate!.month}/${specificDate!.day}($dayName) $timeRange';
    }
    return '$dayName $timeRange';
  }

  /// Format time range as string
  String get timeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  /// Calculate duration in minutes
  int get durationMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }

  /// Check if a time falls within this slot
  bool containsTime(TimeOfDay time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return timeMinutes >= startMinutes && timeMinutes < endMinutes;
  }

  TimeSlot copyWith({
    String? id,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
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
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Default time slots for a week (Mon-Sat, 14:00-21:00)
List<TimeSlot> getDefaultTimeSlots() {
  return List.generate(6, (index) {
    return TimeSlot(
      id: 'slot_${index + 1}',
      dayOfWeek: index + 1, // Monday to Saturday
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 21, minute: 0),
      isActive: true,
    );
  });
}
