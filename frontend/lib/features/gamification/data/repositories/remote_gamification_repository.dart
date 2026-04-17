import '../../../../core/network/api_client.dart';
import '../../domain/entities/gamification.dart';
import '../../domain/repositories/gamification_repository.dart';

/// Remote implementation of [GamificationRepository] using FastAPI backend.
class RemoteGamificationRepository implements GamificationRepository {
  final ApiClient _apiClient;

  RemoteGamificationRepository(this._apiClient);

  @override
  Future<StudentGamification> getStudentGamification(String studentId) async {
    final response = await _apiClient.get('/gamification/$studentId');
    return StudentGamification.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> awardBadges(String studentId, List<PracticeBadge> badges) async {
    if (badges.isEmpty) return;
    await _apiClient.post(
      '/gamification/$studentId/badges',
      data: {'badges': badges.map((b) => b.toJson()).toList()},
    );
  }
}
