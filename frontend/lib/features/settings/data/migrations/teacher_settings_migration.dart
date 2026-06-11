// Teacher settings 1-shot migration.
//
// W1 2026-06-11 spec §5.4 — SSOT 통일:
//   - TeacherSettings.availableSlots (profile, deprecated)
//       → TeacherAvailability.weeklySchedules (schedule, SSOT)
//   - 충돌 시 정책 (architect P1 #3):
//       · breakTimeBetweenLessons → schedule 우선 (운영시간 묶음 SSOT)
//       · minBookingHours         → profile 우선 (수업방식 묶음 SSOT, 반대 방향)
//
// Called once at app boot from `teacher_settings_provider` (W1 Task 1.5).
// Pure function — no I/O, no Riverpod, no platform deps (Flutter Architecture
// rule: data layer may depend on domain only).
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';

/// Result holder for [TeacherSettingsMigration.migrate].
///
/// `changed=true` signals to the caller (provider) that the result must be
/// persisted; `false` means both inputs are returned unchanged (identical
/// instances) and no write is needed.
class TeacherSettingsMigrationResult {
  final TeacherSettings settings;
  final TeacherAvailability availability;
  final bool changed;

  const TeacherSettingsMigrationResult({
    required this.settings,
    required this.availability,
    required this.changed,
  });
}

/// Performs the W1 SSOT migration. Idempotent: a second call on an already
/// migrated pair yields `changed=false` and returns the inputs unchanged.
class TeacherSettingsMigration {
  const TeacherSettingsMigration._();

  /// Migrate deprecated [TeacherSettings] fields into the [TeacherAvailability]
  /// SSOT per spec §5.4.
  ///
  /// Returns a [TeacherSettingsMigrationResult] with the resolved entities and
  /// a `changed` flag.
  static TeacherSettingsMigrationResult migrate({
    required TeacherSettings settings,
    required TeacherAvailability availability,
  }) {
    // ignore: deprecated_member_use_from_same_package
    final hasSlots = settings.availableSlots.isNotEmpty;
    // ignore: deprecated_member_use_from_same_package
    final breakConflict =
        settings.breakTimeBetweenLessons != 0 &&
        // ignore: deprecated_member_use_from_same_package
        settings.breakTimeBetweenLessons !=
            availability.breakTimeBetweenLessons;
    final minBookingConflict =
        settings.minBookingHours != availability.minBookingHours;

    if (!hasSlots && !breakConflict && !minBookingConflict) {
      return TeacherSettingsMigrationResult(
        settings: settings,
        availability: availability,
        changed: false,
      );
    }

    // ---- 1) availableSlots → weeklySchedules ----
    var newAvailability = availability;
    if (hasSlots && availability.weeklySchedules.isEmpty) {
      // ignore: deprecated_member_use_from_same_package
      final converted = _slotsToWeeklySchedules(settings.availableSlots);
      newAvailability = newAvailability.copyWith(weeklySchedules: converted);
    }
    // else: schedule already has weeklySchedules → keep schedule (richer:
    // exceptions/vacation 포함). availableSlots 만 비움 (아래).

    // ---- 2) minBookingHours 충돌: profile 우선 (수업방식 묶음 SSOT) ----
    if (minBookingConflict) {
      newAvailability = newAvailability.copyWith(
        minBookingHours: settings.minBookingHours,
      );
    }

    // ---- 3) settings 의 deprecated 필드 비우기 ----
    //   - availableSlots → [] (schedule 으로 옮겼거나 schedule 우선)
    //   - breakTimeBetweenLessons → 0 (schedule 이 SSOT — 운영시간 묶음)
    // ignore: deprecated_member_use_from_same_package
    final newSettings = settings.copyWith(
      availableSlots: const [],
      breakTimeBetweenLessons: 0,
    );

    return TeacherSettingsMigrationResult(
      settings: newSettings,
      availability: newAvailability,
      changed: true,
    );
  }

  /// Convert legacy [TimeSlot] (dayOfWeek 1=Mon..7=Sun, ClockTime) to
  /// [WeeklySchedule] (dayOfWeek 0=Mon..6=Sun, "HH:mm" strings).
  ///
  /// Day-of-week mapping per spec §3 schedule SSOT.
  static List<WeeklySchedule> _slotsToWeeklySchedules(List<TimeSlot> slots) {
    return [
      for (final slot in slots)
        WeeklySchedule(
          id: slot.id,
          // TimeSlot uses 1..7; WeeklySchedule uses 0..6 (Mon..Sun).
          dayOfWeek: (slot.dayOfWeek - 1).clamp(0, 6),
          startTime: _formatHHmm(slot.startTime.hour, slot.startTime.minute),
          endTime: _formatHHmm(slot.endTime.hour, slot.endTime.minute),
          isActive: slot.isActive,
          // Use slot's specificDate as createdAt anchor when present,
          // otherwise stamp with `DateTime.now()` — caller-provided clock
          // not available here (pure function, no DI). Tests inject deterministic
          // slots so this branch is exercised consistently.
          createdAt: slot.specificDate ?? DateTime.now(),
        ),
    ];
  }

  static String _formatHHmm(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
