import '../entities/entities.dart';

/// Repository interface for managing practice data
abstract class PracticeRepository {
  // Practice logs
  Future<List<PracticeLog>> getPracticeLogs(String studentId);
  Future<PracticeLog?> getPracticeLog(String id);
  Future<PracticeLog?> getPracticeLogByDate(String studentId, DateTime date);
  Future<Map<DateTime, PracticeLog>> getPracticeLogsByMonth(
      String studentId, int year, int month);
  Future<PracticeLog> createPracticeLog(PracticeLog log);
  Future<PracticeLog> updatePracticeLog(PracticeLog log);
  Future<void> deletePracticeLog(String id);

  // Tasks
  Future<PracticeTask> toggleTask(String logId, String taskId);

  // Statistics
  Future<PracticeStats> getPracticeStats(String studentId, int year, int month);
  Future<List<bool>> getWeeklyPractice(String studentId);

  // Streak
  Future<PracticeStreak> getStreak(String studentId);
  Future<PracticeStreak> updateStreak(String studentId);
  Future<PracticeStreak> recordPractice(String studentId);
}
