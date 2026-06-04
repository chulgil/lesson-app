// BadgeChecker — pure domain service evaluating §2.7 badge conditions.
//
// Stateless. Callers provide a [PracticeStatsSnapshot] and the current set
// of earned badge IDs; the checker returns the badges that should be newly
// awarded. Triggers (onPoint/onStreak/onRecording) are convenience entry
// points that share the same evaluation pipeline.

import '../entities/badge.dart';

/// Snapshot of the practice metrics required by §2.7 conditions.
///
/// Pulled together by callers (typically the provider layer) from streak,
/// practice item, repertoire and reaction sources.
class PracticeStatsSnapshot {
  /// Total completed practice sessions (lifetime).
  final int totalPracticeCount;

  /// Current consecutive-day practice streak.
  final int currentStreakDays;

  /// Weekly completion ratio (0.0 – 1.0).
  final double weeklyCompletionRate;

  /// Monthly completion ratio (0.0 – 1.0).
  final double monthlyCompletionRate;

  /// Number of completed "must" priority practice items (lifetime).
  final int mustPracticeCompletedCount;

  /// Number of completed "could" / challenge practice items (lifetime).
  final int challengePracticeCompletedCount;

  /// Number of repertoire pieces fully completed.
  final int repertoireCompletedCount;

  /// Number of teacher "likes" received.
  final int likeCount;

  /// Manual flag — performance attendance recorded by the teacher.
  final bool hasPerformanceAttended;

  const PracticeStatsSnapshot({
    this.totalPracticeCount = 0,
    this.currentStreakDays = 0,
    this.weeklyCompletionRate = 0.0,
    this.monthlyCompletionRate = 0.0,
    this.mustPracticeCompletedCount = 0,
    this.challengePracticeCompletedCount = 0,
    this.repertoireCompletedCount = 0,
    this.likeCount = 0,
    this.hasPerformanceAttended = false,
  });

  PracticeStatsSnapshot copyWith({
    int? totalPracticeCount,
    int? currentStreakDays,
    double? weeklyCompletionRate,
    double? monthlyCompletionRate,
    int? mustPracticeCompletedCount,
    int? challengePracticeCompletedCount,
    int? repertoireCompletedCount,
    int? likeCount,
    bool? hasPerformanceAttended,
  }) {
    return PracticeStatsSnapshot(
      totalPracticeCount: totalPracticeCount ?? this.totalPracticeCount,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      weeklyCompletionRate: weeklyCompletionRate ?? this.weeklyCompletionRate,
      monthlyCompletionRate:
          monthlyCompletionRate ?? this.monthlyCompletionRate,
      mustPracticeCompletedCount:
          mustPracticeCompletedCount ?? this.mustPracticeCompletedCount,
      challengePracticeCompletedCount:
          challengePracticeCompletedCount ??
          this.challengePracticeCompletedCount,
      repertoireCompletedCount:
          repertoireCompletedCount ?? this.repertoireCompletedCount,
      likeCount: likeCount ?? this.likeCount,
      hasPerformanceAttended:
          hasPerformanceAttended ?? this.hasPerformanceAttended,
    );
  }
}

/// Reason a checker run was initiated. Allows callers to gate badge
/// trigger types when only a subset of metrics changed.
enum BadgeTrigger {
  /// Awarded when point activity completes (practice, task, goal).
  onPoint,

  /// Awarded when streak day count advances.
  onStreak,

  /// Awarded when a new recording is saved.
  onRecording,

  /// Manual / explicit re-check (no specific trigger).
  manual,
}

/// Stateless evaluator for §2.7 badge conditions.
class BadgeChecker {
  const BadgeChecker();

