import '../../../../core/network/api_client.dart';
import '../../domain/entities/cancellation_defaults.dart';
import '../../domain/repositories/cancellation_defaults_repository.dart';

/// Remote implementation of [CancellationDefaultsRepository] using the
/// FastAPI backend (#1178 — GET/PUT /settings/cancellation).
///
/// The server row is what actually drives late-cancel compensation
/// notifications, so edits must land here rather than in local storage.
class RemoteCancellationDefaultsRepository
    implements CancellationDefaultsRepository {
  final ApiClient _apiClient;

  RemoteCancellationDefaultsRepository(this._apiClient);

  @override
  Future<CancellationDefaults> getCancellationDefaults() async {
    final response = await _apiClient.get('/settings/cancellation');
    return CancellationDefaults.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CancellationDefaults> updateCancellationDefaults(
    CancellationDefaults defaults,
  ) async {
    final response = await _apiClient.put(
      '/settings/cancellation',
      data: defaults.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at'),
    );
    return CancellationDefaults.fromJson(response.data as Map<String, dynamic>);
  }
}
