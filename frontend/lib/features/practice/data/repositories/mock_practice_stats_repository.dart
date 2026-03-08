import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_stats_repository.dart';

/// Mock implementation for practice stats repository
class MockPracticeStatsRepository implements PracticeStatsRepository {
  final bool _empty;

  MockPracticeStatsRepository({bool empty = false}) : _empty = empty;

  /// Student-specific streak data (varies per student)
  Map<String, (int current, int max)> get _streakByStudent => {
    'student_1': (5, 12),
    'student_2': (6, 14),
    'student_3': (3, 8),
    'student_4': (1, 1),  // trial student
    'student_5': (4, 9),
    'student_11': (7, 21), // model student
    'student_12': (2, 5),
  };

  (int current, int max) _getStreak(String studentId) {
    return _streakByStudent[studentId] ?? (0, 0);
  }

  @override
  Future<PracticeStatsReport> getWeeklyReport(
    String studentId,
    DateTime weekStart,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_empty) {
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      return PracticeStatsReport(
        startDate: start,
        endDate: start.add(const Duration(days: 6)),
        type: ReportType.weekly,
        totalPracticeSeconds: 0,
        practiceDayCount: 0,
        completedSectionCount: 0,
        totalSectionCount: 0,
        dailyStats: [],
        repertoireStats: [],
        currentStreak: 0,
        maxStreak: 0,
      );
    }

    final normalizedStart = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final endDate = normalizedStart.add(const Duration(days: 6));

    // Generate mock daily stats
    final dailyStats = <DailyStats>[];
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = normalizedStart.add(Duration(days: i));
      final isFuture = date.isAfter(now);

      // Generate mock data (varying practice time)
      final practiceSeconds =
          isFuture
              ? 0
              : [1800, 2400, 1200, 0, 3000, 2100, 1500][i]; // Mock values

