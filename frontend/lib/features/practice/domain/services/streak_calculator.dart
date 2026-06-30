import '../entities/practice_log.dart';

/// Authoritative streak values computed purely from practice logs.
///
/// Mirrors the backend `StreakSummary`
/// (docs/specs/practice/streak_ssot.md §1).
class StreakSummary {
  final int currentStreak;
  final int longestStreak;

  /// Most recent practiced calendar day, or null if there is none.
  final DateTime? lastPracticeDate;

  /// Count of distinct practiced calendar days over all history.
  final int totalDays;

  const StreakSummary({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    this.totalDays = 0,
  });

  static const StreakSummary empty = StreakSummary();
}

/// Single source of truth for computing a practice streak from logs.
///
/// Mirrors the backend `compute_streak` (docs/specs/practice/streak_ssot.md §1):
/// strict consecutive calendar days, no weekend bridge, gated on
/// `totalMinutes > 0`, with today/yesterday grace. The frontend never invents a
/// second algorithm — every mock surface and provider derives its streak here.
class StreakCalculator {
  const StreakCalculator._();

  /// Compute the streak from log rows. Days are bucketed by calendar date and
  /// gated on `totalMinutes > 0`. [now] defaults to the current time and is
  /// injectable for deterministic tests.
  static StreakSummary fromLogs(Iterable<PracticeLog> logs, {DateTime? now}) {
    final today = _dateKey(now ?? DateTime.now());
    final days = <DateTime>{};
    for (final log in logs) {
      if (log.totalMinutes <= 0) continue;
      days.add(_dateKey(log.date));
    }
    return _summarize(days, today: today);
  }

  static StreakSummary _summarize(
    Set<DateTime> days, {
    required DateTime today,
  }) {
    if (days.isEmpty) return StreakSummary.empty;

    final sorted = days.toList()..sort();
    final last = sorted.last;

    // current: consecutive days counted backward from the most recent practiced
    // day. Grace: the most recent day must be today or yesterday, else 0.
    int current;
    if (last.isBefore(today.subtract(const Duration(days: 1)))) {
      current = 0;
    } else {
      current = 0;
      var cursor = last;
      while (days.contains(cursor)) {
        current += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    // longest: longest run of consecutive days over all history.
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      run = sorted[i].difference(sorted[i - 1]).inDays == 1 ? run + 1 : 1;
      if (run > longest) longest = run;
    }

    return StreakSummary(
      currentStreak: current,
      longestStreak: longest,
      lastPracticeDate: DateTime(last.year, last.month, last.day),
      totalDays: days.length,
    );
  }

  /// Normalize to a UTC midnight so day arithmetic stays DST-free while
  /// preserving the input's wall-clock calendar day.
  static DateTime _dateKey(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}
