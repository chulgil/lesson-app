import '../../../../../core/domain/value_objects/clock_time.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../lessons/domain/entities/lesson.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/entities/unified_lesson_request.dart';
import '../../../domain/services/schedule_window_conflict_service.dart';

// Pure conflict-check helpers shared by the counter-propose sheet's
// preferred-slots section, accept button, and grid slot add/edit flow.
//
// Extracted from `_SuggestAlternativeBottomSheetState` (P1-4 file-size
// split) — no logic changes, only moved out of the widget's State class so
// it can be reused without a `BuildContext`/`ref`.

/// The date a preferred slot falls on, given the visible week's Monday.
DateTime? dateForPreferredSlot(PreferredTimeSlot slot, DateTime weekStart) {
  if (slot.date != null) return slot.date;
  final dayOfWeek = slot.dayOfWeek;
  if (dayOfWeek == null) return null;
  return weekStart.add(Duration(days: dayOfWeek.clamp(0, 6)));
}

/// Check if a preferred slot conflicts with the teacher's schedule.
/// Returns: null=no conflict, 'confirmed'=hard lesson conflict,
/// 'preview'=preview lesson conflict, 'vacation'=vacation/holiday block,
/// 'hours'=outside operating hours (#526). Vacation/operating-hours are
/// evaluated first so a slot the teacher is unavailable for is never reported
/// as conflict-free just because no lesson overlaps it.
String? checkSlotConflict(
  PreferredTimeSlot slot,
  List<Lesson> lessons,
  TeacherAvailability? availability, {
  required DateTime weekStart,
}) {
  final slotDate = dateForPreferredSlot(slot, weekStart);
  if (slotDate == null) return null;
  final slotStart = ClockTime.parse(slot.startTime).inMinutes;
  final slotEnd = ClockTime.parse(slot.endTime).inMinutes;

  // #526 — vacation / operating-hours window check (independent of lessons).
  final window = ScheduleWindowConflictService.check(
    availability: availability,
    date: slotDate,
    startMinutes: slotStart,
    endMinutes: slotEnd,
  );
  if (window == ScheduleWindowConflict.vacation) return 'vacation';
  if (window == ScheduleWindowConflict.outsideOperatingHours) return 'hours';

  for (final lesson in lessons) {
    if (lesson.date.year == slotDate.year &&
        lesson.date.month == slotDate.month &&
        lesson.date.day == slotDate.day) {
      final lessonStart = ClockTime.parse(lesson.startTime).inMinutes;
      final lessonEnd = lessonStart + lesson.duration;
      if (slotStart < lessonEnd && slotEnd > lessonStart) {
        return lesson.isPreview ? 'preview' : 'confirmed';
      }
    }
  }
  return null;
}

/// Human label for a conflict code, or null when there is no conflict.
String? conflictLabelFor(String? conflict) {
  switch (conflict) {
    case 'confirmed':
      return AppStrings.slotConflict;
    case 'preview':
      return AppStrings.previewConflict;
    case 'vacation':
      return AppStrings.slotVacationConflict;
    case 'hours':
      return AppStrings.slotOutsideOperatingHours;
    default:
      return null;
  }
}

/// Localized reason a proposed window is unavailable due to the teacher's
/// own schedule (#526), or null when the window is fine. Existing-lesson
/// overlap is checked separately by the caller.
String? windowConflictMessage({
  required TeacherAvailability? availability,
  required DateTime date,
  required int startMinutes,
  required int endMinutes,
}) {
  final window = ScheduleWindowConflictService.check(
    availability: availability,
    date: date,
    startMinutes: startMinutes,
    endMinutes: endMinutes,
  );
  switch (window) {
    case ScheduleWindowConflict.vacation:
      return AppStrings.slotVacationConflict;
    case ScheduleWindowConflict.outsideOperatingHours:
      return AppStrings.slotOutsideOperatingHours;
    case ScheduleWindowConflict.none:
      return null;
  }
}
