import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/home/presentation/providers/teacher_profile_completion_provider.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/settings_repository_provider.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_provider.dart';

/// Regression: the [TeacherSettingsNotifier] mutations and the read-side
/// [teacherSettingsProvider] are separate instances. Without invalidation,
/// home/quest screens that derive from [teacherSettingsProvider] (e.g.
/// [hasAvailableSlotsProvider]) keep a stale value after a save. (#5 D-G3)
void main() {
  test(
    'replaceAvailableSlots refreshes the read-side hasAvailableSlots',
    () async {
      final repo = _MutableSettingsRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      // Keep derived providers alive and prime both the read-side provider
      // and the notifier (the notifier returns early when its state is null).
      container.listen(hasAvailableSlotsProvider, (_, __) {});
      await container.read(teacherSettingsProvider.future);
      await container.read(teacherSettingsNotifierProvider.future);
      expect(container.read(hasAvailableSlotsProvider), isFalse);

      // Save the first availability slot via the notifier.
      await container
          .read(teacherSettingsNotifierProvider.notifier)
          .replaceAvailableSlots([
            const TimeSlot(
              id: 'slot-1',
              dayOfWeek: 1,
              startTime: ClockTime(hour: 9, minute: 0),
              endTime: ClockTime(hour: 10, minute: 0),
            ),
          ]);

      // The read-side derived provider must reflect the saved slot.
      await container.read(teacherSettingsProvider.future);
      expect(container.read(hasAvailableSlotsProvider), isTrue);
    },
  );

  test('updateTrialLessonFree refreshes the read-side settings', () async {
    final repo = _MutableSettingsRepository();
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(teacherSettingsProvider.future);
    await container.read(teacherSettingsNotifierProvider.future);
    expect(
      container.read(teacherSettingsProvider).valueOrNull?.trialLessonFree,
      isFalse,
    );

    await container
        .read(teacherSettingsNotifierProvider.notifier)
        .updateTrialLessonFree(true);

    final refreshed = await container.read(teacherSettingsProvider.future);
    expect(refreshed.trialLessonFree, isTrue);
  });
}

/// In-memory [SettingsRepository] that mutates shared state, so the read-side
/// FutureProvider picks up changes only when invalidated.
class _MutableSettingsRepository implements SettingsRepository {
  TeacherSettings _settings = TeacherSettings(
    id: 'teacher-1',
    instruments: const ['피아노'],
    createdAt: DateTime.utc(2026, 5, 2),
  );

  @override
  Future<TeacherSettings> getTeacherSettings() async => _settings;

  @override
  Future<TeacherSettings> getTeacherSettingsById(String teacherId) async =>
      _settings;

  @override
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots) async {
    _settings = _settings.copyWith(availableSlots: slots);
    return _settings;
  }

  @override
  Future<void> updateTrialLessonFree(bool value) async {
    _settings = _settings.copyWith(trialLessonFree: value);
  }

  @override
  Future<TeacherSettings> addCustomDuration(int duration) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> removeCustomDuration(int duration) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> toggleDuration(int duration, bool isActive) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) =>
      throw UnimplementedError();

  @override
  Future<void> updateBookingGuidanceMessage(String? message) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateDefaultDuration(int duration) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateInstruments(List<String> instruments) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) =>
      throw UnimplementedError();

  @override
  Future<void> updatePriceTable(Map<String, Map<String, int>> priceTable) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) =>
      throw UnimplementedError();
}
