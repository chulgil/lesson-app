import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../profile/domain/entities/teacher_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Mock implementation of SettingsRepository
class MockSettingsRepository implements SettingsRepository {
  // ignore: deprecated_member_use_from_same_package
  TeacherSettings _settings = TeacherSettings(
    id: 'teacher_1',
    instruments: ['바이올린', '비올라', '피아노'],
    // ignore: deprecated_member_use_from_same_package
    defaultLessonDuration: 60,
    availableSlots: [
      TimeSlot(
        id: 'slot_1',
        dayOfWeek: 1, // Monday
        startTime: const ClockTime(hour: 14, minute: 0),
        endTime: const ClockTime(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_2',
        dayOfWeek: 2, // Tuesday
        startTime: const ClockTime(hour: 14, minute: 0),
        endTime: const ClockTime(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_3',
        dayOfWeek: 3, // Wednesday
        startTime: const ClockTime(hour: 14, minute: 0),
        endTime: const ClockTime(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_4',
        dayOfWeek: 4, // Thursday
        startTime: const ClockTime(hour: 14, minute: 0),
        endTime: const ClockTime(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_5',
        dayOfWeek: 5, // Friday
        startTime: const ClockTime(hour: 14, minute: 0),
        endTime: const ClockTime(hour: 21, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_6',
        dayOfWeek: 6, // Saturday
        startTime: const ClockTime(hour: 10, minute: 0),
        endTime: const ClockTime(hour: 18, minute: 0),
        isActive: true,
      ),
      TimeSlot(
        id: 'slot_7',
        dayOfWeek: 7, // Sunday
        startTime: const ClockTime(hour: 10, minute: 0),
        endTime: const ClockTime(hour: 18, minute: 0),
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
    // ignore: deprecated_member_use_from_same_package
    return TeacherSettings(
      id: teacherId,
      instruments: ['바이올린', '피아노'],
      // ignore: deprecated_member_use_from_same_package
      defaultLessonDuration: 60,
      customLessonDurations: [50], // Example: teacher added 50 min option
      disabledDurations: [120], // Example: teacher disabled 2 hour option
      availableSlots: [
        TimeSlot(
          id: 'slot_1',
          dayOfWeek: 1, // Monday
          startTime: const ClockTime(hour: 14, minute: 0),
          endTime: const ClockTime(hour: 21, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_2',
          dayOfWeek: 2, // Tuesday
          startTime: const ClockTime(hour: 14, minute: 0),
          endTime: const ClockTime(hour: 21, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_3',
          dayOfWeek: 3, // Wednesday
          startTime: const ClockTime(hour: 15, minute: 0),
          endTime: const ClockTime(hour: 20, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_4',
          dayOfWeek: 4, // Thursday
          startTime: const ClockTime(hour: 14, minute: 0),
          endTime: const ClockTime(hour: 21, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_5',
          dayOfWeek: 5, // Friday
          startTime: const ClockTime(hour: 14, minute: 0),
          endTime: const ClockTime(hour: 19, minute: 0),
          isActive: true,
        ),
        TimeSlot(
          id: 'slot_6',
          dayOfWeek: 6, // Saturday
          startTime: const ClockTime(hour: 10, minute: 0),
          endTime: const ClockTime(hour: 18, minute: 0),
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
      // ignore: deprecated_member_use_from_same_package
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
      // ignore: deprecated_member_use_from_same_package
      availableSlots: slots,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final updatedSlots =
        // ignore: deprecated_member_use_from_same_package
        _settings.availableSlots.map((s) {
          if (s.id == slot.id) {
            return slot;
          }
          return s;
        }).toList();

    _settings = _settings.copyWith(
      // ignore: deprecated_member_use_from_same_package
      availableSlots: updatedSlots,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final updatedSlots =
        // ignore: deprecated_member_use_from_same_package
        _settings.availableSlots.map((s) {
          if (s.id == slotId) {
            return s.copyWith(isActive: isActive);
          }
          return s;
        }).toList();

    _settings = _settings.copyWith(
      // ignore: deprecated_member_use_from_same_package
      availableSlots: updatedSlots,
      updatedAt: DateTime.now(),
    );
    return _settings;
  }

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = _settings.copyWith(
      // ignore: deprecated_member_use_from_same_package
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

  @override
  Future<void> updateTrialLessonFree(bool value) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _settings = _settings.copyWith(
      trialLessonFree: value,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateBookingGuidanceMessage(String? message) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _settings = _settings.copyWith(
      bookingGuidanceMessage: message,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updatePriceTable(
    Map<String, Map<String, int>> priceTable,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _settings = _settings.copyWith(
      lessonPriceTable: priceTable,
      updatedAt: DateTime.now(),
    );
  }
}
