// Tests for W1 Task 1.5a — Settings repository consumer migration.
//
// Spec: .harness/spec/2026-06-11-teacher-settings-redesign.md §5.4
//   - SSOT for 운영시간 is `TeacherAvailability.weeklySchedules` (schedule 도메인).
//   - `TeacherSettings.availableSlots` is @Deprecated and kept only for
//     transitional BE JSON compat + deprecated wrapper methods.
//   - Consumer migration:
//       1) `teacher_profile_completion_provider.hasAvailableSlots` must read
//          from `weeklySchedules` (architect P0 #1).
//       2) Settings repository `updateAvailableSlots(...)` deprecated wrappers
//          must remain callable (boot migration still writes through them) but
//          do NOT define the SSOT.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/home/presentation/providers/teacher_profile_completion_provider.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/settings_repository_provider.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_provider.dart';

import '_fakes/fake_settings_repository.dart';
import '_fakes/fake_teacher_availability_repository.dart';

void main() {
  // Fixed clock to keep generated WeeklySchedule.createdAt deterministic.
  final fixedClock = DateTime.utc(2026, 6, 11);

  TeacherSettings buildSettings({
    // ignore: deprecated_member_use_from_same_package
    List<TimeSlot> availableSlots = const [],
  }) {
    // ignore: deprecated_member_use_from_same_package
    return TeacherSettings(
      id: 'settings-1',
      instruments: const ['바이올린'],
      availableSlots: availableSlots,
      createdAt: fixedClock,
    );
  }

  TeacherAvailability buildAvailability({
    List<WeeklySchedule> weeklySchedules = const [],
  }) {
    return TeacherAvailability(
      id: 'availability-1',
      teacherId: 'teacher_1',
      weeklySchedules: weeklySchedules,
      createdAt: fixedClock,
    );
  }

  WeeklySchedule buildWeekly({
    String id = 'weekly-mon',
    int dayOfWeek = 0,
    bool isActive = true,
  }) {
    return WeeklySchedule(
      id: id,
      dayOfWeek: dayOfWeek,
      startTime: '14:00',
      endTime: '18:00',
      isActive: isActive,
      createdAt: fixedClock,
    );
  }

  TimeSlot buildSlot() {
    return const TimeSlot(
      id: 'slot-mon',
      dayOfWeek: 1,
      startTime: ClockTime(hour: 14, minute: 0),
      endTime: ClockTime(hour: 18, minute: 0),
    );
  }

  ProviderContainer makeContainer({
    required FakeSettingsRepository settingsRepo,
    required FakeTeacherAvailabilityRepository availabilityRepo,
  }) {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWith(
          (ref) => settingsRepo as SettingsRepository,
        ),
        teacherAvailabilityRepositoryProvider.overrideWith(
          (ref) => availabilityRepo as TeacherAvailabilityRepository,
        ),
        currentUserIdProvider.overrideWithValue('teacher_1'),
        // Skip boot migration so we test the read-side derivation in isolation.
        teacherSettingsProvider.overrideWith(
          (ref) async => settingsRepo.getTeacherSettings(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Settings → Availability consumer migration (W1 Task 1.5a)', () {
    test('hasAvailableSlots reads from TeacherAvailability.weeklySchedules SSOT '
        '(architect P0 #1) — settings.availableSlots is ignored', () async {
      // weeklySchedules has an active entry; settings.availableSlots is empty.
      final settingsRepo = FakeSettingsRepository(
        initial: buildSettings(availableSlots: const []),
      );
      final availabilityRepo = FakeTeacherAvailabilityRepository(
        initial: buildAvailability(weeklySchedules: [buildWeekly()]),
      );
      final container = makeContainer(
        settingsRepo: settingsRepo,
        availabilityRepo: availabilityRepo,
      );

      // Prime providers in dependency order.
      await container.read(teacherSettingsProvider.future);
      await container.read(teacherAvailabilityProvider('teacher_1').future);

      expect(container.read(hasAvailableSlotsProvider), isTrue);
    });

    test('hasAvailableSlots is false when weeklySchedules empty even if '
        'settings.availableSlots is populated (legacy ignored)', () async {
      // Inverse case: settings has slots, but availability is empty.
      // After SSOT switch, the answer must be FALSE (availability is source).
      final settingsRepo = FakeSettingsRepository(
        initial: buildSettings(availableSlots: [buildSlot()]),
      );
      final availabilityRepo = FakeTeacherAvailabilityRepository(
        initial: buildAvailability(weeklySchedules: const []),
      );
      final container = makeContainer(
        settingsRepo: settingsRepo,
        availabilityRepo: availabilityRepo,
      );

      await container.read(teacherSettingsProvider.future);
      await container.read(teacherAvailabilityProvider('teacher_1').future);

      expect(container.read(hasAvailableSlotsProvider), isFalse);
    });

    test(
      'hasAvailableSlots is false when all weeklySchedules are inactive',
      () async {
        final settingsRepo = FakeSettingsRepository(
          initial: buildSettings(availableSlots: const []),
        );
        final availabilityRepo = FakeTeacherAvailabilityRepository(
          initial: buildAvailability(
            weeklySchedules: [buildWeekly(isActive: false)],
          ),
        );
        final container = makeContainer(
          settingsRepo: settingsRepo,
          availabilityRepo: availabilityRepo,
        );

        await container.read(teacherSettingsProvider.future);
        await container.read(teacherAvailabilityProvider('teacher_1').future);

        expect(container.read(hasAvailableSlotsProvider), isFalse);
      },
    );

    test('settings repository updateAvailableSlots still callable — deprecated '
        'wrapper preserved for boot migration write path', () async {
      // This guards the deprecated wrapper surface so Task 1.5 boot migration
      // (which calls settingsRepo.updateAvailableSlots(...)) keeps working
      // without the SSOT changing semantics. Real SSOT writes happen through
      // the availability repository.
      final settingsRepo = FakeSettingsRepository(
        initial: buildSettings(availableSlots: [buildSlot()]),
      );

      await settingsRepo.updateAvailableSlots(const []);

      // ignore: deprecated_member_use_from_same_package
      expect(settingsRepo.last.availableSlots, isEmpty);
      expect(settingsRepo.writeCount, 1);
    });
  });
}
