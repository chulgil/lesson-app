import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/domain/value_objects/clock_time.dart';
import '../entities/unified_lesson_request.dart';

/// Single mapper owning the `dayOfWeek` indexing shift between the grid's
/// 1-indexed [TimeSlot] (`core/booking`, 1=Mon..7=Sun) and this feature's
/// 0-indexed request-slot shapes — [PreferredTimeSlot] (`WeeklyCalendarPicker`
/// output) and [TimeSlotOption] (an `AlternativeTimeGrid` selection once it
/// becomes a proposal/counter-propose/schedule-change payload), both
/// 0=Mon..6=Sun.
///
/// docs/specs/schedule/schedule_change_unification_spec.md §3.2/§4 (M-4) —
/// screen code must not write the `+1`/`-1` arithmetic inline; call these
/// instead so the indexing conversion has exactly one place to live (and be
/// tested).
extension TimeSlotMapperX on TimeSlot {
  /// [TimeSlot] (1-indexed) -> [TimeSlotOption] (0-indexed). Used when a
  /// grid selection (`AlternativeTimeGrid`) becomes a proposal /
  /// counter-propose / schedule-change payload.
  TimeSlotOption toTimeSlotOption() {
    return TimeSlotOption(
      id: id,
      dayOfWeek: dayOfWeek - 1,
      startTime: startTime.format24Hour(),
      endTime: endTime.format24Hour(),
      date: specificDate,
    );
  }

  /// [TimeSlot] (1-indexed) -> [PreferredTimeSlot] (0-indexed), given the
  /// slot's rank (1=highest) among the user's selections.
  PreferredTimeSlot toPreferredTimeSlot({required int priority}) {
    return PreferredTimeSlot(
      priority: priority,
      date: specificDate,
      dayOfWeek: dayOfWeek - 1,
      startTime: startTime.format24Hour(),
      endTime: endTime.format24Hour(),
    );
  }
}

/// [PreferredTimeSlot] (0-indexed) -> [TimeSlot] (1-indexed) — the
/// `WeeklyCalendarPicker` direction of the M-4 contract.
extension PreferredTimeSlotMapperX on PreferredTimeSlot {
  /// [id] defaults to a synthesized id since [PreferredTimeSlot] has none.
  TimeSlot toTimeSlot({String? id}) {
    // dayOfWeek (0-indexed) takes priority over date.weekday when both are
    // present, matching `dateForPreferredSlot`'s precedence
    // (suggest_alternative_conflict.dart) for the reverse lookup.
    final resolvedDayOfWeek =
        dayOfWeek != null ? dayOfWeek! + 1 : (date?.weekday ?? 1);
    return TimeSlot(
      id: id ?? 'preferred_${priority}_${resolvedDayOfWeek}_$startTime',
      dayOfWeek: resolvedDayOfWeek,
      startTime: ClockTime.parse(startTime),
      endTime: ClockTime.parse(endTime),
      specificDate: date,
    );
  }
}
