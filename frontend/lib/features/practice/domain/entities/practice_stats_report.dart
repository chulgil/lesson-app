import '../../../../core/utils/time_format_utils.dart';

/// Report type
enum ReportType { weekly, monthly }

/// Daily statistics
class DailyStats {
  final DateTime date;
  final int practiceSeconds;
  final int completedSections;
  final bool hasPracticed;

  DailyStats({
    required this.date,
    required this.practiceSeconds,
    required this.completedSections,
    required this.hasPracticed,
  });

  /// Practice time in minutes
  int get practiceMinutes => practiceSeconds ~/ 60;

  /// Format practice time as text
  String get practiceTimeText => formatPracticeTime(practiceSeconds);

  /// Day of week label (Korean)
  String get dayLabel {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[date.weekday - 1];
  }

  /// Date text (MM.dd)
  String get dateText {
    return '${date.month}.${date.day.toString().padLeft(2, '0')}';
  }
}

/// Repertoire statistics
class RepertoireStats {
  final String repertoireId;
  final String repertoireName;
  final int practiceSeconds;
  final int completedSections;
  final int totalSections;

  RepertoireStats({
    required this.repertoireId,
    required this.repertoireName,
    required this.practiceSeconds,
    required this.completedSections,
    required this.totalSections,
  });

  /// Practice time in minutes
  int get practiceMinutes => practiceSeconds ~/ 60;

  /// Format practice time as text
  String get practiceTimeText => formatPracticeTime(practiceSeconds);

  /// Completion rate (0.0 ~ 1.0)
  double get completionRate =>
      totalSections == 0 ? 0.0 : completedSections / totalSections;

  /// Completion percentage
  int get completionPercent => (completionRate * 100).round();
}

/// Weekly statistics for trend chart
class WeeklyStats {
  final DateTime weekStart;
  final int weekNumber;
  final int practiceSeconds;
  final int practiceDays;

  WeeklyStats({
    required this.weekStart,
    required this.weekNumber,
    required this.practiceSeconds,
    required this.practiceDays,
  });

  /// Practice time in minutes
  int get practiceMinutes => practiceSeconds ~/ 60;

  /// Week label (예: "1주차")
  String get weekLabel => '$weekNumber주차';
}

/// Practice statistics report (calculated, not stored)
class PracticeStatsReport {
  final DateTime startDate;
  final DateTime endDate;
  final ReportType type;

  // Summary statistics
  final int totalPracticeSeconds;
  final int practiceDayCount;
  final int completedSectionCount;
  final int totalSectionCount;

  // Daily details
  final List<DailyStats> dailyStats;

  // Repertoire details
  final List<RepertoireStats> repertoireStats;

  // Weekly trend (for monthly report)
  final List<WeeklyStats> weeklyStats;

  // Streak info
  final int currentStreak;
  final int maxStreak;

  PracticeStatsReport({
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.totalPracticeSeconds,
    required this.practiceDayCount,
    required this.completedSectionCount,
    required this.totalSectionCount,
    required this.dailyStats,
    required this.repertoireStats,
    this.weeklyStats = const [],
    this.currentStreak = 0,
    this.maxStreak = 0,
  });

  /// Total practice time in minutes
  int get totalMinutes => totalPracticeSeconds ~/ 60;

  /// Format total time as text
  String get totalTimeText => formatPracticeTime(totalPracticeSeconds);

  /// Completion rate (0.0 ~ 1.0)
  double get completionRate {
    if (totalSectionCount == 0) return 0.0;
    return completedSectionCount / totalSectionCount;
  }

  /// Completion percentage
  int get completionPercent => (completionRate * 100).round();

  /// Average daily practice time in minutes
  int get avgDailyMinutes {
    if (practiceDayCount == 0) return 0;
    return totalMinutes ~/ practiceDayCount;
  }

  /// Format average daily time as text
  String get avgDailyTimeText => formatMinutesToText(avgDailyMinutes);

  /// Max daily practice minutes (for chart scaling)
  int get maxDailyMinutes {
    if (dailyStats.isEmpty) return 60;
    return dailyStats.map((s) => s.practiceMinutes).reduce((a, b) => a > b ? a : b);
  }

  /// Period text (예: "2026년 1월 1주차" or "2026년 1월")
  String get periodText {
    if (type == ReportType.weekly) {
      final weekNum = getWeekOfMonth(startDate);
      return '${startDate.year}년 ${startDate.month}월 $weekNum주차';
    }
    return '${startDate.year}년 ${startDate.month}월';
  }
}
