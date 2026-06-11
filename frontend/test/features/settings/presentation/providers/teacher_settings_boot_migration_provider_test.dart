// Tests for teacher_settings_boot_migration_provider (W1 Task 1.5).
//
// Spec: .harness/spec/2026-06-11-teacher-settings-redesign.md §5.4
//   - 부팅 시 1회 TeacherSettingsMigration.migrate() 호출
//   - changed=true → settings + availability repository 양쪽 write
//   - Hive flag (`teacher_settings_state` box, `migration_v1_done` key) 영속
//   - 두 번째 부팅 — flag true → migrate 호출 안 됨
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/settings_repository_provider.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_boot_migration_provider.dart';

import '../../data/repositories/_fakes/fake_settings_repository.dart';
import '../../data/repositories/_fakes/fake_teacher_availability_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'lessonaza_teacher_settings_boot_migration_test_',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ---- shared fixtures ----
  final fixedClock = DateTime.utc(2026, 6, 11);

  TeacherSettings buildSettings({
    List<TimeSlot> availableSlots = const [],
    int minBookingHours = 24,
  }) {
    // ignore: deprecated_member_use_from_same_package
    return TeacherSettings(
      id: 'settings-1',
      instruments: const ['바이올린'],
      availableSlots: availableSlots,
      createdAt: fixedClock,
      minBookingHours: minBookingHours,
    );
  }

  TeacherAvailability buildAvailability({
    List<WeeklySchedule> weeklySchedules = const [],
    int minBookingHours = 24,
  }) {
    return TeacherAvailability(
      id: 'availability-1',
      teacherId: 'teacher_1',
      weeklySchedules: weeklySchedules,
      createdAt: fixedClock,
      minBookingHours: minBookingHours,
    );
  }

  TimeSlot buildSlot() {
    return TimeSlot(
      id: 'slot-mon',
      dayOfWeek: 1,
      startTime: const ClockTime(hour: 14, minute: 0),
      endTime: const ClockTime(hour: 18, minute: 0),
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
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('teacher_settings_boot_migration_provider — 부팅 마이그레이션 (W1 Task 1.5)', () {
    test(
      '첫 부팅 — flag false + availableSlots 있음 → migrate 호출 + 양쪽 repository write + flag true 영속',
      () async {
        final settings = buildSettings(availableSlots: [buildSlot()]);
        final availability = buildAvailability(weeklySchedules: const []);
        final settingsRepo = FakeSettingsRepository(initial: settings);
        final availabilityRepo = FakeTeacherAvailabilityRepository(
          initial: availability,
        );
        final container = makeContainer(
          settingsRepo: settingsRepo,
          availabilityRepo: availabilityRepo,
        );

        final done = await container.read(
          teacherSettingsBootMigrationProvider.future,
        );

        expect(done, isTrue);
        // settings 의 deprecated availableSlots 가 비워졌고 schedule 로 옮겨짐
        // ignore: deprecated_member_use_from_same_package
        expect(settingsRepo.last.availableSlots, isEmpty);
        expect(settingsRepo.writeCount, 1);
        expect(availabilityRepo.last.weeklySchedules, hasLength(1));
        expect(availabilityRepo.writeCount, 1);
        // Hive flag 영속
        final box = await Hive.openBox('teacher_settings_state');
        expect(box.get('migration_v1_done'), isTrue);
      },
    );

    test('두 번째 부팅 — flag true → migrate skip (repository write 0회)', () async {
      // 사전 조건: flag 가 이미 true
      final box = await Hive.openBox('teacher_settings_state');
      await box.put('migration_v1_done', true);
      await box.close();

      final settings = buildSettings(availableSlots: [buildSlot()]);
      final availability = buildAvailability(weeklySchedules: const []);
      final settingsRepo = FakeSettingsRepository(initial: settings);
      final availabilityRepo = FakeTeacherAvailabilityRepository(
        initial: availability,
      );
      final container = makeContainer(
        settingsRepo: settingsRepo,
        availabilityRepo: availabilityRepo,
      );

      final done = await container.read(
        teacherSettingsBootMigrationProvider.future,
      );

      expect(done, isTrue);
      // skip 보장 — 어떤 read/write 도 없음
      expect(settingsRepo.readCount, 0);
      expect(settingsRepo.writeCount, 0);
      expect(availabilityRepo.readCount, 0);
      expect(availabilityRepo.writeCount, 0);
    });

    test(
      '이미 완료된 상태 — flag false + availableSlots 비어있음 → migrate 호출되지만 changed=false → write 0회',
      () async {
        final settings = buildSettings(availableSlots: const []);
        final availability = buildAvailability(weeklySchedules: const []);
        final settingsRepo = FakeSettingsRepository(initial: settings);
        final availabilityRepo = FakeTeacherAvailabilityRepository(
          initial: availability,
        );
        final container = makeContainer(
          settingsRepo: settingsRepo,
          availabilityRepo: availabilityRepo,
        );

        final done = await container.read(
          teacherSettingsBootMigrationProvider.future,
        );

        expect(done, isTrue);
        // read 는 1회씩 했지만 변경 없음 → write 0회
        expect(settingsRepo.readCount, 1);
        expect(settingsRepo.writeCount, 0);
        expect(availabilityRepo.readCount, 1);
        expect(availabilityRepo.writeCount, 0);
        // flag 는 여전히 true 로 영속 (재실행 방지)
        final box = await Hive.openBox('teacher_settings_state');
        expect(box.get('migration_v1_done'), isTrue);
      },
    );
  });
}
