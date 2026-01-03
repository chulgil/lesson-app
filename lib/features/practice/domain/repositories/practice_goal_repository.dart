import '../entities/entities.dart';

/// Repository interface for practice goals
abstract class PracticeGoalRepository {
  /// Get active goal for a student
  Future<PracticeGoal?> getActiveGoal(String studentId);

  /// Save (create or update) a goal
  Future<PracticeGoal> saveGoal(PracticeGoal goal);

  /// Deactivate a goal
  Future<void> deactivateGoal(String goalId);

  /// Get daily progress for a student on a specific date
  Future<DailyPracticeProgress> getDailyProgress(
    String studentId,
    DateTime date,
  );

  /// Get weekly progress for a student starting from a specific week
  Future<WeeklyPracticeProgress> getWeeklyProgress(
    String studentId,
    DateTime weekStart,
  );
}
