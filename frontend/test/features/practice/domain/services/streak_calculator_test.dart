import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_log.dart';
import 'package:lessonaza/features/practice/domain/services/streak_calculator.dart';

/// Oracle = the canonical spec (docs/specs/practice/streak_ssot.md §1), not the
/// implementation. Strict consecutive KST calendar days, no weekend bridge,
/// minutes-gated, today/yesterday grace. Mirrors the backend `compute_streak`.
void main() {
  // Fixed reference day so cases are deterministic regardless of wall clock /
  // timezone. June has no DST transition and KST has no DST at all.
  final now = DateTime(2026, 6, 11, 10, 30);

  PracticeLog logOn(int year, int month, int day, {int minutes = 30}) {
    final date = DateTime(year, month, day);
    return PracticeLog(
      id: 'log_$year-$month-$day-$minutes',
      studentId: 's1',
      date: date,
      totalMinutes: minutes,
      tasks: const [],
      createdAt: date,
    );
  }

  group('StreakCalculator.fromLogs (spec §1)', () {
    test('(a) N consecutive days ending today -> current = N', () {
      final summary = StreakCalculator.fromLogs([
        logOn(2026, 6, 9),
        logOn(2026, 6, 10),
        logOn(2026, 6, 11),
      ], now: now);
      expect(summary.currentStreak, 3);
      expect(summary.longestStreak, 3);
      expect(summary.lastPracticeDate?.day, 11);
      expect(summary.totalDays, 3);
    });

    test(
      '(b) ended yesterday, today not practiced -> current kept (grace)',
      () {
        final summary = StreakCalculator.fromLogs([
          logOn(2026, 6, 8),
          logOn(2026, 6, 9),
          logOn(2026, 6, 10),
        ], now: now);
        expect(summary.currentStreak, 3, reason: 'yesterday is within grace');
        expect(summary.longestStreak, 3);
        expect(summary.lastPracticeDate?.day, 10);
      },
    );

    test('(c) ended the day before yesterday -> current = 0', () {
      final summary = StreakCalculator.fromLogs([
        logOn(2026, 6, 8),
        logOn(2026, 6, 9),
      ], now: now);
      expect(summary.currentStreak, 0, reason: 'gap beyond grace breaks it');
      expect(summary.longestStreak, 2);
      expect(summary.lastPracticeDate?.day, 9);
    });

    test('(d) two-day gap is NOT bridged (no weekend bridge)', () {
      // Mon-Fri (Jun 1-5), then Sat-Sun gap (Jun 6-7), then Mon (Jun 8).
      // The strict streak does not bridge the weekend: longest is 5, not 6.
      final summary = StreakCalculator.fromLogs([
        logOn(2026, 6, 1),
        logOn(2026, 6, 2),
        logOn(2026, 6, 3),
        logOn(2026, 6, 4),
        logOn(2026, 6, 5),
        logOn(2026, 6, 8),
      ], now: now);
      expect(
        summary.longestStreak,
        5,
        reason: 'weekend gap must break the run',
      );
      expect(summary.currentStreak, 0, reason: 'last practice is 3 days ago');
      expect(summary.totalDays, 6);
    });

    test('(e) longest can exceed current', () {
      // Past run of 5 (Jun 1-5), gap, then current run of 2 (Jun 10-11=today).
      final summary = StreakCalculator.fromLogs([
        logOn(2026, 6, 1),
        logOn(2026, 6, 2),
        logOn(2026, 6, 3),
        logOn(2026, 6, 4),
        logOn(2026, 6, 5),
        logOn(2026, 6, 10),
        logOn(2026, 6, 11),
      ], now: now);
      expect(summary.currentStreak, 2);
      expect(summary.longestStreak, 5);
    });

    test('(f) zero-minute logs do not count', () {
      final summary = StreakCalculator.fromLogs([
        logOn(2026, 6, 10, minutes: 0),
        logOn(2026, 6, 11, minutes: 0),
      ], now: now);
      expect(summary.currentStreak, 0);
      expect(summary.longestStreak, 0);
      expect(summary.lastPracticeDate, isNull);
      expect(summary.totalDays, 0);
    });

    test('(g) multiple logs on the same calendar day count once', () {
      final summary = StreakCalculator.fromLogs([
        logOn(2026, 6, 11, minutes: 20),
        logOn(2026, 6, 11, minutes: 40),
      ], now: now);
      expect(summary.currentStreak, 1);
      expect(summary.longestStreak, 1);
      expect(summary.totalDays, 1, reason: 'same day deduped');
    });

    test('mixed minutes-gate: only days with minutes > 0 count', () {
      final summary = StreakCalculator.fromLogs([
        logOn(2026, 6, 10, minutes: 0),
        logOn(2026, 6, 11, minutes: 30),
      ], now: now);
      expect(
        summary.currentStreak,
        1,
        reason: 'Jun 10 gated out, Jun 11 today',
      );
      expect(summary.totalDays, 1);
    });

    test('empty logs -> zeroed summary', () {
      final summary = StreakCalculator.fromLogs(const [], now: now);
      expect(summary.currentStreak, 0);
      expect(summary.longestStreak, 0);
      expect(summary.lastPracticeDate, isNull);
      expect(summary.totalDays, 0);
    });
  });
}
