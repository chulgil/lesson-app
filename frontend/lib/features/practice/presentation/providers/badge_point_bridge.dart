// Bridge — listens to PointAwardNotifier and triggers BadgeChecker.
//
// Single direction: practice → gamification. PointAwardService stays
// agnostic of the practice badge system; this bridge subscribes to its
// state and replays into [practiceBadgeStateNotifierProvider].
//
// Wire by `ref.watch(badgePointBridgeProvider(studentId))` near the
// student root (typically alongside [BadgePopupListener]).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../gamification/gamification_facade.dart';
import '../../domain/services/badge_checker.dart';
import 'badge_provider.dart';

part 'badge_point_bridge.g.dart';

/// Subscribes to [pointAwardNotifierProvider] and routes new awards to
/// the practice badge checker. Returns the number of point entries
/// observed so far (mostly for debug/diagnostics).
@Riverpod(keepAlive: true)
int badgePointBridge(Ref ref, String studentId) {
  final history = ref.watch(pointAwardNotifierProvider);
  final relevant = history.where((e) => e.studentId == studentId).toList();
  if (relevant.isEmpty) return 0;

  // Build a minimal stats snapshot from the point history. Real data
  // sources (streak, repertoire, reactions) can override this snapshot
  // when wired; here we only need triggers that point activity proves.
  final last = relevant.last;
  final stats = _statsFromHistory(relevant);
  final trigger = _triggerFor(last);

  // Defer evaluation to the next microtask so we don't mutate provider
  // state while building.
  Future.microtask(() {
    ref
        .read(practiceBadgeStateNotifierProvider(studentId).notifier)
        .evaluate(stats: stats, trigger: trigger);
  });
  return relevant.length;
}

BadgeTrigger _triggerFor(PointHistory entry) {
  switch (entry.type) {
    case PointType.streakBonus:
      return BadgeTrigger.onStreak;
    case PointType.practiceComplete:
      if (entry.description.contains('녹음')) return BadgeTrigger.onRecording;
      return BadgeTrigger.onPoint;
    case PointType.goalAchieved:
    case PointType.lessonAttendance:
    case PointType.badgeEarned:
      return BadgeTrigger.onPoint;
  }
}

PracticeStatsSnapshot _statsFromHistory(List<PointHistory> history) {
  int practiceCount = 0;
  int streakDays = 0;
  for (final h in history) {
    if (h.type == PointType.practiceComplete) practiceCount++;
    if (h.type == PointType.streakBonus) {
      // Description e.g. "7일 스트릭 보너스".
      final match = RegExp(r'(\d+)일').firstMatch(h.description);
      if (match != null) {
        final days = int.tryParse(match.group(1)!) ?? 0;
        if (days > streakDays) streakDays = days;
      }
    }
  }
  return PracticeStatsSnapshot(
    totalPracticeCount: practiceCount,
    currentStreakDays: streakDays,
  );
}
