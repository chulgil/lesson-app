import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/data/repositories/mock_practice_repository.dart';
import 'package:lessonaza/features/practice/data/repositories/mock_practice_stats_repository.dart';

/// The streak shown for a student must be identical across every mock surface:
/// they all derive it from the same shared logs + StreakCalculator (the single
/// source of truth, docs/specs/practice/streak_ssot.md §3). This is a consumer
/// contract, not an implementation mirror.
void main() {
  test('mock streak agrees across practice and stats surfaces', () async {
    final practice = MockPracticeRepository();
    final stats = MockPracticeStatsRepository();
    final now = DateTime.now();

    for (final studentId in const ['student_1', 'student_11', 'student_3']) {
      final providerStreak = await practice.getStreak(studentId);
      final report = await stats.getMonthlyReport(
        studentId,
        now.year,
        now.month,
      );

      expect(
        report.currentStreak,
        providerStreak.currentStreak,
        reason: '$studentId current streak diverges between surfaces',
      );
      expect(
        report.maxStreak,
        providerStreak.longestStreak,
        reason: '$studentId longest streak diverges between surfaces',
      );
    }
  });

  test('mock streak self-heals from logs (regression: cached zero)', () async {
    // getStreak used to return a cached 0 for every student because the streak
    // was only ever computed by updateStreak/recordPractice, never on read.
    final practice = MockPracticeRepository();
    final streak = await practice.getStreak('student_11'); // practices 7/7 days

    expect(streak.currentStreak, 7);
    expect(streak.longestStreak, 7);
  });
}
