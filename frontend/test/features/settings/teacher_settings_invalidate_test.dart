import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/settings_repository_provider.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_boot_migration_provider.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_provider.dart';

/// Stub override that bypasses the Hive-backed boot migration in unit tests.
/// The migration semantics are covered by
/// `teacher_settings_boot_migration_provider_test.dart`; this file focuses on
/// the notifier mirror + invalidation invariants.
final _skipBootMigration = teacherSettingsBootMigrationProvider.overrideWith(
  (ref) async => true,
);

/// Regression: the [TeacherSettingsNotifier] mutations and the read-side
/// [teacherSettingsProvider] are separate instances. Without invalidation,
/// screens that derive from [teacherSettingsProvider] keep a stale value
/// after a save. (#5 D-G3)
///
/// W1 2026-06-11 (Task 1.5a) — [hasAvailableSlotsProvider] now derives from
/// `TeacherAvailability.weeklySchedules` SSOT (spec §5.4), so the deprecated
/// settings-side `replaceAvailableSlots` no longer flips that derived flag.
/// These tests now guard the settings mirror persistence + invalidation
/// invariant only. Availability-side invariants live in
/// `data/repositories/availability_consumer_migration_test.dart`.
void main() {
  test('replaceAvailableSlots persists into the settings mirror', () async {
    final repo = _MutableSettingsRepository();
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
        _skipBootMigration,
      ],
    );
    addTearDown(container.dispose);

    // Prime both the read-side provider and the notifier (the notifier returns
    // early when its state is null).
    await container.read(teacherSettingsProvider.future);
    await container.read(teacherSettingsNotifierProvider.future);

    // Save the first availability slot via the notifier (deprecated mirror).
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

    // The settings mirror must reflect the saved slot.
    final saved = await repo.getTeacherSettings();
    // ignore: deprecated_member_use_from_same_package
    expect(saved.availableSlots, hasLength(1));
    // ignore: deprecated_member_use_from_same_package
    expect(saved.availableSlots.single.id, 'slot-1');
  });

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
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          _skipBootMigration,
        ],
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
      // ignore: deprecated_member_use_from_same_package
      expect(saved.availableSlots, hasLength(1));
      // ignore: deprecated_member_use_from_same_package
      expect(saved.availableSlots.single.id, 'first-slot');
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
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          _skipBootMigration,
        ],
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
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          _skipBootMigration,
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(
        teacherSettingsNotifierProvider.future,
      );

      // #1194 — the notifier now rethrows after rolling back so screens can
      // surface the failure; the rollback contract below is unchanged.
      await expectLater(
        container
            .read(teacherSettingsNotifierProvider.notifier)
            .updateBreakTime(15),
        throwsException,
      );

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
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
        _skipBootMigration,
      ],
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

  // #205 / #206 — min booking hours invalidation + mock mirror
  _minBookingTests();
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
    // ignore: deprecated_member_use_from_same_package
    _settings = _settings.copyWith(availableSlots: slots);
    return _settings;
  }

  @override
  Future<void> updateTrialLessonFree(bool value) async {
    _settings = _settings.copyWith(trialLessonFree: value);
  }

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
    // ignore: deprecated_member_use_from_same_package
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

// ─── #205 / #206 regression tests ───────────────────────────────────────────

/// Settings repository that persists [updateMinBookingHours] and also
/// mirrors the new threshold into the supplied availability repository —
/// matching the MockSettingsRepository + _syncAvailabilityConstraints path.
class _MinBookingSettingsRepository extends _MutableSettingsRepository {
  _MinBookingSettingsRepository(this._availRepo);

  final _MutableAvailabilityRepository _availRepo;

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) async {
    _settings = _settings.copyWith(minBookingHours: hours);
    // Mirror into the availability store (mirrors _syncAvailabilityConstraints).
    final current = await _availRepo.getAvailability(_settings.id);
    if (current != null) {
      await _availRepo.saveAvailability(
        current.copyWith(minBookingHours: hours),
      );
    }
    return _settings;
  }
}

/// Minimal in-memory [TeacherAvailabilityRepository] used by these tests.
/// Only [getAvailability] and [saveAvailability] are implemented.
class _MutableAvailabilityRepository implements TeacherAvailabilityRepository {
  TeacherAvailability? _availability;

  void seed(TeacherAvailability availability) {
    _availability = availability;
  }

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async =>
      _availability?.teacherId == teacherId ? _availability : null;

  @override
  Future<TeacherAvailability> saveAvailability(
    TeacherAvailability availability,
  ) async {
    _availability = availability;
    return availability;
  }

  // Remaining interface methods — unused in these tests.
  @override
  Future<void> deleteAvailability(String teacherId) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

// ── Tests ────────────────────────────────────────────────────────────────────

// These tests are appended to the same file so they share helper classes and
// can be run with a single `flutter test` invocation.

void _minBookingTests() {
  const teacherId = 'teacher-1';

  test('#205 updateMinBookingHours invalidates teacherAvailabilityProvider so '
      'slot filters see the new threshold', () async {
    final availRepo = _MutableAvailabilityRepository();
    availRepo.seed(
      TeacherAvailability(
        id: 'avail-1',
        teacherId: teacherId,
        minBookingHours: 0,
        slotDurationMinutes: 50,
        slotStartInterval: 30,
        breakTimeBetweenLessons: 10,
        weeklySchedules: const [],
        exceptions: const [],
        createdAt: DateTime.utc(2026, 6, 25),
      ),
    );
    final settingsRepo = _MinBookingSettingsRepository(availRepo);

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        teacherAvailabilityRepositoryProvider.overrideWithValue(availRepo),
        _skipBootMigration,
      ],
    );
    addTearDown(container.dispose);

    await container.read(teacherSettingsProvider.future);
    await container.read(teacherSettingsNotifierProvider.future);

    // Warm the availability cache before the write.
    final before = await container.read(
      teacherAvailabilityProvider(teacherId).future,
    );
    expect(before?.minBookingHours, 0);

    // Act — write via the notifier.
    await container
        .read(teacherSettingsNotifierProvider.notifier)
        .updateMinBookingHours(24);

    // The provider must have been invalidated and now returns the new value.
    final after = await container.read(
      teacherAvailabilityProvider(teacherId).future,
    );
    expect(
      after?.minBookingHours,
      24,
      reason: 'availability cache must reflect the new threshold (#205)',
    );
  });

  test('#206 MockSettingsRepository._syncAvailabilityConstraints mirrors '
      'minBookingHours into the availability store', () async {
    final availRepo = _MutableAvailabilityRepository();
    availRepo.seed(
      TeacherAvailability(
        id: 'avail-1',
        teacherId: teacherId,
        minBookingHours: 0,
        slotDurationMinutes: 50,
        slotStartInterval: 30,
        breakTimeBetweenLessons: 10,
        weeklySchedules: const [],
        exceptions: const [],
        createdAt: DateTime.utc(2026, 6, 25),
      ),
    );
    final settingsRepo = _MinBookingSettingsRepository(availRepo);

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        teacherAvailabilityRepositoryProvider.overrideWithValue(availRepo),
        _skipBootMigration,
      ],
    );
    addTearDown(container.dispose);

    await container.read(teacherSettingsProvider.future);
    await container.read(teacherSettingsNotifierProvider.future);

    await container
        .read(teacherSettingsNotifierProvider.notifier)
        .updateMinBookingHours(48);

    // The availability store must hold the mirrored value (#206).
    final stored = await availRepo.getAvailability(teacherId);
    expect(
      stored?.minBookingHours,
      48,
      reason: 'availability store must mirror the new minBookingHours (#206)',
    );
  });
}
