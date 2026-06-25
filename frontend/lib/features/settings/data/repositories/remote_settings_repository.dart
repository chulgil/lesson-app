import '../../../../core/network/api_client.dart';
import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../profile/domain/entities/teacher_settings.dart';
import '../../../../core/booking/entities/time_slot.dart';
import '../../domain/repositories/settings_repository.dart';

/// Remote implementation of [SettingsRepository] using FastAPI backend.
///
/// Maps to GET/PUT /api/v1/settings/teacher.
/// Note: available_slots are managed separately by TeacherAvailabilityRepository.
class RemoteSettingsRepository implements SettingsRepository {
  final ApiClient _apiClient;

  RemoteSettingsRepository(this._apiClient);

  @override
  Future<TeacherSettings> getTeacherSettings() async {
    final response = await _apiClient.get('/settings/teacher');
    final data = response.data as Map<String, dynamic>;
    final settings = TeacherSettings.fromJson(data);
    // ignore: deprecated_member_use_from_same_package
    return settings.copyWith(availableSlots: await _getAvailabilitySlots());
  }

  @override
  Future<TeacherSettings> getTeacherSettingsById(String teacherId) async {
    final response = await _apiClient.get(
      '/settings/teacher/${Uri.encodeComponent(teacherId)}',
    );
    final data = response.data as Map<String, dynamic>;
    final settings = TeacherSettings.fromJson(data);
    return settings.copyWith(
      // ignore: deprecated_member_use_from_same_package
      availableSlots: await _getAvailabilitySlots(teacherId: teacherId),
    );
  }

  Future<TeacherSettings> _updateSettings(Map<String, dynamic> updates) async {
    final response = await _apiClient.put('/settings/teacher', data: updates);
    final data = response.data as Map<String, dynamic>;
    final settings = TeacherSettings.fromJson(data);
    // ignore: deprecated_member_use_from_same_package
    return settings.copyWith(availableSlots: await _getAvailabilitySlots());
  }

  @override
  Future<TeacherSettings> updateInstruments(List<String> instruments) async {
    return _updateSettings({'instruments': instruments});
  }

  @override
  Future<TeacherSettings> updateDefaultDuration(int duration) async {
    return _updateSettings({'default_lesson_duration': duration});
  }

