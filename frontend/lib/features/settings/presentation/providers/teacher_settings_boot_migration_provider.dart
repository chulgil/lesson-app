// Teacher settings 1-shot boot migration provider (W1 Task 1.5).
//
// Spec: .harness/spec/2026-06-11-teacher-settings-redesign.md §5.4
//
// Single responsibility: at app boot, read settings + availability, run the
// pure `TeacherSettingsMigration.migrate(...)` once, persist the result to
// both repositories if it changed, then set a Hive flag so subsequent boots
// skip the read/write round-trip entirely.
//
// `teacher_settings_provider` watches `bootMigration.future` so the read-side
// settings FutureProvider only resolves after migration has run.
//
// Failure mode: any exception (Hive open, repository I/O, parsing) is logged
// to debugPrint and the provider returns `false`. The app keeps booting with
// the un-migrated values — better degraded behaviour than a blocked screen.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../schedule/domain/entities/teacher_availability.dart';
import '../../../schedule/schedule_facade.dart'
    show teacherAvailabilityRepositoryProvider;
import '../../data/migrations/teacher_settings_migration.dart';
import 'settings_repository_provider.dart';

part 'teacher_settings_boot_migration_provider.g.dart';

/// Hive box that stores the 1-shot migration flag.
const _kBoxName = 'teacher_settings_state';

/// Bool key — `true` once the migration has run successfully.
const _kMigrationDoneKey = 'migration_v1_done';

/// Resolves to `true` once the W1 migration has run (or was already done).
///
/// Returns `false` only on a hard failure (Hive unavailable, repository
/// threw) so callers can choose to retry on the next boot.
@Riverpod(keepAlive: true)
Future<bool> teacherSettingsBootMigration(
  TeacherSettingsBootMigrationRef ref,
) async {
  // Open the persistence box first. If Hive is not initialized (e.g. unit
  // tests that exercise teacherSettingsProvider without Hive.init), short
  // circuit to `false` silently so downstream providers can keep going.
  final Box<dynamic> box;
  try {
    box = await Hive.openBox(_kBoxName);
  } catch (_) {
    return false;
  }
  try {
    final done = box.get(_kMigrationDoneKey) as bool? ?? false;
    if (done) {
      return true;
    }

    final settingsRepo = ref.read(settingsRepositoryProvider);
    final availabilityRepo = ref.read(teacherAvailabilityRepositoryProvider);
    final teacherId = ref.read(currentUserIdProvider);

    final settings = await settingsRepo.getTeacherSettings();
    final existing = await availabilityRepo.getAvailability(teacherId);
    // First-boot fallback: no availability row yet → start from an empty one
    // anchored to the current teacher so saveAvailability() can persist it.
    final availability =
        existing ??
        TeacherAvailability(
          id: 'availability-$teacherId',
          teacherId: teacherId,
          weeklySchedules: const [],
          createdAt: DateTime.now(),
        );

    final result = TeacherSettingsMigration.migrate(
      settings: settings,
      availability: availability,
    );

    if (result.changed) {
      // ignore: deprecated_member_use_from_same_package
      await settingsRepo.updateAvailableSlots(result.settings.availableSlots);
      // ignore: deprecated_member_use_from_same_package
      if (result.settings.breakTimeBetweenLessons !=
          // ignore: deprecated_member_use_from_same_package
          settings.breakTimeBetweenLessons) {
        // ignore: deprecated_member_use_from_same_package
        await settingsRepo.updateBreakTime(
          result.settings.breakTimeBetweenLessons,
        );
      }
      if (result.settings.minBookingHours != settings.minBookingHours) {
        await settingsRepo.updateMinBookingHours(
          result.settings.minBookingHours,
        );
      }
      await availabilityRepo.saveAvailability(result.availability);
    }

    await box.put(_kMigrationDoneKey, true);
    return true;
  } catch (e, st) {
    debugPrint('teacher_settings_boot_migration failed: $e\n$st');
    return false;
  }
}
