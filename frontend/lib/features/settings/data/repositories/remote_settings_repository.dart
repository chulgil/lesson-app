import '../../../../core/network/api_client.dart';
import '../../../profile/domain/entities/teacher_settings.dart';
import '../../../schedule/domain/entities/time_slot.dart';
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
    // Available slots are managed by the schedule system, not settings API
    return settings.copyWith(availableSlots: []);
  }

  @override
  Future<TeacherSettings> getTeacherSettingsById(String teacherId) async {
    // For remote, we only have the current teacher's settings
    return getTeacherSettings();
  }

  Future<TeacherSettings> _updateSettings(Map<String, dynamic> updates) async {
    final response = await _apiClient.put(
      '/settings/teacher',
      data: updates,
    );
    final data = response.data as Map<String, dynamic>;
    return TeacherSettings.fromJson(data).copyWith(availableSlots: []);
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
  Future<TeacherSettings> addCustomDuration(int duration) async {
    final current = await getTeacherSettings();
    final updated = [...current.customLessonDurations, duration];
    return _updateSettings({'custom_lesson_durations': updated});
  }

  @override
  Future<TeacherSettings> removeCustomDuration(int duration) async {
    final current = await getTeacherSettings();
    final updated = current.customLessonDurations
        .where((d) => d != duration)
        .toList();
    final updatedDisabled = current.disabledDurations
        .where((d) => d != duration)
        .toList();
    return _updateSettings({
      'custom_lesson_durations': updated,
      'disabled_durations': updatedDisabled,
    });
  }

  @override
  Future<TeacherSettings> toggleDuration(int duration, bool isActive) async {
    final current = await getTeacherSettings();
    List<int> newDisabled;
    if (isActive) {
      newDisabled = current.disabledDurations
          .where((d) => d != duration)
          .toList();
    } else {
      newDisabled = [...current.disabledDurations, duration];
    }
    return _updateSettings({'disabled_durations': newDisabled});
  }

  @override
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots) async {
    // Available slots are managed by TeacherAvailabilityRepository
    // This is a no-op for remote - return current settings
    return getTeacherSettings();
  }

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) async {
    // Managed by TeacherAvailabilityRepository
    return getTeacherSettings();
  }

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) async {
    // Managed by TeacherAvailabilityRepository
    return getTeacherSettings();
  }

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) async {
    return _updateSettings({'break_time_between_lessons': minutes});
  }

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) async {
    return _updateSettings({'min_booking_hours': hours});
  }
}
