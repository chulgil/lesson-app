import 'practice_goal.dart';

/// Daily practice progress (calculated, not stored)
class DailyPracticeProgress {
  final DateTime date;
  final int practiceTimeSeconds; // Today's practice time (seconds)
  final int completedSectionCount; // Today's completed section count

  DailyPracticeProgress({
    required this.date,
    required this.practiceTimeSeconds,
    required this.completedSectionCount,
  });

  /// Practice time in minutes
  int get practiceTimeMinutes => practiceTimeSeconds ~/ 60;

  /// Format practice time as text
  String get practiceTimeText {
    final mins = practiceTimeMinutes;
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remaining = mins % 60;
      return remaining > 0 ? '$hours시간 $remaining분' : '$hours시간';
    }
    return '$mins분';
  }

  /// Daily time goal progress rate (0.0 ~ 1.0+)
  double timeProgressRate(int? goalMinutes) {
    if (goalMinutes == null || goalMinutes == 0) return 0.0;
    return practiceTimeMinutes / goalMinutes;
  }

  /// Daily section goal progress rate (0.0 ~ 1.0+)
  double sectionProgressRate(int? goalCount) {
    if (goalCount == null || goalCount == 0) return 0.0;
    return completedSectionCount / goalCount;
  }

  /// Whether daily goal is achieved
  bool isDailyGoalAchieved(PracticeGoal goal) {
    final timeAchieved = goal.dailyTimeMinutes == null ||
        practiceTimeMinutes >= goal.dailyTimeMinutes!;
    final sectionAchieved = goal.dailySectionCount == null ||
        completedSectionCount >= goal.dailySectionCount!;
    return timeAchieved && sectionAchieved;
  }

  /// Whether time goal is achieved
  bool isTimeGoalAchieved(int? goalMinutes) {
    if (goalMinutes == null) return true;
    return practiceTimeMinutes >= goalMinutes;
  }

  /// Whether section goal is achieved
  bool isSectionGoalAchieved(int? goalCount) {
    if (goalCount == null) return true;
    return completedSectionCount >= goalCount;
  }

  @override
  String toString() {
    return 'DailyPracticeProgress(date: $date, '
        'practiceTimeSeconds: $practiceTimeSeconds, '
        'completedSectionCount: $completedSectionCount)';
  }
}

/// Weekly practice progress (calculated, not stored)
class WeeklyPracticeProgress {
  final DateTime weekStart; // Week start date (Monday)
  final int totalTimeSeconds; // Total weekly practice time
  final int practiceDayCount; // Days practiced
  final List<DailyPracticeProgress> dailyProgress; // Daily details

  WeeklyPracticeProgress({
    required this.weekStart,
    required this.totalTimeSeconds,
    required this.practiceDayCount,
    required this.dailyProgress,
  });

  /// Total practice time in minutes
  int get totalTimeMinutes => totalTimeSeconds ~/ 60;

  /// Format total time as text
  String get totalTimeText {
    final mins = totalTimeMinutes;
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remaining = mins % 60;
      return remaining > 0 ? '$hours시간 $remaining분' : '$hours시간';
    }
    return '$mins분';
  }

  /// Weekly time goal progress rate
  double timeProgressRate(int? goalMinutes) {
    if (goalMinutes == null || goalMinutes == 0) return 0.0;
    return totalTimeMinutes / goalMinutes;
  }

  /// Weekly day count goal progress rate
  double dayProgressRate(int? goalDays) {
    if (goalDays == null || goalDays == 0) return 0.0;
    return practiceDayCount / goalDays;
  }

  /// Whether weekly goal is achieved
  bool isWeeklyGoalAchieved(PracticeGoal goal) {
    final timeAchieved = goal.weeklyTimeMinutes == null ||
        totalTimeMinutes >= goal.weeklyTimeMinutes!;
    final dayAchieved = goal.weeklyDayCount == null ||
        practiceDayCount >= goal.weeklyDayCount!;
    return timeAchieved && dayAchieved;
  }

  /// Whether time goal is achieved
  bool isTimeGoalAchieved(int? goalMinutes) {
    if (goalMinutes == null) return true;
    return totalTimeMinutes >= goalMinutes;
  }

  /// Whether day count goal is achieved
  bool isDayGoalAchieved(int? goalDays) {
    if (goalDays == null) return true;
    return practiceDayCount >= goalDays;
  }

  @override
  String toString() {
    return 'WeeklyPracticeProgress(weekStart: $weekStart, '
        'totalTimeSeconds: $totalTimeSeconds, '
        'practiceDayCount: $practiceDayCount)';
  }
}
