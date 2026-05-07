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
    final monthStr =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final response = await _apiClient.get(
      '/analytics/monthly-stats',
      queryParameters: {'month': monthStr},
    );
    return TeacherMonthlyStats.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentProgressData> getStudentProgress(
    String studentId, {
    required AnalyticsPeriod period,
  }) async {
    // TODO(Phase G): implement remote API call
    throw UnimplementedError('getStudentProgress not yet implemented remotely');
  }

  @override
  Future<RevenueAnalyticsData> getRevenueAnalytics({
    required int periodMonths,
  }) async {
    // TODO(Phase G): implement remote API call
    throw UnimplementedError('getRevenueAnalytics not yet implemented remotely');
  }

  @override
  Future<RetentionAnalyticsData> getRetentionAnalytics() async {
    // TODO(Phase G): implement remote API call
    throw UnimplementedError('getRetentionAnalytics not yet implemented remotely');
  }

  @override
  Future<List<StudentSummaryItem>> getStudentSummaryList(DateTime month) async {
    // TODO(Phase G): implement remote API call
    throw UnimplementedError('getStudentSummaryList not yet implemented remotely');
  }
}