  /// Evaluate every (non-earned) badge against [stats] and return newly
  /// eligible badges. [now] override exists for deterministic tests.
  List<Badge> evaluate({
    required PracticeStatsSnapshot stats,
    required Set<String> earnedBadgeIds,
    BadgeTrigger trigger = BadgeTrigger.manual,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final awarded = <Badge>[];

    for (final type in BadgeType.values) {
      if (earnedBadgeIds.contains(type.id)) continue;
      if (type.isManual) continue; // performance — manual grant only
      if (!_isRelevantFor(type, trigger)) continue;
      if (_meetsCondition(type, stats)) {
        awarded.add(Badge.earned(type, at: timestamp));
      }
    }
    return awarded;
  }

  /// Convenience — invoked when points were just awarded.
  List<Badge> onPoint({
    required PracticeStatsSnapshot stats,
    required Set<String> earnedBadgeIds,
    DateTime? now,
  }) => evaluate(
    stats: stats,
    earnedBadgeIds: earnedBadgeIds,
    trigger: BadgeTrigger.onPoint,
    now: now,
  );

  /// Convenience — invoked when streak day count advances.
  List<Badge> onStreak({
    required PracticeStatsSnapshot stats,
    required Set<String> earnedBadgeIds,
    DateTime? now,
  }) => evaluate(
    stats: stats,
    earnedBadgeIds: earnedBadgeIds,
    trigger: BadgeTrigger.onStreak,
    now: now,
  );

  /// Convenience — invoked after a recording is saved.
  List<Badge> onRecording({
    required PracticeStatsSnapshot stats,
    required Set<String> earnedBadgeIds,
    DateTime? now,
  }) => evaluate(
    stats: stats,
    earnedBadgeIds: earnedBadgeIds,
    trigger: BadgeTrigger.onRecording,
    now: now,
  );

  /// Manually grant a single badge (e.g., performance attendance).
  Badge grantManual(BadgeType type, {DateTime? now}) =>
      Badge.earned(type, at: now ?? DateTime.now());

  // ── internal ─────────────────────────────────────────────────────────

  bool _isRelevantFor(BadgeType type, BadgeTrigger trigger) {
    if (trigger == BadgeTrigger.manual) return true;
    switch (type) {
      case BadgeType.streak3:
      case BadgeType.streak7:
      case BadgeType.streak30:
      case BadgeType.streak100:
        return trigger == BadgeTrigger.onStreak ||
            trigger == BadgeTrigger.onPoint;
      case BadgeType.firstPractice:
      case BadgeType.perfectWeek:
      case BadgeType.mustMaster:
      case BadgeType.practiceKing:
      case BadgeType.firstPiece:
      case BadgeType.fivePieces:
      case BadgeType.challengeKing:
      case BadgeType.firstLike:
      case BadgeType.lovedStudent:
        // Practice / task completions and feedback all funnel through
        // PointAwardService — covered by onPoint or onRecording.
        return trigger != BadgeTrigger.onStreak;
      case BadgeType.performance:
        return false;
    }
  }

  bool _meetsCondition(BadgeType type, PracticeStatsSnapshot s) {
    switch (type) {
      case BadgeType.firstPractice:
        return s.totalPracticeCount >= 1;
      case BadgeType.streak3:
        return s.currentStreakDays >= 3;
      case BadgeType.streak7:
        return s.currentStreakDays >= 7;
      case BadgeType.streak30:
        return s.currentStreakDays >= 30;
      case BadgeType.streak100:
        return s.currentStreakDays >= 100;
      case BadgeType.perfectWeek:
        return s.weeklyCompletionRate >= 1.0;
      case BadgeType.mustMaster:
        return s.mustPracticeCompletedCount >= 10;
      case BadgeType.practiceKing:
        return s.monthlyCompletionRate >= 0.9;
      case BadgeType.firstPiece:
        return s.repertoireCompletedCount >= 1;
      case BadgeType.fivePieces:
        return s.repertoireCompletedCount >= 5;
      case BadgeType.challengeKing:
        return s.challengePracticeCompletedCount >= 10;
      case BadgeType.firstLike:
        return s.likeCount >= 5;
      case BadgeType.lovedStudent:
        return s.likeCount >= 20;
      case BadgeType.performance:
        return s.hasPerformanceAttended;
    }
  }
}