      dailyStats.add(
        DailyStats(
          date: date,
          practiceSeconds: practiceSeconds,
          completedSections: practiceSeconds > 0 ? (practiceSeconds ~/ 600) : 0,
          hasPracticed: practiceSeconds > 0,
        ),
      );
    }

    // Calculate totals
    final totalSeconds = dailyStats.fold<int>(
      0,
      (sum, s) => sum + s.practiceSeconds,
    );
    final practiceDays = dailyStats.where((s) => s.hasPracticed).length;
    final completedSections = dailyStats.fold<int>(
      0,
      (sum, s) => sum + s.completedSections,
    );

    // Mock repertoire stats
    final repertoireStats = [
      RepertoireStats(
        repertoireId: 'rep_1',
        repertoireName: '바흐 파르티타 2번',
        practiceSeconds: (totalSeconds * 0.5).round(),
        completedSections: 4,
        totalSections: 5,
      ),
      RepertoireStats(
        repertoireId: 'rep_2',
        repertoireName: '모차르트 소나타 K.545',
        practiceSeconds: (totalSeconds * 0.3).round(),
        completedSections: 2,
        totalSections: 4,
      ),
      RepertoireStats(
        repertoireId: 'rep_3',
        repertoireName: '쇼팽 왈츠 Op.64',
        practiceSeconds: (totalSeconds * 0.2).round(),
        completedSections: 1,
        totalSections: 3,
      ),
    ];

    final streak = _getStreak(studentId);
    return PracticeStatsReport(
      startDate: normalizedStart,
      endDate: endDate,
      type: ReportType.weekly,
      totalPracticeSeconds: totalSeconds,
      practiceDayCount: practiceDays,
      completedSectionCount: completedSections,
      totalSectionCount: 12,
      dailyStats: dailyStats,
      repertoireStats: repertoireStats,
      currentStreak: streak.$1,
      maxStreak: streak.$2,
    );
  }

  @override
  Future<PracticeStatsReport> getMonthlyReport(
    String studentId,
    int year,
    int month,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (_empty) {
      return PracticeStatsReport(
        startDate: DateTime(year, month, 1),
        endDate: DateTime(year, month + 1, 0),
        type: ReportType.monthly,
        totalPracticeSeconds: 0,
        practiceDayCount: 0,
        completedSectionCount: 0,
        totalSectionCount: 0,
        dailyStats: [],
        repertoireStats: [],
        currentStreak: 0,
        maxStreak: 0,
      );
    }

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month
    final daysInMonth = endDate.day;

    // Generate mock daily stats for the month
    final dailyStats = <DailyStats>[];
    final now = DateTime.now();

    for (int i = 0; i < daysInMonth; i++) {
      final date = startDate.add(Duration(days: i));
      final isFuture = date.isAfter(now);
      final isWeekend = date.weekday == 6 || date.weekday == 7;

      // Generate mock data (less practice on weekends, random variation)
      int practiceSeconds = 0;
      if (!isFuture) {
        final baseTime = isWeekend ? 1200 : 2400;
        final variation = (i * 17) % 1200 - 600; // Pseudo-random variation
        practiceSeconds = (baseTime + variation).clamp(0, 4200);
        // Some days have no practice
        if (i % 7 == 3) practiceSeconds = 0;
      }

      dailyStats.add(
        DailyStats(
          date: date,
          practiceSeconds: practiceSeconds,
          completedSections: practiceSeconds > 0 ? (practiceSeconds ~/ 600) : 0,
          hasPracticed: practiceSeconds > 0,
        ),
      );
    }

    // Calculate weekly stats for trend
    final weeklyStats = <WeeklyStats>[];
    int weekNum = 1;
    int weekStartIndex = 0;

    while (weekStartIndex < daysInMonth) {
      final weekEndIndex = (weekStartIndex + 6).clamp(0, daysInMonth - 1);
      final weekDays = dailyStats.sublist(weekStartIndex, weekEndIndex + 1);

      final weekSeconds = weekDays.fold<int>(
        0,
        (sum, s) => sum + s.practiceSeconds,
      );
      final weekPracticeDays = weekDays.where((s) => s.hasPracticed).length;

      weeklyStats.add(
        WeeklyStats(
          weekStart: dailyStats[weekStartIndex].date,
          weekNumber: weekNum,
          practiceSeconds: weekSeconds,
          practiceDays: weekPracticeDays,
        ),
      );

      weekNum++;
      weekStartIndex = weekEndIndex + 1;
    }

    // Calculate totals
    final totalSeconds = dailyStats.fold<int>(
      0,
      (sum, s) => sum + s.practiceSeconds,
    );
    final practiceDays = dailyStats.where((s) => s.hasPracticed).length;
    final completedSections = dailyStats.fold<int>(
      0,
      (sum, s) => sum + s.completedSections,
    );

    // Mock repertoire stats
    final repertoireStats = [
      RepertoireStats(
        repertoireId: 'rep_1',
        repertoireName: '바흐 파르티타 2번',
        practiceSeconds: (totalSeconds * 0.4).round(),
        completedSections: 8,
        totalSections: 10,
      ),
      RepertoireStats(
        repertoireId: 'rep_2',
        repertoireName: '모차르트 소나타 K.545',
        practiceSeconds: (totalSeconds * 0.35).round(),
        completedSections: 6,
        totalSections: 8,
      ),
      RepertoireStats(
        repertoireId: 'rep_3',
        repertoireName: '쇼팽 왈츠 Op.64',
        practiceSeconds: (totalSeconds * 0.25).round(),
        completedSections: 3,
        totalSections: 6,
      ),
    ];

    final streak = _getStreak(studentId);
    return PracticeStatsReport(
      startDate: startDate,
      endDate: endDate,
      type: ReportType.monthly,
      totalPracticeSeconds: totalSeconds,
      practiceDayCount: practiceDays,
      completedSectionCount: completedSections,
      totalSectionCount: 24,
      dailyStats: dailyStats,
      repertoireStats: repertoireStats,
      weeklyStats: weeklyStats,
      currentStreak: streak.$1,
      maxStreak: streak.$2 > streak.$1 ? streak.$2 + 3 : streak.$2, // monthly max slightly higher
    );
  }

  @override
  Future<List<DailyStats>> getDailyStats(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_empty) return [];

    final stats = <DailyStats>[];
    var current = startDate;

    while (!current.isAfter(endDate)) {
      final dayIndex = current.difference(startDate).inDays;
      final practiceSeconds =
          [1800, 2400, 0, 1500, 3000, 1200, 0][dayIndex % 7];

      stats.add(
        DailyStats(
          date: current,
          practiceSeconds: practiceSeconds,
          completedSections: practiceSeconds > 0 ? (practiceSeconds ~/ 600) : 0,
          hasPracticed: practiceSeconds > 0,
        ),
      );

      current = current.add(const Duration(days: 1));
    }

    return stats;
  }
}
