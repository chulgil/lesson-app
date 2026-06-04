import '../entities/practice_report.dart';

/// Daily practice input — one row per (date, repertoire) practice block.
///
/// Calculator consumes this raw shape (e.g. derived from PracticeLog,
/// Recording, or PracticeStats) and produces WeeklyReport / MonthlyReport.
class DailyPracticeInput {
  final DateTime date;
  final String repertoireId;
  final String repertoireName;
  final int practiceSeconds;

  const DailyPracticeInput({
    required this.date,
    required this.repertoireId,
    required this.repertoireName,
    required this.practiceSeconds,
  });
}

/// Pure calculator. No Flutter, no Riverpod, no I/O.
class PracticeReportCalculator {
  const PracticeReportCalculator();

  /// Compute weekly report for the ISO week starting Monday `weekStart`.
  ///
  /// `inputs` may contain rows outside the week; they are ignored.
  WeeklyReport calculateWeekly({
    required DateTime weekStart,
    required List<DailyPracticeInput> inputs,
  }) {
    final start = _dateOnly(weekStart);
    final end = start.add(const Duration(days: 6));

    final inRange = inputs.where(
      (i) =>
          !_dateOnly(i.date).isBefore(start) && !_dateOnly(i.date).isAfter(end),
    );

    final dailyEntries = _aggregateDaily(start, end, inRange);
    final repertoireRatios = _aggregateRepertoire(inRange);
    final totalSeconds = inRange.fold<int>(0, (a, b) => a + b.practiceSeconds);
    final practiceDays = dailyEntries
        .where((d) => d.practiceSeconds > 0)
        .length;

    return WeeklyReport(
      weekStart: start,
      weekEnd: end,
      dailyEntries: dailyEntries,
      repertoireRatios: repertoireRatios,
      totalPracticeSeconds: totalSeconds,
      practiceDayCount: practiceDays,
    );
  }

  /// Compute monthly report for `year` / `month` (1-12).
  MonthlyReport calculateMonthly({
    required int year,
    required int month,
    required List<DailyPracticeInput> inputs,
  }) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0); // last day

    final inRange = inputs.where(
      (i) =>
          !_dateOnly(i.date).isBefore(start) && !_dateOnly(i.date).isAfter(end),
    );

    final dailyEntries = _aggregateDaily(start, end, inRange);
    final repertoireRatios = _aggregateRepertoire(inRange);
    final totalSeconds = inRange.fold<int>(0, (a, b) => a + b.practiceSeconds);
    final practiceDays = dailyEntries
        .where((d) => d.practiceSeconds > 0)
        .length;

    return MonthlyReport(
      year: year,
      month: month,
      monthStart: start,
      monthEnd: end,
      dailyEntries: dailyEntries,
      repertoireRatios: repertoireRatios,
      totalPracticeSeconds: totalSeconds,
      practiceDayCount: practiceDays,
    );
  }

  /// Aggregate to one entry per day between `start` and `end` inclusive.
  List<DailyReportEntry> _aggregateDaily(
    DateTime start,
    DateTime end,
    Iterable<DailyPracticeInput> inputs,
  ) {
    final secondsByDay = <DateTime, int>{};
    for (final input in inputs) {
      final key = _dateOnly(input.date);
      secondsByDay[key] = (secondsByDay[key] ?? 0) + input.practiceSeconds;
    }

    final result = <DailyReportEntry>[];
    final totalDays = end.difference(start).inDays + 1;
    for (var i = 0; i < totalDays; i++) {
      final day = start.add(Duration(days: i));
      final key = _dateOnly(day);
      result.add(
        DailyReportEntry(date: day, practiceSeconds: secondsByDay[key] ?? 0),
      );
    }
    return result;
  }

  /// Aggregate repertoire share, sorted by seconds descending.
  List<RepertoireRatio> _aggregateRepertoire(
    Iterable<DailyPracticeInput> inputs,
  ) {
    final byRepertoire = <String, _RepertoireAccumulator>{};
    var total = 0;
    for (final input in inputs) {
      total += input.practiceSeconds;
      byRepertoire
          .putIfAbsent(
            input.repertoireId,
            () => _RepertoireAccumulator(
              repertoireId: input.repertoireId,
              repertoireName: input.repertoireName,
            ),
          )
          .add(input.practiceSeconds);
    }

    final ratios =
        byRepertoire.values
            .map(
              (a) => RepertoireRatio(
                repertoireId: a.repertoireId,
                repertoireName: a.repertoireName,
                practiceSeconds: a.seconds,
                ratio: total == 0 ? 0.0 : a.seconds / total,
              ),
            )
            .toList()
          ..sort((a, b) => b.practiceSeconds.compareTo(a.practiceSeconds));

    return ratios;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _RepertoireAccumulator {
  _RepertoireAccumulator({
    required this.repertoireId,
    required this.repertoireName,
  });

  final String repertoireId;
  final String repertoireName;
  int seconds = 0;

  void add(int s) => seconds += s;
}
