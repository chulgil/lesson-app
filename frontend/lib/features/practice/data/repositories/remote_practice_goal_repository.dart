import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/practice_goal.dart';
import '../../domain/entities/practice_progress.dart';
import '../../domain/repositories/practice_goal_repository.dart';

/// Remote implementation of [PracticeGoalRepository] using FastAPI backend.
///
/// Maps to:
/// - GET /practice/goals?student_id={id} → getActiveGoal
/// - PUT /practice/goals → saveGoal
/// - GET /practice-logs/date/{date}?student_id={id} → getDailyProgress
/// - GET /practice-logs/weekly?student_id={id}&week_start={date} → getWeeklyProgress
class RemotePracticeGoalRepository implements PracticeGoalRepository {
  final ApiClient _apiClient;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  RemotePracticeGoalRepository(this._apiClient);

  @override
  Future<PracticeGoal?> getActiveGoal(String studentId) async {
    try {
      final response = await _apiClient.get(
        '/practice/goals',
        queryParameters: {'student_id': studentId},
      );
      final data = response.data as Map<String, dynamic>;
      return _goalFromJson(data, studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PracticeGoal> saveGoal(PracticeGoal goal) async {
    final response = await _apiClient.put(
      '/practice/goals',
      data: {
        'student_id': goal.studentId,
        'daily_time_minutes': goal.dailyTimeMinutes,
        'daily_section_count': goal.dailySectionCount,
        'weekly_time_minutes': goal.weeklyTimeMinutes,
        'weekly_day_count': goal.weeklyDayCount,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return _goalFromJson(data, goal.studentId);
  }

  @override
  Future<void> deactivateGoal(String goalId) async {
    // Backend doesn't have a deactivate endpoint — save with all nulls
    await _apiClient.put(
      '/practice/goals',
      data: {
        'student_id': goalId, // goalId is actually used as studentId in this context
        'daily_time_minutes': null,
        'daily_section_count': null,
        'weekly_time_minutes': null,
        'weekly_day_count': null,
      },
    );
  }

  @override
  Future<DailyPracticeProgress> getDailyProgress(
    String studentId,
    DateTime date,
  ) async {
    try {
      final dateStr = _dateFormat.format(date);
      final response = await _apiClient.get(
        '/practice-logs/date/$dateStr',
        queryParameters: {'student_id': studentId},
      );
      final data = response.data;
      if (data == null) {
        return DailyPracticeProgress(
          date: date,
          practiceTimeSeconds: 0,
          completedSectionCount: 0,
        );
      }
      final log = data as Map<String, dynamic>;
      final totalMinutes = log['total_minutes'] as int? ?? 0;
      final tasks = log['tasks'] as List<dynamic>? ?? [];
      final completedTasks = tasks.where((t) =>
        (t as Map<String, dynamic>)['is_completed'] == true
      ).length;
      return DailyPracticeProgress(
        date: date,
        practiceTimeSeconds: totalMinutes * 60,
        completedSectionCount: completedTasks,
      );
    } catch (_) {
      return DailyPracticeProgress(
        date: date,
        practiceTimeSeconds: 0,
        completedSectionCount: 0,
      );
    }
  }

  @override
  Future<WeeklyPracticeProgress> getWeeklyProgress(
    String studentId,
    DateTime weekStart,
  ) async {
    try {
      final weekStartStr = _dateFormat.format(weekStart);
      final response = await _apiClient.get(
        '/practice-logs/weekly',
        queryParameters: {
          'student_id': studentId,
          'week_start': weekStartStr,
        },
      );
      final days = (response.data as List<dynamic>).cast<bool>();
      final practiceDayCount = days.where((d) => d).length;

      // Fetch daily details for each day
      final dailyProgress = <DailyPracticeProgress>[];
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        if (days.length > i && days[i]) {
          final dp = await getDailyProgress(studentId, date);
          dailyProgress.add(dp);
        } else {
          dailyProgress.add(DailyPracticeProgress(
            date: date,
            practiceTimeSeconds: 0,
            completedSectionCount: 0,
          ));
        }
      }

      final totalTimeSeconds = dailyProgress.fold<int>(
        0,
        (sum, dp) => sum + dp.practiceTimeSeconds,
      );

      return WeeklyPracticeProgress(
        weekStart: weekStart,
        totalTimeSeconds: totalTimeSeconds,
        practiceDayCount: practiceDayCount,
        dailyProgress: dailyProgress,
      );
    } catch (_) {
      return WeeklyPracticeProgress(
        weekStart: weekStart,
        totalTimeSeconds: 0,
        practiceDayCount: 0,
        dailyProgress: List.generate(
          7,
          (i) => DailyPracticeProgress(
            date: weekStart.add(Duration(days: i)),
            practiceTimeSeconds: 0,
            completedSectionCount: 0,
          ),
        ),
      );
    }
  }

  /// Map backend PracticeGoalResponse to PracticeGoal entity
  PracticeGoal _goalFromJson(Map<String, dynamic> json, String studentId) {
    return PracticeGoal(
      id: 'goal_$studentId',
      studentId: json['student_id'] as String? ?? studentId,
      dailyTimeMinutes: json['daily_time_minutes'] as int?,
      dailySectionCount: json['daily_section_count'] as int?,
      weeklyTimeMinutes: json['weekly_time_minutes'] as int?,
      weeklyDayCount: json['weekly_day_count'] as int?,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }
}
