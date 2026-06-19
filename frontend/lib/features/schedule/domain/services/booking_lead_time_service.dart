import '../entities/availability_slot.dart';

/// Pure helper that enforces a teacher's minimum booking lead time (#850).
///
/// A teacher may require students to book at least [minBookingHours] hours
/// before a lesson starts. When [minBookingHours] is 0 (the default) there is
/// no restriction and every slot is returned unchanged — only teachers who
/// explicitly raise the value opt into enforcement.
class BookingLeadTimeService {
  const BookingLeadTimeService._();

  /// Removes slots that start earlier than [now] + [minBookingHours] hours.
  ///
  /// - [minBookingHours] `<= 0` → no filtering (returns [slots] as-is).
  /// - Boundary: a slot starting exactly at the cutoff is kept (it is not
  ///   "before" the cutoff).
  ///
  /// Pure (no clock/Riverpod dependency) — [now] is injected so callers stay
  /// deterministic and the rule is unit-testable.
  static List<AvailabilitySlot> filterByLeadTime({
    required List<AvailabilitySlot> slots,
    required int minBookingHours,
    required DateTime now,
  }) {
    if (minBookingHours <= 0) return slots;
    final cutoff = now.add(Duration(hours: minBookingHours));
    return slots.where((slot) => !slot.startDateTime.isBefore(cutoff)).toList();
  }
}
