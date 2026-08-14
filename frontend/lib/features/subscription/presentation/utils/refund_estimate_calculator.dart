import '../../domain/entities/lesson_policy.dart';
import '../../domain/entities/subscription.dart';

/// Reference-only refund amount estimate for the refund request flow
/// (#1271). Both student and teacher see this as a *참고용* number — the
/// teacher always enters the final transferred amount manually
/// ([RefundRequestRepository.complete]).
///
/// Heuristic (documented, not authoritative):
/// 1. Unused value = amount x (remaining / total) — the proportional value
///    of lessons not yet consumed.
/// 2. Ratio applied to the unused value:
///    - Full refund ([LessonPolicy.fullRefundDays] since start, no lessons
///      used yet) -> 1.0
///    - Less than half the lessons used -> [LessonPolicy.partialRefundRatio]
///    - Half or more used -> [LessonPolicy.halfwayRefundRatio]
///
/// Returns null when there is nothing to estimate (no remaining lessons, or
/// the subscription type doesn't carry a lesson total).
int? estimateRefundAmount({
  required Subscription subscription,
  required LessonPolicy policy,
  DateTime? now,
}) {
  final total = subscription.totalLessonsForDisplay;
  final remaining = subscription.remainingLessons;
  if (total == null || total <= 0 || remaining == null || remaining <= 0) {
    return null;
  }

  final unusedValue = (subscription.amount * remaining / total).round();

  final effectiveNow = now ?? DateTime.now();
  final start = subscription.startDate;
  final withinFullRefundWindow =
      start != null &&
      !effectiveNow.isBefore(start) &&
      effectiveNow.difference(start).inDays <= policy.fullRefundDays;

  final double ratio;
  if (withinFullRefundWindow && subscription.usedLessons == 0) {
    ratio = 1.0;
  } else if (subscription.usedLessons / total < 0.5) {
    ratio = policy.partialRefundRatio;
  } else {
    ratio = policy.halfwayRefundRatio;
  }

  return (unusedValue * ratio).round();
}
