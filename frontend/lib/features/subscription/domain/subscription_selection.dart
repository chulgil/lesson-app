import 'entities/subscription.dart';

/// Pure selection helpers for attaching a manually-added lesson to the right
/// subscription (spec: `docs/specs/subscription/subscription_required_spec.md` §2.5).

/// Sort active subscriptions for the manual-lesson picker.
///
/// Most "at risk of being wasted" first so the recommended highlight is the
/// first element (만료 임박 우선): earliest end date first (subscriptions with
/// no end date go last), then fewest remaining lessons, then a stable id
/// tie-break. Returns a new list — the input is never mutated.
List<Subscription> sortSubscriptionsForPicker(
  List<Subscription> subscriptions,
) {
  final sorted = [...subscriptions];
  sorted.sort((a, b) {
    final endCompare = _compareEndDate(a.endDate, b.endDate);
    if (endCompare != 0) return endCompare;

    final remainingCompare = _compareRemaining(
      a.remainingLessons,
      b.remainingLessons,
    );
    if (remainingCompare != 0) return remainingCompare;

    return a.id.compareTo(b.id);
  });
  return sorted;
}

/// Earlier end date first; null end dates sort last.
int _compareEndDate(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

/// Fewer remaining lessons first; null remaining sorts last.
int _compareRemaining(int? a, int? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

/// Resolve the instrument to apply to a manually-added lesson.
///
/// The chosen subscription's membership instrument is the SSOT. Falls back to
/// the student's instrument only when no subscription is chosen (0개 trial path)
/// or the subscription carries no instrument.
String resolveLessonInstrument({
  Subscription? subscription,
  required String studentInstrument,
}) {
  final inherited = subscription?.instrument;
  if (inherited != null && inherited.trim().isNotEmpty) {
    return inherited;
  }
  return studentInstrument;
}
