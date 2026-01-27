import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/repositories/teacher_availability_repository.dart';

/// Mock implementation for development
class MockTeacherAvailabilityRepository
    implements TeacherAvailabilityRepository {
  final _uuid = const Uuid();

  /// In-memory storage for availability settings
  final Map<String, TeacherAvailability> _availabilities = {};

  /// In-memory storage for booked slots
  final Map<String, AvailabilitySlot> _bookedSlots = {};

  /// Recent lessons for recommendation (mock data)
  final Map<String, List<_MockLessonHistory>> _lessonHistory = {};

  MockTeacherAvailabilityRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    // Create mock teacher availability
    final teacherId = 'teacher_1';
    final availability = TeacherAvailability(
      id: _uuid.v4(),
      teacherId: teacherId,
      slotDurationMinutes: 60,
      weeklySchedules: [
        // Tuesday 14:00-18:00
        WeeklySchedule(
          id: _uuid.v4(),
          dayOfWeek: 1, // Tuesday
          startTime: '14:00',
          endTime: '18:00',
          createdAt: now,
        ),
        // Thursday 14:00-18:00
        WeeklySchedule(
          id: _uuid.v4(),
          dayOfWeek: 3, // Thursday
          startTime: '14:00',
          endTime: '18:00',
          createdAt: now,
        ),
        // Saturday 10:00-18:00
        WeeklySchedule(
          id: _uuid.v4(),
          dayOfWeek: 5, // Saturday
          startTime: '10:00',
          endTime: '18:00',
          createdAt: now,
        ),
      ],
      exceptions: [
        // Holiday on next Thursday
        TimeException(
          id: _uuid.v4(),
          type: ExceptionType.holiday,
          startDate: _getNextWeekday(now, DateTime.thursday),
          endDate: _getNextWeekday(now, DateTime.thursday),
          reason: '개인 사정',
          createdAt: now,
        ),
      ],
      createdAt: now,
    );

    _availabilities[teacherId] = availability;

    // Add some mock lesson history for recommendations
    _lessonHistory['student_1'] = [
      _MockLessonHistory(
        dayOfWeek: DateTime.tuesday,
        hour: 16,
        minute: 0,
        count: 4,
      ),
    ];
    _lessonHistory['student_2'] = [
      _MockLessonHistory(
        dayOfWeek: DateTime.saturday,
        hour: 10,
        minute: 0,
        count: 3,
      ),
    ];

    // Add a pre-booked slot
    final nextTuesday = _getNextWeekday(now, DateTime.tuesday);
    final bookedSlot = AvailabilitySlot(
      id: _uuid.v4(),
      teacherId: teacherId,
      date: nextTuesday,
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 15, minute: 0),
      durationMinutes: 60,
      status: AvailabilitySlotStatus.booked,
      bookedByStudentId: 'student_3',
      bookedByStudentName: '박민지',
    );
    _bookedSlots[bookedSlot.id] = bookedSlot;
  }

  DateTime _getNextWeekday(DateTime from, int weekday) {
    var daysUntil = weekday - from.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return DateTime(from.year, from.month, from.day + daysUntil);
  }

  // ============================================================
  // Teacher Availability Settings
  // ============================================================

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _availabilities[teacherId];
  }

  @override
  Future<TeacherAvailability> saveAvailability(
    TeacherAvailability availability,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _availabilities[availability.teacherId] = availability;
    return availability;
  }

  @override
  Future<void> deleteAvailability(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _availabilities.remove(teacherId);
  }

  // ============================================================
  // Weekly Schedules
  // ============================================================

  @override
  Future<TeacherAvailability> addWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final current = _availabilities[teacherId];
    if (current == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }

    final updated = current.copyWith(
      weeklySchedules: [...current.weeklySchedules, schedule],
      updatedAt: DateTime.now(),
    );
    _availabilities[teacherId] = updated;
    return updated;
  }

  @override
  Future<TeacherAvailability> updateWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final current = _availabilities[teacherId];
    if (current == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }

    final schedules = current.weeklySchedules.map((s) {
      return s.id == schedule.id ? schedule : s;
    }).toList();

    final updated = current.copyWith(
      weeklySchedules: schedules,
      updatedAt: DateTime.now(),
    );
    _availabilities[teacherId] = updated;
    return updated;
  }

  @override
  Future<TeacherAvailability> removeWeeklySchedule(
    String teacherId,
    String scheduleId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final current = _availabilities[teacherId];
    if (current == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }

    final schedules =
        current.weeklySchedules.where((s) => s.id != scheduleId).toList();

    final updated = current.copyWith(
      weeklySchedules: schedules,
      updatedAt: DateTime.now(),
    );
    _availabilities[teacherId] = updated;
    return updated;
  }

  // ============================================================
  // Time Exceptions
  // ============================================================

  @override
  Future<TeacherAvailability> addException(
    String teacherId,
    TimeException exception,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final current = _availabilities[teacherId];
    if (current == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }

    final updated = current.copyWith(
      exceptions: [...current.exceptions, exception],
      updatedAt: DateTime.now(),
    );
    _availabilities[teacherId] = updated;
    return updated;
  }

  @override
  Future<TeacherAvailability> updateException(
    String teacherId,
    TimeException exception,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final current = _availabilities[teacherId];
    if (current == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }

    final exceptions = current.exceptions.map((e) {
      return e.id == exception.id ? exception : e;
    }).toList();

    final updated = current.copyWith(
      exceptions: exceptions,
      updatedAt: DateTime.now(),
    );
    _availabilities[teacherId] = updated;
    return updated;
  }

  @override
  Future<TeacherAvailability> removeException(
    String teacherId,
    String exceptionId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final current = _availabilities[teacherId];
    if (current == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }

    final exceptions =
        current.exceptions.where((e) => e.id != exceptionId).toList();

    final updated = current.copyWith(
      exceptions: exceptions,
      updatedAt: DateTime.now(),
    );
    _availabilities[teacherId] = updated;
    return updated;
  }

  // ============================================================
  // Computed Slots
  // ============================================================

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final availability = _availabilities[teacherId];
    if (availability == null) return [];

    return _computeSlotsForDate(
      availability,
      date,
      currentStudentId: currentStudentId,
    );
  }

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final availability = _availabilities[teacherId];
    if (availability == null) return [];

    final slots = <AvailabilitySlot>[];
    var current = startDate;

    while (!current.isAfter(endDate)) {
      final daySlots = _computeSlotsForDate(
        availability,
        current,
        currentStudentId: currentStudentId,
      );
      slots.addAll(daySlots);
      current = current.add(const Duration(days: 1));
    }

    return slots;
  }

  @override
  Future<List<DateTime>> getNextAvailableDates(
    String teacherId, {
    required DateTime fromDate,
    int limit = 3,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final availability = _availabilities[teacherId];
    if (availability == null) return [];

    final availableDates = <DateTime>[];
    var current = fromDate;
    var attempts = 0;
    const maxAttempts = 60; // Look up to 60 days ahead

    while (availableDates.length < limit && attempts < maxAttempts) {
      final slots = _computeSlotsForDate(availability, current);
      final hasAvailable = slots.any(
        (s) => s.status == AvailabilitySlotStatus.available,
      );

      if (hasAvailable) {
        availableDates.add(current);
      }

      current = current.add(const Duration(days: 1));
      attempts++;
    }

    return availableDates;
  }

  @override
  Future<List<AvailabilitySlot>> getRecommendedSlots(
    String teacherId,
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final allSlots = await getAvailableSlotsForDateRange(
      teacherId,
      startDate,
      endDate,
      currentStudentId: studentId,
    );

    final history = _lessonHistory[studentId] ?? [];
    if (history.isEmpty) return [];

    return allSlots.where((slot) {
      if (slot.status != AvailabilitySlotStatus.available) return false;

      // Check if this slot matches student's usual time
      return history.any((h) =>
          slot.date.weekday == h.dayOfWeek &&
          slot.startTime.hour == h.hour &&
          slot.startTime.minute == h.minute &&
          h.count >= 2);
    }).map((slot) => slot.copyWith(isRecommended: true)).toList();
  }

  List<AvailabilitySlot> _computeSlotsForDate(
    TeacherAvailability availability,
    DateTime date, {
    String? currentStudentId,
  }) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final isToday = dateOnly.year == now.year &&
        dateOnly.month == now.month &&
        dateOnly.day == now.day;

    // Check if date is in the past
    if (dateOnly.isBefore(DateTime(now.year, now.month, now.day))) {
      return [];
    }

    // Check for exceptions (holidays, vacations)
    for (final exception in availability.exceptions) {
      if (exception.type != ExceptionType.additionalSlot &&
          exception.containsDate(date)) {
        return []; // Day is blocked
      }
    }

    // Find applicable weekly schedule
    final weekday = date.weekday - 1; // Convert to 0=Monday
    final schedules = availability.weeklySchedules.where(
      (s) => s.dayOfWeek == weekday && s.isActive,
    );

    if (schedules.isEmpty) return [];

    final slots = <AvailabilitySlot>[];
    final duration = availability.slotDurationMinutes;

    for (final schedule in schedules) {
      final startParts = schedule.startTime.split(':');
      final endParts = schedule.endTime.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      var currentMinutes = startHour * 60 + startMinute;
      final endMinutes = endHour * 60 + endMinute;

      while (currentMinutes + duration <= endMinutes) {
        final slotHour = currentMinutes ~/ 60;
        final slotMinute = currentMinutes % 60;

        final startTime = TimeOfDay(hour: slotHour, minute: slotMinute);
        final endTime = TimeOfDay(
          hour: (currentMinutes + duration) ~/ 60,
          minute: (currentMinutes + duration) % 60,
        );

        // Skip if slot is in the past for today
        if (isToday) {
          final slotDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            slotHour,
            slotMinute,
          );
          if (slotDateTime.isBefore(now)) {
            currentMinutes += duration;
            continue;
          }
        }

        // Check if slot is booked
        final bookedSlot = _findBookedSlot(
          availability.teacherId,
          date,
          startTime,
        );

        AvailabilitySlotStatus status;
        String? bookedById;
        String? bookedByName;
        String? lessonId;

        if (bookedSlot != null) {
          if (bookedSlot.bookedByStudentId == currentStudentId) {
            status = AvailabilitySlotStatus.myBooking;
          } else {
            status = AvailabilitySlotStatus.booked;
          }
          bookedById = bookedSlot.bookedByStudentId;
          bookedByName = bookedSlot.bookedByStudentName;
          lessonId = bookedSlot.lessonId;
        } else {
          status = AvailabilitySlotStatus.available;
        }

        // Check recommendation
        final isRecommended =
            currentStudentId != null &&
            _isRecommendedSlot(currentStudentId, date, startTime);

        slots.add(AvailabilitySlot(
          id: '${availability.teacherId}_${date.toIso8601String()}_$slotHour:$slotMinute',
          teacherId: availability.teacherId,
          date: date,
          startTime: startTime,
          endTime: endTime,
          durationMinutes: duration,
          status: status,
          bookedByStudentId: bookedById,
          bookedByStudentName: bookedByName,
          lessonId: lessonId,
          isRecommended: isRecommended,
        ));

        currentMinutes += duration;
      }
    }

    return slots;
  }

  AvailabilitySlot? _findBookedSlot(
    String teacherId,
    DateTime date,
    TimeOfDay startTime,
  ) {
    for (final slot in _bookedSlots.values) {
      if (slot.teacherId == teacherId &&
          slot.date.year == date.year &&
          slot.date.month == date.month &&
          slot.date.day == date.day &&
          slot.startTime.hour == startTime.hour &&
          slot.startTime.minute == startTime.minute) {
        return slot;
      }
    }
    return null;
  }

  bool _isRecommendedSlot(String studentId, DateTime date, TimeOfDay time) {
    final history = _lessonHistory[studentId];
    if (history == null) return false;

    return history.any((h) =>
        date.weekday == h.dayOfWeek &&
        time.hour == h.hour &&
        time.minute == h.minute &&
        h.count >= 2);
  }

  // ============================================================
  // Booking Operations
  // ============================================================

  @override
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Parse slot ID to get details
    final parts = slotId.split('_');
    if (parts.length < 3) {
      throw Exception('Invalid slot ID format');
    }

    final teacherId = parts[0];
    final dateStr = parts[1];
    final timeStr = parts[2];
    final timeParts = timeStr.split(':');

    final date = DateTime.parse(dateStr);
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Check if slot is still available
    final existing = _findBookedSlot(
      teacherId,
      date,
      TimeOfDay(hour: hour, minute: minute),
    );

    if (existing != null) {
      throw Exception('이미 예약된 시간입니다');
    }

    final availability = _availabilities[teacherId];
    if (availability == null) {
      throw Exception('Teacher availability not found');
    }

    final bookedSlot = AvailabilitySlot(
      id: slotId,
      teacherId: teacherId,
      date: date,
      startTime: TimeOfDay(hour: hour, minute: minute),
      endTime: TimeOfDay(
        hour: (hour * 60 + minute + availability.slotDurationMinutes) ~/ 60,
        minute: (hour * 60 + minute + availability.slotDurationMinutes) % 60,
      ),
      durationMinutes: availability.slotDurationMinutes,
      status: AvailabilitySlotStatus.booked,
      bookedByStudentId: studentId,
      bookedByStudentName: studentName,
    );

    _bookedSlots[slotId] = bookedSlot;
    return bookedSlot;
  }

  @override
  Future<AvailabilitySlot> cancelBooking(String slotId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final slot = _bookedSlots[slotId];
    if (slot == null) {
      throw Exception('Booking not found');
    }

    _bookedSlots.remove(slotId);

    return slot.copyWith(
      status: AvailabilitySlotStatus.available,
      bookedByStudentId: null,
      bookedByStudentName: null,
      lessonId: null,
    );
  }

  // ============================================================
  // Block Grid Operations
  // ============================================================

  @override
  Future<void> toggleTimeBlock(
    String teacherId,
    DateTime date,
    TimeOfDay time,
    bool isAvailable,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final availability = _availabilities[teacherId];
    if (availability == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }

    if (isAvailable) {
      // Remove any exception for this date/time
      final exceptionsToRemove = availability.exceptions.where((e) =>
          e.containsDate(date) &&
          e.startTime != null &&
          e.startTime == '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');

      if (exceptionsToRemove.isNotEmpty) {
        for (final e in exceptionsToRemove) {
          await removeException(teacherId, e.id);
        }
      }
    } else {
      // Add exception for this time
      final exception = TimeException(
        id: _uuid.v4(),
        type: ExceptionType.holiday,
        startDate: date,
        endDate: date,
        startTime:
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        reason: 'Manual block',
        createdAt: DateTime.now(),
      );
      await addException(teacherId, exception);
    }
  }

  @override
  Future<void> setTimeBlocks(
    String teacherId,
    DateTime date,
    List<TimeOfDay> times,
    bool isAvailable,
  ) async {
    for (final time in times) {
      await toggleTimeBlock(teacherId, date, time, isAvailable);
    }
  }
}

/// Mock lesson history for recommendations
class _MockLessonHistory {
  final int dayOfWeek;
  final int hour;
  final int minute;
  final int count;

  _MockLessonHistory({
    required this.dayOfWeek,
    required this.hour,
    required this.minute,
    required this.count,
  });
}
