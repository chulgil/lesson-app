import '../../../../core/network/api_client.dart';
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
}
