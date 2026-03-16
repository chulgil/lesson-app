import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/teaching_resource.dart';
import '../../domain/repositories/teaching_resource_repository.dart';

/// Remote implementation of [TeachingResourceRepository] using FastAPI backend.
class RemoteTeachingResourceRepository implements TeachingResourceRepository {
  final ApiClient _apiClient;

  RemoteTeachingResourceRepository(this._apiClient);

  @override
  Future<List<TeachingResource>> getByTeacherId(String teacherId) async {
    final response = await _apiClient.get('/settings/teaching-resources');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => TeachingResource.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<TeachingResource>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Fetch all and filter client-side (backend doesn't have batch-by-IDs endpoint)
    final all = await getByTeacherId('');
    return all.where((r) => ids.contains(r.id)).toList();
  }

  @override
  Future<TeachingResource?> getById(String id) async {
    try {
      final response = await _apiClient.get('/settings/teaching-resources/$id');
      return TeachingResource.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TeachingResource> create(TeachingResource resource) async {
    final response = await _apiClient.post(
      '/settings/teaching-resources',
      data: resource.toJson()..remove('id')..remove('created_at'),
    );
    return TeachingResource.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TeachingResource> update(TeachingResource resource) async {
    final response = await _apiClient.put(
      '/settings/teaching-resources/${resource.id}',
      data: resource.toJson()..remove('id')..remove('created_at'),
    );
    return TeachingResource.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/settings/teaching-resources/$id');
  }
}
