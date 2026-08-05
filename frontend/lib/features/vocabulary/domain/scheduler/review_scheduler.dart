import '../entities/card_review_state.dart';
import '../entities/review_grade.dart';

/// Computes the next spaced-repetition state for a card given the learner's
/// [ReviewGrade] (#1124).
///
/// The seam that keeps the scheduling algorithm swappable: the first slice ships
/// [Sm2Scheduler] (classic SuperMemo-2, Anki's historical algorithm); a future
/// slice can drop in an FSRS-based implementation (Anki's modern ML scheduler)
/// without touching callers — mirroring the discipline platform's registry seams.
abstract class ReviewScheduler {
  /// The next state after reviewing a card in [state] with [grade] at
  /// [reviewedAt]. Pure: [reviewedAt] is injected (never reads the clock) so the
  /// result is deterministic and testable.
  CardReviewState review(
    CardReviewState state,
    ReviewGrade grade,
    DateTime reviewedAt,
  );
}
