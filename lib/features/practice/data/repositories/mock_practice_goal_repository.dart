import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_goal_repository.dart';

/// Mock implementation for practice goal repository
class MockPracticeGoalRepository implements PracticeGoalRepository {
  final _uuid = const Uuid();
  final Map<String, PracticeGoal> _goals = {};

  // Mock data for progress simulation
  final Map<String, Map<String, int>> _mockDailyData = {};

  MockPracticeGoalRepository() {
    _initMockData();
  }

  void _initMockData() {
    // Initialize some mock daily practice data
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    _mockDailyData['student_1'] = {
      todayKey: 1200, // 20 minutes in seconds
      yesterdayKey: 2400, // 40 minutes in seconds
    };
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<PracticeGoal?> getActiveGoal(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    for (final goal in _goals.values) {
      if (goal.studentId == studentId && goal.isActive) {
        return goal;
      }
    }
    return null;
  }

  @override
  Future<PracticeGoal> saveGoal(PracticeGoal goal) async {
    await Future.delayed(const Duration(milliseconds: 150));

    // Deactivate existing goals for this student
    for (final existingGoal in _goals.values.toList()) {
      if (existingGoal.studentId == goal.studentId && existingGoal.isActive) {
        _goals[existingGoal.id] = existingGoal.copyWith(isActive: false);
      }
    }

    final savedGoal = goal.id.isEmpty
        ? goal.copyWith(
            id: _uuid.v4(),
            createdAt: DateTime.now(),
          )
        : goal.copyWith(updatedAt: DateTime.now());

    _goals[savedGoal.id] = savedGoal;
    return savedGoal;
  }

  @override
  Future<void> deactivateGoal(String goalId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final goal = _goals[goalId];
    if (goal != null) {
      _goals[goalId] = goal.copyWith(isActive: false);
    }
  }

  @override
  Future<DailyPracticeProgress> getDailyProgress(
    String studentId,
    DateTime date,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final dateKey = _dateKey(date);
    final studentData = _mockDailyData[studentId] ?? {};
    final practiceTime = studentData[dateKey] ?? 0;

    // Mock completed sections based on practice time
    final completedSections = (practiceTime ~/ 600).clamp(0, 5); // 1 section per 10 mins

    return DailyPracticeProgress(
      date: date,
      practiceTimeSeconds: practiceTime,
      completedSectionCount: completedSections,
    );
  }

  @override
  Future<WeeklyPracticeProgress> getWeeklyProgress(
    String studentId,
    DateTime weekStart,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final dailyProgressList = <DailyPracticeProgress>[];
    int totalTime = 0;
    int practiceDays = 0;

    // Calculate for 7 days starting from weekStart
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final progress = await getDailyProgress(studentId, date);
      dailyProgressList.add(progress);

      if (progress.practiceTimeSeconds > 0) {
        totalTime += progress.practiceTimeSeconds;
        practiceDays++;
      }
    }

    return WeeklyPracticeProgress(
      weekStart: weekStart,
      totalTimeSeconds: totalTime,
      practiceDayCount: practiceDays,
      dailyProgress: dailyProgressList,
    );
  }

  /// Add mock practice time for testing
  void addMockPracticeTime(String studentId, DateTime date, int seconds) {
    final dateKey = _dateKey(date);
    _mockDailyData.putIfAbsent(studentId, () => {});
    _mockDailyData[studentId]![dateKey] =
        (_mockDailyData[studentId]![dateKey] ?? 0) + seconds;
  }
}
