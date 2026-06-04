// Badge providers — orchestrates Practice §2.7 badge state.
//
// - [badgeCheckerProvider]: singleton stateless checker.
// - [practiceBadgeStateProvider]: per-student earned-badge state + recently
//   awarded queue (drives popup).
// - [practiceBadgeCollectionProvider]: read-only derived list (earned +
//   locked) for the gallery view.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/badge.dart';
import '../../domain/services/badge_checker.dart';

part 'badge_provider.g.dart';

/// Stateless badge checker — kept alive (no per-build cost).
@Riverpod(keepAlive: true)
BadgeChecker badgeChecker(Ref ref) => const BadgeChecker();

/// Per-student badge state — earned set + recently awarded queue.
///
/// Earned badges persist across the session; the queue is consumed by
/// [BadgePopupListener] after presenting the popup.
class PracticeBadgeState {
  final Map<String, Badge> earned;
  final List<Badge> recentlyAwarded;

  const PracticeBadgeState({
    this.earned = const {},
    this.recentlyAwarded = const [],
  });

  PracticeBadgeState copyWith({
    Map<String, Badge>? earned,
    List<Badge>? recentlyAwarded,
  }) {
    return PracticeBadgeState(
      earned: earned ?? this.earned,
      recentlyAwarded: recentlyAwarded ?? this.recentlyAwarded,
    );
  }
}

/// Mutable badge state per student. Kept alive so popups outlive
/// rebuilds of the listening widget.
@Riverpod(keepAlive: true)
class PracticeBadgeStateNotifier extends _$PracticeBadgeStateNotifier {
  @override
  PracticeBadgeState build(String studentId) => const PracticeBadgeState();

  /// Evaluate the checker against [stats] and persist any newly awarded
  /// badges. Returns the list of badges newly awarded in this call.
  List<Badge> evaluate({
    required PracticeStatsSnapshot stats,
    BadgeTrigger trigger = BadgeTrigger.manual,
    DateTime? now,
  }) {
    final checker = ref.read(badgeCheckerProvider);
    final earnedIds = state.earned.keys.toSet();
    final awarded = checker.evaluate(
      stats: stats,
      earnedBadgeIds: earnedIds,
      trigger: trigger,
      now: now,
    );
    if (awarded.isEmpty) return const [];

    final nextEarned = Map<String, Badge>.from(state.earned);
    for (final b in awarded) {
      nextEarned[b.id] = b;
    }
    state = state.copyWith(
      earned: nextEarned,
      recentlyAwarded: [...state.recentlyAwarded, ...awarded],
    );
    return awarded;
  }

  /// Manually grant [type] — used for performance attendance (§2.7 특별).
  Badge? grantManual(BadgeType type, {DateTime? now}) {
    if (state.earned.containsKey(type.id)) return null;
    final checker = ref.read(badgeCheckerProvider);
    final badge = checker.grantManual(type, now: now);
    state = state.copyWith(
      earned: {...state.earned, badge.id: badge},
      recentlyAwarded: [...state.recentlyAwarded, badge],
    );
    return badge;
  }

  /// Clear the recently-awarded queue after the popup has been shown.
  void consumeRecentlyAwarded() {
    if (state.recentlyAwarded.isEmpty) return;
    state = state.copyWith(recentlyAwarded: const []);
  }

  /// Reset state (test/debug only).
  void reset() {
    state = const PracticeBadgeState();
  }
}

/// Gallery view: ordered list of every [BadgeType] with earned status applied.
@riverpod
List<Badge> practiceBadgeCollection(Ref ref, String studentId) {
  final s = ref.watch(practiceBadgeStateNotifierProvider(studentId));
  return [
    for (final type in BadgeType.values)
      s.earned[type.id] ?? Badge.locked(type),
  ];
}
