// Badge award provider: checks conditions and awards badges automatically.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/gamification.dart';
import 'gamification_provider.dart';

part 'badge_award_provider.g.dart';

/// Condition definition for automatic badge awards.
class BadgeCondition {
  final String badgeId;
  final String name;
  final String description;
  final String icon;
  final BadgeRarity rarity;
  final bool Function(StudentGamification gamification) checkFunction;

  const BadgeCondition({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.checkFunction,
  });
}

/// All automatic badge conditions (from gamification spec section 4.1).
final List<BadgeCondition> autoBadgeConditions = [
  BadgeCondition(
    badgeId: 'badge_first_practice',
    name: '첫 연습',
    description: '첫 연습 기록을 완료했습니다',
    icon: 'music_note',
    rarity: BadgeRarity.common,
    checkFunction: (g) => g.totalPoints > 0,
  ),
  BadgeCondition(
    badgeId: 'badge_streak_7',
    name: '7일 스트릭',
    description: '7일 연속 연습을 달성했습니다',
    icon: 'local_fire_department',
    rarity: BadgeRarity.rare,
    checkFunction: (g) => _hasStreakBonus(g, days: 7),
  ),
  BadgeCondition(
    badgeId: 'badge_streak_30',
    name: '30일 스트릭',
    description: '30일 연속 연습을 달성했습니다',
    icon: 'whatshot',
    rarity: BadgeRarity.epic,
    checkFunction: (g) => _hasStreakBonus(g, days: 30),
  ),
  BadgeCondition(
    badgeId: 'badge_streak_100',
    name: '100일 스트릭',
    description: '100일 연속 연습을 달성했습니다',
    icon: 'military_tech',
    rarity: BadgeRarity.legendary,
    checkFunction: (g) => _hasStreakBonus(g, days: 100),
  ),
  BadgeCondition(
    badgeId: 'badge_first_recording',
    name: '첫 녹음',
    description: '첫 녹음을 저장했습니다',
    icon: 'mic',
    rarity: BadgeRarity.common,
    checkFunction:
        (g) => g.recentHistory.any((h) => h.description.contains('녹음')),
  ),
  BadgeCondition(
    badgeId: 'badge_weekly_all_clear',
    name: '과제 올클리어',
    description: '이번 주 과제를 100% 완료했습니다',
    icon: 'task_alt',
    rarity: BadgeRarity.rare,
    checkFunction:
        (g) => g.recentHistory.any((h) => h.type == PointType.goalAchieved),
  ),
  BadgeCondition(
    badgeId: 'badge_monthly_champion',
    name: '연습왕',
    description: '월간 포인트 1위를 달성했습니다',
    icon: 'emoji_events',
    rarity: BadgeRarity.epic,
    // Mock: high total points indicates class leader
    checkFunction: (g) => g.totalPoints >= 2000,
  ),
  BadgeCondition(
    badgeId: 'badge_consistency',
    name: '꾸준함의 힘',
    description: '3개월 연속 주 5일 이상 연습했습니다',
    icon: 'trending_up',
    rarity: BadgeRarity.legendary,
    // Mock: level 5+ approximates 3 months of consistent practice
    checkFunction: (g) => g.level >= 5,
  ),
  BadgeCondition(
    badgeId: 'badge_repertoire_master',
    name: '레퍼토리 마스터',
    description: '5곡 이상 레퍼토리를 완주했습니다',
    icon: 'library_music',
    rarity: BadgeRarity.epic,
    // Mock: check via point history for multiple goal achievements
    checkFunction:
        (g) =>
            g.recentHistory
                .where((h) => h.type == PointType.goalAchieved)
                .length >=
            5,
  ),
];

/// Check streak bonus from point history.
bool _hasStreakBonus(StudentGamification g, {required int days}) {
  return g.recentHistory.any(
    (h) => h.type == PointType.streakBonus && h.description.contains('$days일'),
  );
}

/// Check badge eligibility and return newly eligible badges.
///
/// Compares [autoBadgeConditions] against the student's current gamification
/// state. Returns only badges that satisfy conditions but are not yet earned.
@riverpod
Future<List<PracticeBadge>> checkBadgeEligibility(
  CheckBadgeEligibilityRef ref,
  String studentId,
) async {
  final gamification = await ref.watch(
    studentGamificationProvider(studentId).future,
  );

  final earnedIds =
      gamification.earnedBadges
          .where((b) => b.isEarned)
          .map((b) => b.id)
          .toSet();

  final newlyEligible = <PracticeBadge>[];

  for (final condition in autoBadgeConditions) {
    if (earnedIds.contains(condition.badgeId)) continue;

    if (condition.checkFunction(gamification)) {
      newlyEligible.add(
        PracticeBadge(
          id: condition.badgeId,
          name: condition.name,
          description: condition.description,
          icon: condition.icon,
          rarity: condition.rarity,
          earnedAt: DateTime.now(),
          isEarned: true,
        ),
      );
    }
  }

  return newlyEligible;
}

/// Queue of badges newly awarded in the current session, keyed by studentId.
///
/// UI listens to this to show badge-earned toasts/animations. Callers invoke
/// [RecentlyAwardedBadges.consume] after displaying to clear the queue.
@Riverpod(keepAlive: true)
class RecentlyAwardedBadges extends _$RecentlyAwardedBadges {
  @override
  List<PracticeBadge> build(String studentId) => const [];

  void push(List<PracticeBadge> badges) {
    if (badges.isEmpty) return;
    state = [...state, ...badges];
  }

  void consume() {
    if (state.isEmpty) return;
    state = const [];
  }
}
