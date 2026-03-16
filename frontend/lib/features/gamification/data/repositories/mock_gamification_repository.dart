// Mock gamification repository with test data.

import '../../domain/entities/gamification.dart';
import '../../domain/repositories/gamification_repository.dart';

class MockGamificationRepository implements GamificationRepository {
  @override
  Future<StudentGamification> getStudentGamification(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final now = DateTime.now();

    return StudentGamification(
      studentId: studentId,
      totalPoints: 450,
      level: 3,
      levelTitle: '꾸준한 연주자',
      pointsToNextLevel: 150,
      currentLevelMinPoints: 300,
      nextLevelMinPoints: 600,
      earnedBadges: [
        PracticeBadge(
          id: 'badge_1',
          name: '첫 연습',
          description: '첫 번째 연습을 완료했습니다',
          icon: 'music_note',
          rarity: BadgeRarity.common,
          earnedAt: now.subtract(const Duration(days: 30)),
          isEarned: true,
        ),
        PracticeBadge(
          id: 'badge_2',
          name: '7일 스트릭',
          description: '7일 연속 연습을 달성했습니다',
          icon: 'local_fire_department',
          rarity: BadgeRarity.rare,
          earnedAt: now.subtract(const Duration(days: 14)),
          isEarned: true,
        ),
        PracticeBadge(
          id: 'badge_3',
          name: '목표 달성자',
          description: '연습 목표를 3회 달성했습니다',
          icon: 'emoji_events',
          rarity: BadgeRarity.rare,
          earnedAt: now.subtract(const Duration(days: 7)),
          isEarned: true,
        ),
        const PracticeBadge(
          id: 'badge_4',
          name: '30일 스트릭',
          description: '30일 연속 연습을 달성하세요',
          icon: 'whatshot',
          rarity: BadgeRarity.epic,
          isEarned: false,
        ),
        const PracticeBadge(
          id: 'badge_5',
          name: '연습 마스터',
          description: '총 100시간 연습을 달성하세요',
          icon: 'star',
          rarity: BadgeRarity.legendary,
          isEarned: false,
        ),
      ],
      recentHistory: [
        PointHistory(
          id: 'ph_1',
          studentId: studentId,
          points: 10,
          type: PointType.practiceComplete,
          description: '연습 완료',
          earnedAt: now.subtract(const Duration(hours: 2)),
        ),
        PointHistory(
          id: 'ph_2',
          studentId: studentId,
          points: 5,
          type: PointType.streakBonus,
          description: '14일 스트릭 보너스',
          earnedAt: now.subtract(const Duration(hours: 2)),
        ),
        PointHistory(
          id: 'ph_3',
          studentId: studentId,
          points: 20,
          type: PointType.goalAchieved,
          description: '주간 목표 달성',
          earnedAt: now.subtract(const Duration(days: 1)),
        ),
        PointHistory(
          id: 'ph_4',
          studentId: studentId,
          points: 10,
          type: PointType.lessonAttendance,
          description: '레슨 출석',
          earnedAt: now.subtract(const Duration(days: 2)),
        ),
        PointHistory(
          id: 'ph_5',
          studentId: studentId,
          points: 50,
          type: PointType.badgeEarned,
          description: '뱃지 획득: 목표 달성자',
          earnedAt: now.subtract(const Duration(days: 7)),
        ),
      ],
    );
  }
}
