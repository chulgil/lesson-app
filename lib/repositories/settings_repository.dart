import 'package:flutter/material.dart';

import '../models/teacher_settings.dart';
import '../models/time_slot.dart';

/// Repository interface for teacher settings
abstract class SettingsRepository {
  Future<TeacherSettings> getTeacherSettings();
  Future<TeacherSettings> getTeacherSettingsById(String teacherId);
  Future<TeacherSettings> updateInstruments(List<String> instruments);
  Future<TeacherSettings> updateDefaultDuration(int duration);
  Future<TeacherSettings> addCustomDuration(int duration);
  Future<TeacherSettings> removeCustomDuration(int duration);
  Future<TeacherSettings> toggleDuration(int duration, bool isActive);
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots);
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot);
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive);
  Future<TeacherSettings> updateBreakTime(int minutes);
  Future<TeacherSettings> updateMinBookingHours(int hours);
}

/// Mock implementation of SettingsRepository
class MockSettingsRepository implements SettingsRepository {
  TeacherSettings _settings = TeacherSettings(
    id: 'teacher_1',
    instruments: ['바이올린', '비올라', '피아노'],
    defaultLessonDuration: 60,
    availableSlots: [
      TimeSlot(
        id: 'slot_1',
        dayOfWeek: 1, // Monday
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_2',
        dayOfWeek: 2, // Tuesday
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_3',
        dayOfWeek: 3, // Wednesday
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_4',
        dayOfWeek: 4, // Thursday
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_5',
        dayOfWeek: 5, // Friday
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_6',
        dayOfWeek: 6, // Saturday
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_7',
        dayOfWeek: 7, // Sunday
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        isActive: false,
      ),
    ],
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );

  @override
  Future<TeacherSettings> getTeacherSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _settings;
  }

  @override
  Future<TeacherSettings> getTeacherSettingsById(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return mock settings for any teacher
    // In production, this would fetch from the backend
    return TeacherSettings(
      id: teacherId,
      instruments: ['바이올린', '피아노'],
      defaultLessonDuration: 60,
      customLessonDurations: [50], // Example: teacher added 50 min option
      disabledDurations: [120], // Example: teacher disabled 2 hour option
      availableSlots: [
        TimeSlot(
          id: 'slot_1',
          dayOfWeek: 1, // Monday
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 21, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_2',
          dayOfWeek: 2, // Tuesday
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 21, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_3',
          dayOfWeek: 3, // Wednesday
          startTime: const TimeOfDay(hour: 15, minute: 0),
          endTime: const TimeOfDay(hour: 20, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_4',
          dayOfWeek: 4, // Thursday
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 21, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_5',
          dayOfWeek: 5, // Friday
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 19, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_6',
          dayOfWeek: 6, // Saturday
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          isActive: true,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    );
  }

  @override
  Future<TeacherSettings> updateInstruments(List<String> instruments) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = _settings.copyWith(
      instruments: instruments,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> updateDefaultDuration(int duration) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = _settings.copyWith(
      defaultLessonDuration: duration,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> addCustomDuration(int duration) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_settings.customLessonDurations.contains(duration) ||
        LessonDurations.defaults.contains(duration)) {
      return _settings;
    }
    _settings = _settings.copyWith(
      customLessonDurations: [..._settings.customLessonDurations, duration],
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> removeCustomDuration(int duration) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = _settings.copyWith(
      customLessonDurations:
          _settings.customLessonDurations.where((d) => d != duration).toList(),
      // Also remove from disabled if it was disabled
      disabledDurations:
          _settings.disabledDurations.where((d) => d != duration).toList(),
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> toggleDuration(int duration, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Ensure at least one duration remains active
    final activeCount = _settings.allLessonDurations.length;
    if (!isActive && activeCount <= 1) {
      // Cannot disable the last active duration
      return _settings;
    }

    List<int> newDisabled;
    if (isActive) {
      // Enable: remove from disabled list
      newDisabled =
          _settings.disabledDurations.where((d) => d != duration).toList();
    } else {
      // Disable: add to disabled list
      newDisabled = [..._settings.disabledDurations, duration];
    }

    _settings = _settings.copyWith(
      disabledDurations: newDisabled,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = _settings.copyWith(
      availableSlots: slots,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final updatedSlots = _settings.availableSlots.map((s) {
      if (s.id == slot.id) {
        return slot;
      }
      return s;
    }).toList();

    _settings = _settings.copyWith(
      availableSlots: updatedSlots,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final updatedSlots = _settings.availableSlots.map((s) {
      if (s.id == slotId) {
        return s.copyWith(isActive: isActive);
      }
      return s;
    }).toList();

    _settings = _settings.copyWith(
      availableSlots: updatedSlots,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = _settings.copyWith(
      breakTimeBetweenLessons: minutes,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = _settings.copyWith(
      minBookingHours: hours,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }
}
