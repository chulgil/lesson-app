import '../entities/cancel_reason.dart';

/// Outcome of the cancellation credit computation.
///
/// Pure value object — see lesson_cancellation_flow_spec §2, §3.3, §7, §8.2.
class CancellationCreditOutcome {
  /// Credits consumed by this cancellation (0 or 1).
  final int creditUsed;

  /// Remaining credits after applying [creditUsed].
  final int remainingAfter;

  /// True when the cancellation happened before the deadline (free).
  final bool beforeDeadline;

  /// True when the cancellation must be blocked:
  /// after-deadline student cancel with no remaining credits (spec §8.2).
  final bool blocked;

  const CancellationCreditOutcome({
    required this.creditUsed,
    required this.remainingAfter,
    required this.beforeDeadline,
    required this.blocked,
  });
}

/// Pure policy for lesson cancellation credit (single source of truth).
///
/// Backend remains the eventual enforcement point; this function keeps the
/// app's displayed credit info correct and consistent with the spec.
class CancellationCreditPolicy {
  const CancellationCreditPolicy();

  /// Compute the credit outcome for a cancellation.
  ///
  /// - [reason]: cancellation reason.
  /// - [lessonStart]: scheduled start datetime of the lesson being cancelled.
  /// - [now]: current time (injected for testability).
  /// - [deadlineHours]: free-cancel window before [lessonStart].
  /// - [usedReschedule]/[maxReschedule]: current credit counters.
  CancellationCreditOutcome compute({
    required CancelReason reason,
    required DateTime lessonStart,
    required DateTime now,
    required int deadlineHours,
    required int usedReschedule,
    required int maxReschedule,
  }) {
    final remaining = maxReschedule - usedReschedule;
    final deadline = lessonStart.subtract(Duration(hours: deadlineHours));
    final beforeDeadline = now.isBefore(deadline);

    // Teacher / mutual cancels never consume a credit (spec §2).
    if (!reason.isStudentReason) {
      return CancellationCreditOutcome(
        creditUsed: 0,
        remainingAfter: remaining,
        beforeDeadline: beforeDeadline,
        blocked: false,
      );
    }

    // Student cancel before the deadline is free (spec §3.3).
    if (beforeDeadline) {
      return CancellationCreditOutcome(
        creditUsed: 0,
        remainingAfter: remaining,
        beforeDeadline: true,
        blocked: false,
      );
    }

    // After the deadline with no credits left → block (spec §8.2).
    if (remaining <= 0) {
      return const CancellationCreditOutcome(
        creditUsed: 0,
        remainingAfter: 0,
        beforeDeadline: false,
        blocked: true,
      );
    }

    // After the deadline → consume one credit.
    return CancellationCreditOutcome(
      creditUsed: 1,
      remainingAfter: remaining - 1,
      beforeDeadline: false,
      blocked: false,
    );
  }
}
