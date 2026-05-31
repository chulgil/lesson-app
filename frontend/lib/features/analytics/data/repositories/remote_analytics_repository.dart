import '../../../../core/network/api_client.dart';
import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/teacher_stats.dart';
import '../../domain/repositories/analytics_repository.dart';

/// Remote implementation of [AnalyticsRepository] using FastAPI backend.
class RemoteAnalyticsRepository implements AnalyticsRepository {
  final ApiClient _apiClient;

  RemoteAnalyticsRepository(this._apiClient);

  @override
  Future<TeacherMonthlyStats> getTeacherMonthlyStats(DateTime month) async {
    final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final response = await _apiClient.get(
      '/analytics/monthly-stats',
      queryParameters: {'month': monthStr},
    );
    return TeacherMonthlyStats.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<StudentProgressData> getStudentProgress(
    String studentId, {
    required AnalyticsPeriod period,
  }) async {
    return StudentProgressData(
      studentId: studentId,
      studentName: '학생',
      attendanceRate: 0,
      attendedLessons: 0,
      totalLessons: 0,
      practiceAchievementRate: 0,
      totalPracticeMinutes: 0,
      practiceStreakDays: 0,
      weeklyPractice: const [],
      attendanceCalendar: const [],
      repertoire: const [],
      recordings: const [],
      feedbackHighlights: const [],
    );
  }

  @override
  Future<RevenueAnalyticsData> getRevenueAnalytics({
    required int periodMonths,
  }) async {
    final stats = await getTeacherMonthlyStats(DateTime.now());
    return RevenueAnalyticsData(
      currentMonthRevenue: stats.totalRevenue,
      revenueChangePercent: stats.revenueChangePercent,
      pendingAmount: 0,
      pendingCount: 0,
      expectedMonthlyRevenue: stats.totalRevenue,
      expiringSubscriptionCount: 0,
      trend:
          stats.lessonTrend
              .take(periodMonths)
              .map(
                (trend) => MonthlyRevenueTrend(
                  month: trend.month,
                  confirmedRevenue: trend.revenue,
                  pendingRevenue: 0,
                ),
              )
              .toList(),
      breakdown: const [],
    );
  }

  @override
  Future<RetentionAnalyticsData> getRetentionAnalytics() async {
    return const RetentionAnalyticsData(
      renewalRate: 0,
      avgSubscriptionMonths: 0,
      atRiskStudents: [],
      renewalTrend: [],
      tenureDistribution: [],
    );
  }

  @override
  Future<List<StudentSummaryItem>> getStudentSummaryList(DateTime month) async {
    return const [];
  }
}
