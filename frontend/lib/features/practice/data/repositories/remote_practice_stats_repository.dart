import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/practice_stats_report.dart';
import '../../domain/repositories/practice_stats_repository.dart';

/// Remote implementation of [PracticeStatsRepository] using FastAPI backend.
///
/// Maps to GET /practice/stats?student_id={id}&year={y}&month={m}
/// Backend returns PracticeStatsResponse with:
///   total_practice_minutes, total_practice_days, completed_sections,
///   current_streak, longest_streak, daily_stats: {date: {minutes, sections_completed}}
class RemotePracticeStatsRepository implements PracticeStatsRepository {
  final ApiClient _apiClient;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  RemotePracticeStatsRepository(this._apiClient);

  @override
  Future<PracticeStatsReport> getMonthlyReport(
    String studentId,
    int year,
    int month,
  ) async {
    final response = await _apiClient.get(
      '/practice/stats',
      queryParameters: {
        'student_id': studentId,
        'year': year,
        'month': month,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return _mapToReport(
      data,
      startDate: DateTime(year, month, 1),
      endDate: DateTime(year, month + 1, 0), // last day of month
      type: ReportType.monthly,
    );
  }

  @override
  Future<PracticeStatsReport> getWeeklyReport(
    String studentId,
    DateTime weekStart,
  ) async {
    // Use monthly stats and filter to the relevant week
    final response = await _apiClient.get(
      '/practice/stats',
      queryParameters: {
        'student_id': studentId,
        'year': weekStart.year,
        'month': weekStart.month,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Filter daily_stats to just the week
    final allDailyStats = data['daily_stats'] as Map<String, dynamic>? ?? {};
    final weekDailyStats = <String, dynamic>{};
    for (final entry in allDailyStats.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date != null &&
          !date.isBefore(weekStart) &&
          !date.isAfter(weekEnd)) {
        weekDailyStats[entry.key] = entry.value;
      }
    }

    // Compute week totals from filtered data
    int totalMinutes = 0;
    int practiceDays = 0;
    int completedSections = 0;
    final dailyStatsList = <DailyStats>[];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = _dateFormat.format(date);
      final dayStat = weekDailyStats[dateKey] as Map<String, dynamic>?;

      final minutes = dayStat?['minutes'] as int? ?? 0;
      final sections = dayStat?['sections_completed'] as int? ?? 0;
      final hasPracticed = minutes > 0;

      if (hasPracticed) practiceDays++;
      totalMinutes += minutes;
      completedSections += sections;

      dailyStatsList.add(DailyStats(
        date: date,
        practiceSeconds: minutes * 60,
        completedSections: sections,
        hasPracticed: hasPracticed,
      ));
    }

    return PracticeStatsReport(
      startDate: weekStart,
      endDate: weekEnd,
      type: ReportType.weekly,
      totalPracticeSeconds: totalMinutes * 60,
      practiceDayCount: practiceDays,
      completedSectionCount: completedSections,
      totalSectionCount: completedSections, // No total from backend
      dailyStats: dailyStatsList,
      repertoireStats: [],
      currentStreak: data['current_streak'] as int? ?? 0,
      maxStreak: data['longest_streak'] as int? ?? 0,
    );
  }

  @override
  Future<List<DailyStats>> getDailyStats(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Fetch monthly stats and extract daily data
    final response = await _apiClient.get(
      '/practice/stats',
      queryParameters: {
        'student_id': studentId,
        'year': startDate.year,
        'month': startDate.month,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final allDailyStats = data['daily_stats'] as Map<String, dynamic>? ?? {};

    final result = <DailyStats>[];
    var current = startDate;
    while (!current.isAfter(endDate)) {
      final dateKey = _dateFormat.format(current);
      final dayStat = allDailyStats[dateKey] as Map<String, dynamic>?;

      final minutes = dayStat?['minutes'] as int? ?? 0;
      final sections = dayStat?['sections_completed'] as int? ?? 0;

      result.add(DailyStats(
        date: current,
        practiceSeconds: minutes * 60,
        completedSections: sections,
        hasPracticed: minutes > 0,
      ));
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  /// Map backend PracticeStatsResponse to PracticeStatsReport
  PracticeStatsReport _mapToReport(
    Map<String, dynamic> data, {
    required DateTime startDate,
    required DateTime endDate,
    required ReportType type,
  }) {
    final dailyStatsMap = data['daily_stats'] as Map<String, dynamic>? ?? {};
    final dailyStatsList = <DailyStats>[];

    var current = startDate;
    while (!current.isAfter(endDate)) {
      final dateKey = _dateFormat.format(current);
      final dayStat = dailyStatsMap[dateKey] as Map<String, dynamic>?;

      final minutes = dayStat?['minutes'] as int? ?? 0;
      final sections = dayStat?['sections_completed'] as int? ?? 0;

      dailyStatsList.add(DailyStats(
        date: current,
        practiceSeconds: minutes * 60,
        completedSections: sections,
        hasPracticed: minutes > 0,
      ));
      current = current.add(const Duration(days: 1));
    }

    final totalMinutes = data['total_practice_minutes'] as int? ?? 0;
    final practiceDays = data['total_practice_days'] as int? ?? 0;
    final completedSections = data['completed_sections'] as int? ?? 0;

    return PracticeStatsReport(
      startDate: startDate,
      endDate: endDate,
      type: type,
      totalPracticeSeconds: totalMinutes * 60,
      practiceDayCount: practiceDays,
      completedSectionCount: completedSections,
      totalSectionCount: completedSections,
      dailyStats: dailyStatsList,
      repertoireStats: [],
      currentStreak: data['current_streak'] as int? ?? 0,
      maxStreak: data['longest_streak'] as int? ?? 0,
    );
  }
}
