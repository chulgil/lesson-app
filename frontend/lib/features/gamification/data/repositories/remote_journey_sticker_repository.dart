import '../../../../core/network/api_client.dart';
import '../../domain/entities/journey_sticker.dart';
import '../../domain/repositories/journey_sticker_repository.dart';

/// Remote implementation backed by the computed FastAPI catalog endpoint.
class RemoteJourneyStickerRepository implements JourneyStickerRepository {
  final ApiClient _apiClient;

  RemoteJourneyStickerRepository(this._apiClient);

  @override
  Future<JourneyStickerCatalog> getCatalog(String studentId) async {
    final response = await _apiClient.get(
      '/gamification/$studentId/journey-stickers',
    );
    return JourneyStickerCatalog.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
