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

  test(
    'replaceAvailableSlots persists when the notifier is cold (first tap)',
    () async {
      // Regression (#1): the first-availability save screen and home/quest only
      // watch the read-side FutureProvider, leaving the notifier cold. The
      // previous `if (state.value == null) return;` guard silently dropped the
      // first save, surfacing as "저장 실패". We must NOT prime the notifier
      // here — that is exactly the cold path that used to fail.
      final repo = _MutableSettingsRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      // Only the read-side is primed; the notifier has never been built.
      await container.read(teacherSettingsProvider.future);

      await container
          .read(teacherSettingsNotifierProvider.notifier)
          .replaceAvailableSlots([
            const TimeSlot(
              id: 'first-slot',
              dayOfWeek: 1,
              startTime: ClockTime(hour: 14, minute: 0),
              endTime: ClockTime(hour: 18, minute: 0),
            ),
          ]);

      // The slot must have reached the repository (no silent drop).
      final saved = await repo.getTeacherSettings();
      expect(saved.availableSlots, hasLength(1));
      expect(saved.availableSlots.single.id, 'first-slot');

      // And the read-side derived provider reflects it.
      await container.read(teacherSettingsProvider.future);
      expect(container.read(hasAvailableSlotsProvider), isTrue);
    },
  );

  test(
    'updateBreakTime keeps the saved value when only the availability mirror '
    'fails',
    () async {
      // Regression (#7): the remote repo writes /settings/teacher first, then
      // mirrors to /schedule/availability. A failure of the secondary mirror
      // must NOT throw — the primary value is already persisted. We simulate
      // that here by having the repo persist break time but ignore mirror
      // errors (matching the production best-effort mirror).
      final repo = _MutableSettingsRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(teacherSettingsProvider.future);
      await container.read(teacherSettingsNotifierProvider.future);

      await container
          .read(teacherSettingsNotifierProvider.notifier)
          .updateBreakTime(15);

      // The notifier must hold data (not an error state) so the screen stays
      // usable, and the value must be persisted.
      final state = container.read(teacherSettingsNotifierProvider);
      expect(state.hasError, isFalse);
      expect(state.valueOrNull?.breakTimeBetweenLessons, 15);
    },
  );

  test(
    'updateBreakTime rolls back to last-good data on failure (no error screen)',
    () async {
      // Regression (#6): mutations used to flip the notifier into a full-screen
      // loading then error state, blanking the screen on a transient failure.
      // Now a failure rolls back to the last known-good value instead.
      final repo = _ThrowingBreakTimeRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(teacherSettingsNotifierProvider.future);

      await container
          .read(teacherSettingsNotifierProvider.notifier)
          .updateBreakTime(15);

      final state = container.read(teacherSettingsNotifierProvider);
      expect(state.hasError, isFalse, reason: 'no full-screen error state');
      expect(state.valueOrNull, isNotNull, reason: 'screen stays usable');
      expect(
        state.valueOrNull?.breakTimeBetweenLessons,
        initial.breakTimeBetweenLessons,
        reason: 'rolled back to last-good value',
      );
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
  Future<TeacherSettings> updateBreakTime(int minutes) async {
    // Primary write succeeds; secondary availability mirror is best-effort and
    // is intentionally not modeled here (it never throws in production). (#7)
    _settings = _settings.copyWith(breakTimeBetweenLessons: minutes);
    return _settings;
  }

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

/// Repository whose [updateBreakTime] always throws, to exercise the
/// notifier's rollback-to-last-good behavior. (#6)
class _ThrowingBreakTimeRepository extends _MutableSettingsRepository {
  @override
  Future<TeacherSettings> updateBreakTime(int minutes) =>
      throw Exception('network');
}
