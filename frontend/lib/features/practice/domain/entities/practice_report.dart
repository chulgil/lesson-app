// Practice report domain entities (§5.2 주간/월간 리포트)
//
// Pure value objects. No Flutter / Riverpod / l10n dependency.
// Calculator produces these from raw stats sources.

/// Daily summary for a single day in the report period.
class DailyReportEntry {
  final DateTime date;
  final int practiceSeconds;

  const DailyReportEntry({required this.date, required this.practiceSeconds});

  int get practiceMinutes => practiceSeconds ~/ 60;
  bool get hasPracticed => practiceSeconds > 0;
}

/// Repertoire share of a report period.
class RepertoireRatio {
  final String repertoireId;
  final String repertoireName;
  final int practiceSeconds;
  final double ratio;

  const RepertoireRatio({
    required this.repertoireId,
    required this.repertoireName,
    required this.practiceSeconds,
    required this.ratio,
  });

  int get practiceMinutes => practiceSeconds ~/ 60;
  int get ratioPercent => (ratio * 100).round();
}

/// Weekly report (7 day window, Monday start).
class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<DailyReportEntry> dailyEntries;
  final List<RepertoireRatio> repertoireRatios;
  final int totalPracticeSeconds;
  final int practiceDayCount;

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.dailyEntries,
    required this.repertoireRatios,
    required this.totalPracticeSeconds,
    required this.practiceDayCount,
  });

  int get totalMinutes => totalPracticeSeconds ~/ 60;

  int get averageDailyMinutes {
    if (practiceDayCount == 0) return 0;
    return totalMinutes ~/ practiceDayCount;
  }

  bool get isEmpty => totalPracticeSeconds == 0;
}

/// Monthly report (1 ~ last day of month).
class MonthlyReport {
  final int year;
  final int month;
  final DateTime monthStart;
  final DateTime monthEnd;
  final List<DailyReportEntry> dailyEntries;
  final List<RepertoireRatio> repertoireRatios;
  final int totalPracticeSeconds;
  final int practiceDayCount;

  const MonthlyReport({
    required this.year,
    required this.month,
    required this.monthStart,
    required this.monthEnd,
    required this.dailyEntries,
    required this.repertoireRatios,
    required this.totalPracticeSeconds,
    required this.practiceDayCount,
  });

  int get totalMinutes => totalPracticeSeconds ~/ 60;

  int get averageDailyMinutes {
    if (practiceDayCount == 0) return 0;
    return totalMinutes ~/ practiceDayCount;
  }

  bool get isEmpty => totalPracticeSeconds == 0;
}
