import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';
import 'package:lessonaza/features/gamification/presentation/extensions/challenge_visuals.dart';

// #965 회귀 0 가드: challenge.dart 의 도메인 표시 getter 를 presentation 으로
// 옮긴 뒤에도 출력이 기존과 동일한지 고정한다.
Challenge _challenge(ActivityType type, int target) => Challenge(
  id: 'c',
  title: 't',
  description: 'd',
  type: type,
  period: ChallengePeriod.weekly,
  targetValue: target,
  currentValue: 0,
  rewardPoints: 0,
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 8),
);

void main() {
  group('ActivityTypeVisuals.icon', () {
    test('returns Material vector icons (no emoji string)', () {
      const expected = {
        ActivityType.practiceDays: Icons.event,
        ActivityType.practiceMinutes: Icons.timer,
        ActivityType.recordings: Icons.mic,
        ActivityType.lessons: Icons.music_note,
        ActivityType.streak: Icons.local_fire_department,
        ActivityType.pointsEarned: Icons.diamond,
      };
      for (final type in ActivityType.values) {
        expect(type.icon, expected[type], reason: type.name);
        expect(type.icon, isA<IconData>());
      }
    });
  });

  group('ChallengePeriodVisuals.displayName', () {
    test('matches legacy labels', () {
      expect(ChallengePeriod.weekly.displayName, '주간');
      expect(ChallengePeriod.monthly.displayName, '월간');
    });
  });

  group('ChallengeVisuals.targetDisplay', () {
    test('matches legacy unit formatting (regression 0)', () {
      expect(_challenge(ActivityType.practiceDays, 5).targetDisplay, '5일');
      expect(_challenge(ActivityType.practiceMinutes, 30).targetDisplay, '30분');
      expect(_challenge(ActivityType.recordings, 3).targetDisplay, '3회');
      expect(_challenge(ActivityType.lessons, 4).targetDisplay, '4회');
      expect(_challenge(ActivityType.streak, 7).targetDisplay, '7일');
      expect(_challenge(ActivityType.pointsEarned, 100).targetDisplay, '100P');
    });
  });
}
