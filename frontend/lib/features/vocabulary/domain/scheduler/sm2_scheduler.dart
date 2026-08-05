import '../entities/card_review_state.dart';
import '../entities/review_grade.dart';
import 'review_scheduler.dart';

/// SuperMemo-2 scheduler — the algorithm Anki was historically built on
/// (P. Woźniak, 1987). Deterministic, pure, no ML/backend (#1124).
///
/// Per review with quality `q = grade.quality` (again 2 / hard 3 / good 4 / easy 5):
/// 1. Update the ease factor: `EF' = EF + (0.1 - (5-q)*(0.08+(5-q)*0.02))`, floored
///    at 1.3 (below that cards recur uselessly — "ease hell").
/// 2. On a pass (`q >= 3`) increment the repetition count; the interval is 1 day
///    (1st rep), 6 days (2nd), then `round(previousInterval * EF')`.
/// 3. On a lapse (`q < 3`) reset repetitions to 0 and the interval to 1 day (the
///    card re-enters learning); the ease penalty from step 1 still applies.
///
/// Deliberate divergence from the most-cited SM-2 ports: the mature interval uses
/// the UPDATED EF' (not the pre-review EF), so Hard shortens and Easy lengthens the
/// next interval — identical for Good, whose EF delta is 0. This is locked by test.
///
/// Raw SM-2: it omits Anki's later tweaks (sub-day learning steps, Easy graduation
/// jumps, "interval must grow ≥1 day", fuzz) — those belong to a richer scheduler
/// (e.g. FSRS) behind [ReviewScheduler]. A lapse re-shows the card the next
/// calendar day, not same-day.
class Sm2Scheduler implements ReviewScheduler {
  const Sm2Scheduler();

  static const double _minEaseFactor = 1.3;

  /// Due date at day granularity: [intervalDays] calendar days after the review
  /// date, at local midnight. Calendar arithmetic (not 24h × N) so a DST
  /// transition can't push the due date onto the wrong day, and a consumer can
  /// bucket "due today" by date with no time-of-day fringe.
  static DateTime _dueCalendarDate(DateTime reviewedAt, int intervalDays) =>
      DateTime(reviewedAt.year, reviewedAt.month, reviewedAt.day + intervalDays);

  @override
  CardReviewState review(
    CardReviewState state,
    ReviewGrade grade,
    DateTime reviewedAt,
  ) {
    final q = grade.quality;

    // 1. Ease factor update (applies on both pass and lapse), floored at 1.3.
    final rawEase =
        state.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    final easeFactor = rawEase < _minEaseFactor ? _minEaseFactor : rawEase;

    // 2/3. Repetitions and interval.
    final int repetitions;
    final int intervalDays;
    if (!grade.passed) {
      repetitions = 0;
      intervalDays = 1;
    } else {
      repetitions = state.repetitions + 1;
      if (repetitions == 1) {
        intervalDays = 1;
      } else if (repetitions == 2) {
        intervalDays = 6;
      } else {
        intervalDays = (state.intervalDays * easeFactor).round();
      }
    }

    return state.copyWith(
      easeFactor: easeFactor,
      repetitions: repetitions,
      intervalDays: intervalDays,
      dueDate: _dueCalendarDate(reviewedAt, intervalDays),
      lastReviewedAt: reviewedAt,
    );
  }
}
