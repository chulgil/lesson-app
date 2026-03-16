import '../entities/teacher_stats.dart';

/// Repository interface for teacher analytics data.
abstract class AnalyticsRepository {
  Future<TeacherMonthlyStats> getTeacherMonthlyStats(DateTime month);
}
