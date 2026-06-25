// Minimal in-memory SettingsRepository for boot-migration tests.
//
// Tracks read/write counts so tests can assert idempotency (skip on second
// boot, no-op when nothing changed) without touching network/Hive.
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({required TeacherSettings initial}) : _value = initial;

  TeacherSettings _value;
  int readCount = 0;
  int writeCount = 0;

  TeacherSettings get last => _value;

  @override
  Future<TeacherSettings> getTeacherSettings() async {
    readCount++;
    return _value;
  }

  @override
  Future<TeacherSettings> getTeacherSettingsById(String teacherId) async {
    readCount++;
    return _value;
  }

  @override
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots) async {
    writeCount++;
    // ignore: deprecated_member_use_from_same_package
    _value = _value.copyWith(availableSlots: slots);
    return _value;
  }

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) async {
    writeCount++;
    // ignore: deprecated_member_use_from_same_package
    _value = _value.copyWith(breakTimeBetweenLessons: minutes);
    return _value;
  }

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) async {
    writeCount++;
    _value = _value.copyWith(minBookingHours: hours);
    return _value;
  }

  // ---- Unused by boot-migration; throw to surface accidental usage. ----

  @override
  Future<TeacherSettings> updateInstruments(List<String> instruments) =>
      throw UnimplementedError('not used by boot migration');

  @override
  Future<TeacherSettings> updateDefaultDuration(int duration) =>
      throw UnimplementedError('not used by boot migration');

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) =>
      throw UnimplementedError('not used by boot migration');

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) =>
      throw UnimplementedError('not used by boot migration');

  @override
  Future<void> updateTrialLessonFree(bool value) =>
      throw UnimplementedError('not used by boot migration');

  @override
  Future<void> updateBookingGuidanceMessage(String? message) =>
      throw UnimplementedError('not used by boot migration');

  @override
  Future<void> updatePriceTable(Map<String, Map<String, int>> priceTable) =>
      throw UnimplementedError('not used by boot migration');
}
