import '../entities/teacher_availability.dart';

/// Kinds of conflict a candidate time window can have against a teacher's
/// own availability (independent of existing lessons).
enum ScheduleWindowConflict {
  /// No vacation/operating-hours conflict.
  none,

  /// The window overlaps a vacation/holiday block (whole-day or partial).
  vacation,

  /// The window falls (wholly or partly) outside the teacher's operating
  /// hours for that weekday.
  outsideOperatingHours,
}

/// Pure helper that validates a candidate booking/proposal window against a
/// teacher's own schedule — vacation/holiday exceptions and operating hours
/// (#526). Existing-lesson overlap is handled separately by the caller.
///
/// Vacation takes precedence over operating hours: if a date is blocked by a
/// vacation/holiday exception, the window is reported as [vacation] even when
/// it would also be outside operating hours.
///
/// Pure (no Riverpod/clock dependency) so it is deterministic and
/// unit-testable. When [availability] is null the window is treated as having
/// no conflict — the screen has no schedule data to validate against and must
/// not block on missing information.
class ScheduleWindowConflictService {
  const ScheduleWindowConflictService._();

  /// Checks the window `[startMinutes, endMinutes)` on [date].
  ///
  /// - [startMinutes]/[endMinutes] are minutes-from-midnight (e.g. 14:00 → 840).
  /// - Boundary: a window touching an operating-hours edge or a vacation edge
  ///   is treated as NOT conflicting (consistent with
  ///   [TimeException.containsDateTimeRange]).
  static ScheduleWindowConflict check({
    required TeacherAvailability? availability,
    required DateTime date,
    required int startMinutes,
    required int endMinutes,
  }) {
    if (availability == null) return ScheduleWindowConflict.none;

    // 1. Vacation / holiday blocks (whole-day or partial) take precedence.
    final isVacationBlocked = availability.exceptions.any(
      (e) =>
          e.type != ExceptionType.additionalSlot &&
          e.containsDateTimeRange(date, startMinutes, endMinutes),
    );
    if (isVacationBlocked) return ScheduleWindowConflict.vacation;

    // 2. Operating hours: the window must sit fully inside at least one active
    //    weekly schedule for this weekday. WeeklySchedule.dayOfWeek is
    //    0=Monday..6=Sunday; DateTime.weekday is 1=Monday..7=Sunday.
    final weekday0 = date.weekday - 1;
    final daySchedules = availability.weeklySchedules.where(
      (s) => s.dayOfWeek == weekday0 && s.isActive,
    );

    // No operating hours configured for this weekday → entirely outside hours.
    if (daySchedules.isEmpty) {
      return ScheduleWindowConflict.outsideOperatingHours;
    }

    final fitsInAnyWindow = daySchedules.any((s) {
      final scheduleStart = _parseHHmm(s.startTime);
      final scheduleEnd = _parseHHmm(s.endTime);
      if (scheduleStart == null || scheduleEnd == null) return false;
      return startMinutes >= scheduleStart && endMinutes <= scheduleEnd;
    });

    return fitsInAnyWindow
        ? ScheduleWindowConflict.none
        : ScheduleWindowConflict.outsideOperatingHours;
  }

  static int? _parseHHmm(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}