  @override
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots) async {
    final current = await getTeacherSettings();
    return _saveAvailableSlots(current, slots);
  }

  Future<TeacherSettings> _saveAvailableSlots(
    TeacherSettings current,
    List<TimeSlot> slots,
  ) async {
    await _apiClient.put(
      '/schedule/availability',
      data: {
        'availabilities': _availabilityPayloadFromSlots(slots),
        // ignore: deprecated_member_use_from_same_package
        'slot_duration_minutes': current.defaultLessonDuration,
        // ignore: deprecated_member_use_from_same_package
        'break_time_between_lessons': current.breakTimeBetweenLessons,
        'min_booking_hours': current.minBookingHours,
      },
    );
    // ignore: deprecated_member_use_from_same_package
    return current.copyWith(availableSlots: slots);
  }

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) async {
    final current = await getTeacherSettings();
    // ignore: deprecated_member_use_from_same_package
    final slots = [...current.availableSlots];
    final index = slots.indexWhere((existing) => existing.id == slot.id);
    if (index == -1) {
      slots.add(slot);
    } else {
      slots[index] = slot;
    }
    return _saveAvailableSlots(current, slots);
  }

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) async {
    final current = await getTeacherSettings();
    final slots =
        // ignore: deprecated_member_use_from_same_package
        current.availableSlots
            .map(
              (slot) =>
                  slot.id == slotId ? slot.copyWith(isActive: isActive) : slot,
            )
            .toList();
    return _saveAvailableSlots(current, slots);
  }

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) async {
    final settings = await _updateSettings({
      'break_time_between_lessons': minutes,
    });
    // The booking engine reads break/min from the availability SSOT, not from
    // /settings/teacher, so mirror the value there too. (#5 D-G3 — SSOT) (#19)
    await _syncAvailabilityConstraints(settings);
    return settings;
  }

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) async {
    final settings = await _updateSettings({'min_booking_hours': hours});
    // Keep the availability SSOT in sync with the settings change. (#19)
    await _syncAvailabilityConstraints(settings);
    return settings;
  }

  /// Push the break/min-booking constraints to the availability endpoint so
  /// the booking engine, which reads them from `/schedule/availability`,
  /// reflects settings changes without requiring a slot re-save.
  ///
  /// Best-effort mirror: the authoritative write is the preceding
  /// `/settings/teacher` PUT, which has already succeeded by the time we get
  /// here. If only this secondary mirror fails we must NOT surface an error —
  /// doing so previously made the screen show an error state even though the
  /// setting was saved. The constraint re-syncs on the next slot save, and the
  /// booking engine falls back to the settings value. (#19 — partial-failure)
  Future<void> _syncAvailabilityConstraints(TeacherSettings settings) async {
    try {
      await _apiClient.put(
        '/schedule/availability',
        data: {
          'availabilities': _availabilityPayloadFromSlots(
            // ignore: deprecated_member_use_from_same_package
            settings.availableSlots,
          ),
          // ignore: deprecated_member_use_from_same_package
          'slot_duration_minutes': settings.defaultLessonDuration,
          // ignore: deprecated_member_use_from_same_package
          'break_time_between_lessons': settings.breakTimeBetweenLessons,
          'min_booking_hours': settings.minBookingHours,
        },
      );
    } catch (_) {
      // Swallow: primary settings write already persisted (see doc above).
    }
  }

  @override
  Future<void> updateTrialLessonFree(bool value) async {
    await _updateSettings({'trial_lesson_free': value});
  }

  @override
  Future<void> updateBookingGuidanceMessage(String? message) async {
    await _updateSettings({'booking_guidance_message': message});
  }

  @override
  Future<void> updatePriceTable(
    Map<String, Map<String, int>> priceTable,
  ) async {
    await _updateSettings({'lesson_price_table': priceTable});
  }

  Future<List<TimeSlot>> _getAvailabilitySlots({String? teacherId}) async {
    try {
      final response = await _apiClient.get(
        teacherId == null
            ? '/schedule/availability'
            : '/schedule/availability/${Uri.encodeComponent(teacherId)}',
      );
      final data = response.data as Map<String, dynamic>;
      return _slotsFromAvailabilityJson(data);
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _availabilityPayloadFromSlots(
    List<TimeSlot> slots,
  ) {
    final grouped = <int, List<TimeSlot>>{};
    for (final slot in slots.where((slot) => slot.isActive)) {
      grouped.putIfAbsent(slot.dayOfWeek - 1, () => []).add(slot);
    }

    return grouped.entries.map((entry) {
      final daySlots = [...entry.value]
        ..sort((a, b) => a.startTime.inMinutes - b.startTime.inMinutes);
      return {
        'day_of_week': entry.key,
        'time_slots': daySlots
            .map(
              (slot) => {
                'start_time': _clockTimeToJson(slot.startTime),
                'end_time': _clockTimeToJson(slot.endTime),
              },
            )
            .toList(),
      };
    }).toList();
  }

  List<TimeSlot> _slotsFromAvailabilityJson(Map<String, dynamic> json) {
    final slots = <TimeSlot>[];
    final availabilities = json['availabilities'] as List<dynamic>?;
    if (availabilities != null) {
      for (final dayAvailability in availabilities) {
        final day = dayAvailability as Map<String, dynamic>;
        final dayOfWeek = (day['day_of_week'] as num).toInt() + 1;
        final timeSlots = day['time_slots'] as List<dynamic>? ?? [];
        for (var index = 0; index < timeSlots.length; index++) {
          final slot = timeSlots[index] as Map<String, dynamic>;
          slots.add(
            TimeSlot(
              id: '${json['teacher_id'] ?? 'teacher'}_${dayOfWeek}_$index',
              dayOfWeek: dayOfWeek,
              startTime: _clockTimeFromJson(slot['start_time'] as String),
              endTime: _clockTimeFromJson(slot['end_time'] as String),
            ),
          );
        }
      }
      return slots;
    }

    final weeklySchedules = json['weekly_schedules'] as List<dynamic>? ?? [];
    for (var index = 0; index < weeklySchedules.length; index++) {
      final schedule = weeklySchedules[index] as Map<String, dynamic>;
      final dayOfWeek = (schedule['day_of_week'] as num).toInt() + 1;
      slots.add(
        TimeSlot(
          id: schedule['id'] as String? ?? '${json['teacher_id']}_$index',
          dayOfWeek: dayOfWeek,
          startTime: _clockTimeFromJson(schedule['start_time'] as String),
          endTime: _clockTimeFromJson(schedule['end_time'] as String),
        ),
      );
    }
    return slots;
  }

  ClockTime _clockTimeFromJson(String value) {
    final parts = value.split(':');
    return ClockTime(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _clockTimeToJson(ClockTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}
