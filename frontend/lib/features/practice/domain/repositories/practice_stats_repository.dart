import '../entities/entities.dart';

/// Repository interface for practice statistics
abstract class PracticeStatsRepository {
  /// Get weekly report
  Future<PracticeStatsReport> getWeeklyReport(
    String studentId,
    DateTime weekStart,
  );

  /// Get monthly report
  Future<PracticeStatsReport> getMonthlyReport(
    String studentId,
    int year,
    int month,
  );

  /// Get daily stats for a specific period
  Future<List<DailyStats>> getDailyStats(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  );
}
