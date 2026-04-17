// Point award service for granting points on practice activities.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/gamification.dart';
import 'badge_award_provider.dart';
import 'gamification_provider.dart';

part 'point_award_service.g.dart';

/// Rule defining how points are awarded for a specific activity.
class PointAwardRule {
  final PointType source;
  final int points;
  final String description;
  final int? dailyLimit;

  const PointAwardRule({
    required this.source,
    required this.points,
    required this.description,
    this.dailyLimit,
  });

  /// All point award rules matching gamification spec.
  static const List<PointAwardRule> rules = [
    PointAwardRule(
      source: PointType.practiceComplete,
      points: 30,
      description: '일일 연습 완료',
      dailyLimit: 1,
    ),
    PointAwardRule(
      source: PointType.practiceComplete,
      points: 20,
      description: '과제 항목 완료',
    ),
    PointAwardRule(
      source: PointType.goalAchieved,
      points: 50,
      description: '연습 목표 달성',
      dailyLimit: 1,
    ),
    PointAwardRule(
      source: PointType.streakBonus,
      points: 100,
      description: '7일 스트릭 보너스',
    ),
    PointAwardRule(
      source: PointType.streakBonus,
      points: 500,
      description: '30일 스트릭 보너스',
    ),
    PointAwardRule(
      source: PointType.practiceComplete,
      points: 10,
      description: '녹음 등록',
    ),
  ];
}

/// State holding awarded point history entries.
typedef PointAwardState = List<PointHistory>;

@riverpod
class PointAwardNotifier extends _$PointAwardNotifier {
  int _idCounter = 0;

  @override
  PointAwardState build() => const [];

  /// Award 30P for daily practice completion.
  PointHistory awardPracticeComplete(String studentId) {
    final entry = _createEntry(
      studentId: studentId,
      points: 30,
      type: PointType.practiceComplete,
      description: '일일 연습 완료',
    );
    state = [...state, entry];
    _triggerBadgeCheck(studentId);
    return entry;
  }

  /// Award 20P for completing a task item.
  PointHistory awardTaskComplete(String studentId, String taskName) {
    final entry = _createEntry(
      studentId: studentId,
      points: 20,
      type: PointType.practiceComplete,
      description: '과제 완료: $taskName',
    );
    state = [...state, entry];
    _triggerBadgeCheck(studentId);
    return entry;
  }

  /// Award 50P for achieving a practice goal.
  PointHistory awardGoalAchieved(String studentId) {
    final entry = _createEntry(
      studentId: studentId,
      points: 50,
      type: PointType.goalAchieved,
      description: '연습 목표 달성',
    );
    state = [...state, entry];
    _triggerBadgeCheck(studentId);
    return entry;
  }

  /// Award streak bonus: 100P for 7-day, 500P for 30-day.
  PointHistory? awardStreakBonus(String studentId, int streakDays) {
    if (streakDays != 7 && streakDays != 30) return null;

    final points = streakDays == 30 ? 500 : 100;
    final entry = _createEntry(
      studentId: studentId,
      points: points,
      type: PointType.streakBonus,
      description: '${streakDays}일 스트릭 보너스',
    );
    state = [...state, entry];
    _triggerBadgeCheck(studentId);
    return entry;
  }

  /// Award 10P for saving a recording.
  PointHistory awardRecordingSaved(String studentId) {
    final entry = _createEntry(
      studentId: studentId,
      points: 10,
      type: PointType.practiceComplete,
      description: '녹음 등록',
    );
    state = [...state, entry];
    _triggerBadgeCheck(studentId);
    return entry;
  }

  /// Evaluate badge conditions and persist any newly eligible badges.
  ///
  /// Invalidates [studentGamificationProvider] afterward so UI refreshes.
  /// Newly awarded badges are exposed via [recentlyAwardedBadgesProvider].
  Future<void> _triggerBadgeCheck(String studentId) async {
    final repo = ref.read(gamificationRepositoryProvider);
    final eligible = await ref.read(
      checkBadgeEligibilityProvider(studentId).future,
    );
    if (eligible.isEmpty) return;

    await repo.awardBadges(studentId, eligible);

    ref.read(recentlyAwardedBadgesProvider(studentId).notifier).push(eligible);
    ref.invalidate(studentGamificationProvider(studentId));
    ref.invalidate(checkBadgeEligibilityProvider(studentId));
  }

  /// Get total points awarded for a student in current session.
  int totalPointsFor(String studentId) {
    return state
        .where((e) => e.studentId == studentId)
        .fold(0, (sum, e) => sum + e.points);
  }

  PointHistory _createEntry({
    required String studentId,
    required int points,
    required PointType type,
    required String description,
  }) {
    _idCounter++;
    return PointHistory(
      id: 'pa_$_idCounter',
      studentId: studentId,
      points: points,
      type: type,
      description: description,
      earnedAt: DateTime.now(),
    );
  }
}
