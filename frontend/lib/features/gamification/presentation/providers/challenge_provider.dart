import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/challenge.dart';

part 'challenge_provider.g.dart';

/// Provides the list of active challenges for a student.
@riverpod
Future<List<Challenge>> studentChallenges(Ref ref, String studentId) async {
  // TODO: Replace with repository call when backend is ready
  return _generateMockChallenges();
}

/// Provides only active (non-completed, non-expired) challenges.
@riverpod
Future<List<Challenge>> activeChallenges(Ref ref, String studentId) async {
  final all = await ref.watch(studentChallengesProvider(studentId).future);
  return all.where((c) => c.isActive).toList();
}

/// Provides completed challenges.
@riverpod
Future<List<Challenge>> completedChallenges(Ref ref, String studentId) async {
  final all = await ref.watch(studentChallengesProvider(studentId).future);
  return all.where((c) => c.isCompleted).toList();
}

/// Generate mock challenges based on current week/month.
List<Challenge> _generateMockChallenges() {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);

  return [
    // Weekly challenges
    Challenge(
      id: 'wk_practice_5',
      title: '주간 연습왕',
      description: '이번 주 5일 이상 연습하기',
      type: ChallengeType.practiceDays,
      period: ChallengePeriod.weekly,
      targetValue: 5,
      currentValue: 3,
      rewardPoints: 100,
      startDate: weekStart,
      endDate: weekEnd,
    ),
    Challenge(
      id: 'wk_recording_3',
      title: '녹음 마스터',
      description: '이번 주 녹음 3회 이상 하기',
      type: ChallengeType.recordings,
      period: ChallengePeriod.weekly,
      targetValue: 3,
      currentValue: 1,
      rewardPoints: 50,
      startDate: weekStart,
      endDate: weekEnd,
    ),
    Challenge(
      id: 'wk_minutes_120',
      title: '집중 연습',
      description: '이번 주 총 120분 이상 연습하기',
      type: ChallengeType.practiceMinutes,
      period: ChallengePeriod.weekly,
      targetValue: 120,
      currentValue: 85,
      rewardPoints: 80,
      startDate: weekStart,
      endDate: weekEnd,
    ),

    // Monthly challenges
    Challenge(
      id: 'mo_streak_14',
      title: '월간 연속 연습',
      description: '이번 달 14일 연속 연습 달성하기',
      type: ChallengeType.streak,
      period: ChallengePeriod.monthly,
      targetValue: 14,
      currentValue: 7,
      rewardPoints: 300,
      rewardBadgeId: 'monthly_streak_badge',
      startDate: monthStart,
      endDate: monthEnd,
    ),
    Challenge(
      id: 'mo_lessons_8',
      title: '레슨 개근',
      description: '이번 달 레슨 8회 완료하기',
      type: ChallengeType.lessons,
      period: ChallengePeriod.monthly,
      targetValue: 8,
      currentValue: 4,
      rewardPoints: 200,
      startDate: monthStart,
      endDate: monthEnd,
    ),
    Challenge(
      id: 'mo_points_500',
      title: '포인트 수집가',
      description: '이번 달 500P 이상 획득하기',
      type: ChallengeType.pointsEarned,
      period: ChallengePeriod.monthly,
      targetValue: 500,
      currentValue: 320,
      rewardPoints: 150,
      startDate: monthStart,
      endDate: monthEnd,
    ),

    // Completed example
    Challenge(
      id: 'wk_practice_3_done',
      title: '첫 걸음',
      description: '이번 주 3일 이상 연습하기',
      type: ChallengeType.practiceDays,
      period: ChallengePeriod.weekly,
      targetValue: 3,
      currentValue: 3,
      rewardPoints: 50,
      startDate: weekStart,
      endDate: weekEnd,
      isCompleted: true,
      completedAt: now.subtract(const Duration(days: 1)),
    ),
  ];
}
