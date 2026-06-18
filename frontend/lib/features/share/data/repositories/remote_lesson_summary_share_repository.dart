import '../../../../core/network/api_client.dart';
import '../../domain/entities/lesson_summary_share.dart';
import '../../domain/repositories/lesson_summary_share_repository.dart';

/// #808 — FastAPI 백엔드를 사용하는 [LessonSummaryShareRepository] 구현.
class RemoteLessonSummaryShareRepository
    implements LessonSummaryShareRepository {
  final ApiClient _apiClient;

  RemoteLessonSummaryShareRepository(this._apiClient);

  @override
  Future<LessonSummaryShare> createLessonSummaryShare(
    String lessonId, {
    int expiresInHours = 24,
  }) async {
    final response = await _apiClient.post(
      '/lesson-summaries/$lessonId/share',
      data: {'expires_in_hours': expiresInHours},
    );
    return LessonSummaryShare.fromJson(response.data as Map<String, dynamic>);
  }
}
