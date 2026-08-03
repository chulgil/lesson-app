import '../../../../core/network/api_client.dart';
import '../../domain/entities/growth_report_share.dart';
import '../../domain/repositories/growth_report_share_repository.dart';

/// #1217 — FastAPI 백엔드를 사용하는 [GrowthReportShareRepository] 구현.
class RemoteGrowthReportShareRepository implements GrowthReportShareRepository {
  final ApiClient _apiClient;

  RemoteGrowthReportShareRepository(this._apiClient);

  @override
  Future<GrowthReportShare> createGrowthReportShare(
    String studentId, {
    int expiresInHours = 24,
  }) async {
    final response = await _apiClient.post(
      '/growth-reports/$studentId/share',
      data: {'expires_in_hours': expiresInHours},
    );
    return GrowthReportShare.fromJson(response.data as Map<String, dynamic>);
  }
}
