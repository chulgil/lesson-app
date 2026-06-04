// Unit tests for BadgeChecker (§2.7).
//
// Verifies condition matrix for each BadgeType and trigger-relevance gating.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/badge.dart';
import 'package:lessonaza/features/practice/domain/services/badge_checker.dart';

void main() {
  const checker = BadgeChecker();
  final now = DateTime(2026, 6, 4);

  Set<String> ids(Iterable<BadgeType> types) => types.map((t) => t.id).toSet();

  group('firstPractice', () {
    test('not awarded when no practice', () {
      final result = checker.evaluate(
        stats: const PracticeStatsSnapshot(),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(result.any((b) => b.type == BadgeType.firstPractice), isFalse);
    });
    test('awarded after first practice', () {
      final result = checker.evaluate(
        stats: const PracticeStatsSnapshot(totalPracticeCount: 1),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(result.any((b) => b.type == BadgeType.firstPractice), isTrue);
    });
  });

  group('streak ladder', () {
    test('streak_3 only at 3 days', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(currentStreakDays: 3),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.streak3), isTrue);
      expect(types.contains(BadgeType.streak7), isFalse);
    });
    test('streak_30 includes earlier streaks (still not earned)', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(currentStreakDays: 30),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.streak3), isTrue);
      expect(types.contains(BadgeType.streak7), isTrue);
      expect(types.contains(BadgeType.streak30), isTrue);
      expect(types.contains(BadgeType.streak100), isFalse);
    });
    test('streak_100 at exactly 100', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(currentStreakDays: 100),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.streak100), isTrue);
    });
  });

  group('diligence', () {
    test('perfectWeek requires 100% weekly', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(weeklyCompletionRate: 0.99),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.perfectWeek), isFalse);
      final r2 = checker.evaluate(
        stats: const PracticeStatsSnapshot(weeklyCompletionRate: 1.0),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r2.any((b) => b.type == BadgeType.perfectWeek), isTrue);
    });
    test('mustMaster requires 10 must completions', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(mustPracticeCompletedCount: 10),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.mustMaster), isTrue);
    });
    test('practiceKing at >=0.9 monthly', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(monthlyCompletionRate: 0.9),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.practiceKing), isTrue);
    });
  });

  group('challenge', () {
    test('firstPiece requires 1 repertoire completed', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(repertoireCompletedCount: 1),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.firstPiece), isTrue);
      expect(r.any((b) => b.type == BadgeType.fivePieces), isFalse);
    });
    test('fivePieces requires 5 repertoire', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(repertoireCompletedCount: 5),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.fivePieces), isTrue);
    });
    test('challengeKing requires 10 challenge completions', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(challengePracticeCompletedCount: 10),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.challengeKing), isTrue);
    });
  });

  group('special / manual', () {
    test('firstLike at 5 likes', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(likeCount: 5),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.firstLike), isTrue);
      expect(r.any((b) => b.type == BadgeType.lovedStudent), isFalse);
    });
    test('lovedStudent at 20 likes', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(likeCount: 20),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.lovedStudent), isTrue);
    });
    test('performance is manual — never auto-awarded', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(hasPerformanceAttended: true),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.performance), isFalse);
    });
    test('performance grantManual creates earned badge', () {
      final b = checker.grantManual(BadgeType.performance, now: now);
      expect(b.isEarned, isTrue);
      expect(b.type, BadgeType.performance);
      expect(b.earnedAt, now);
    });
  });

  group('idempotency', () {
    test('already-earned badges are skipped', () {
      final r = checker.evaluate(
        stats: const PracticeStatsSnapshot(
          totalPracticeCount: 1,
          currentStreakDays: 3,
        ),
        earnedBadgeIds: ids({BadgeType.firstPractice}),
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.firstPractice), isFalse);
      expect(types.contains(BadgeType.streak3), isTrue);
    });
  });

  group('trigger gating', () {
    test('onStreak excludes practice-only badges', () {
      final r = checker.onStreak(
        stats: const PracticeStatsSnapshot(
          totalPracticeCount: 1,
          currentStreakDays: 3,
          likeCount: 5,
        ),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.streak3), isTrue);
      // firstPractice / firstLike are not in the streak trigger scope.
      expect(types.contains(BadgeType.firstPractice), isFalse);
      expect(types.contains(BadgeType.firstLike), isFalse);
    });
    test('onPoint includes streak badges (point activity may unlock them)', () {
      final r = checker.onPoint(
        stats: const PracticeStatsSnapshot(currentStreakDays: 7),
        earnedBadgeIds: const {},
        now: now,
      );
      expect(r.any((b) => b.type == BadgeType.streak7), isTrue);
    });
    test('onRecording awards first_practice + first_like when valid', () {
      final r = checker.onRecording(
        stats: const PracticeStatsSnapshot(totalPracticeCount: 1, likeCount: 5),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.firstPractice), isTrue);
      expect(types.contains(BadgeType.firstLike), isTrue);
    });
  });

  group('practiceRepeat ladder (#508)', () {
    test('not awarded below 10 cumulative reps', () {
      final r = checker.onPracticeRepeat(
        stats: const PracticeStatsSnapshot(cumulativeRepeatCount: 9),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.practiceRepeat10), isFalse);
    });
    test('practiceRepeat10 awarded at 10 cumulative reps', () {
      final r = checker.onPracticeRepeat(
        stats: const PracticeStatsSnapshot(cumulativeRepeatCount: 10),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.practiceRepeat10), isTrue);
      expect(types.contains(BadgeType.practiceRepeat50), isFalse);
      expect(types.contains(BadgeType.practiceRepeat100), isFalse);
    });
    test('practiceRepeat50 at 50 includes practiceRepeat10', () {
      final r = checker.onPracticeRepeat(
        stats: const PracticeStatsSnapshot(cumulativeRepeatCount: 50),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.practiceRepeat10), isTrue);
      expect(types.contains(BadgeType.practiceRepeat50), isTrue);
      expect(types.contains(BadgeType.practiceRepeat100), isFalse);
    });
    test('practiceRepeat100 at 100 awards all three tiers when unowned', () {
      final r = checker.onPracticeRepeat(
        stats: const PracticeStatsSnapshot(cumulativeRepeatCount: 100),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.practiceRepeat10), isTrue);
      expect(types.contains(BadgeType.practiceRepeat50), isTrue);
      expect(types.contains(BadgeType.practiceRepeat100), isTrue);
    });
    test('repeat badges live in challenge category', () {
      expect(BadgeType.practiceRepeat10.category, BadgeCategory.challenge);
      expect(BadgeType.practiceRepeat50.category, BadgeCategory.challenge);
      expect(BadgeType.practiceRepeat100.category, BadgeCategory.challenge);
    });
    test('onPracticeRepeat excludes non-repeat practice badges', () {
      // Even with totalPracticeCount/likeCount that would normally trigger
      // other badges, the onPracticeRepeat trigger only handles repeat tiers.
      final r = checker.onPracticeRepeat(
        stats: const PracticeStatsSnapshot(
          totalPracticeCount: 1,
          likeCount: 5,
          cumulativeRepeatCount: 10,
        ),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.practiceRepeat10), isTrue);
      expect(types.contains(BadgeType.firstPractice), isFalse);
      expect(types.contains(BadgeType.firstLike), isFalse);
    });
    test('onPoint does not award repeat badges', () {
      final r = checker.onPoint(
        stats: const PracticeStatsSnapshot(cumulativeRepeatCount: 100),
        earnedBadgeIds: const {},
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.practiceRepeat10), isFalse);
      expect(types.contains(BadgeType.practiceRepeat100), isFalse);
    });
    test('already-earned repeat badges are skipped', () {
      final r = checker.onPracticeRepeat(
        stats: const PracticeStatsSnapshot(cumulativeRepeatCount: 50),
        earnedBadgeIds: ids({BadgeType.practiceRepeat10}),
        now: now,
      );
      final types = r.map((b) => b.type).toSet();
      expect(types.contains(BadgeType.practiceRepeat10), isFalse);
      expect(types.contains(BadgeType.practiceRepeat50), isTrue);
    });
  });

  group('Badge entity', () {
    test('locked + earned factories', () {
      final locked = Badge.locked(BadgeType.firstPractice);
      expect(locked.isEarned, isFalse);
      expect(locked.earnedAt, isNull);
      final earned = Badge.earned(BadgeType.firstPractice, at: now);
      expect(earned.isEarned, isTrue);
      expect(earned.earnedAt, now);
    });
    test('BadgeType.fromId round-trip', () {
      for (final t in BadgeType.values) {
        expect(BadgeTypeMeta.fromId(t.id), t);
      }
      expect(BadgeTypeMeta.fromId('nonsense'), isNull);
    });
  });
}
