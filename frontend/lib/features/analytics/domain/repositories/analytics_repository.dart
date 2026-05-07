import '../entities/analytics_models.dart';
import '../entities/teacher_stats.dart';

/// Repository interface for teacher analytics data.
abstract class AnalyticsRepository {
  Future<TeacherMonthlyStats> getTeacherMonthlyStats(DateTime month);

  // Student progress
  Future<StudentProgressData> getStudentProgress(
    String studentId, {
    required AnalyticsPeriod period,
  });

  // Revenue analytics
  Future<RevenueAnalyticsData> getRevenueAnalytics({
    required int periodMonths,
  });

  // Retention analytics
  Future<RetentionAnalyticsData> getRetentionAnalytics();

  // Student summary list (monthly summary tab)
  Future<List<StudentSummaryItem>> getStudentSummaryList(DateTime month);
}
