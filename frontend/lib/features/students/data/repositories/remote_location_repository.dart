import '../../../../core/network/api_client.dart';
import '../../domain/entities/lesson_location.dart';
import '../../domain/repositories/location_repository.dart';

/// Remote implementation of [LocationRepository] using FastAPI backend.
class RemoteLocationRepository implements LocationRepository {
  final ApiClient _apiClient;

  RemoteLocationRepository(this._apiClient);

  @override
  Future<List<LessonLocation>> getByClassId(String classId) async {
    final response = await _apiClient.get(
      '/locations',
      queryParameters: {'class_id': classId},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => LessonLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LessonLocation>> getByOwnerId(String ownerId) async {
    final response = await _apiClient.get(
      '/locations',
      queryParameters: {'owner_id': ownerId},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => LessonLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LessonLocation?> getById(String id) async {
    final response = await _apiClient.get('/locations/$id');
    return LessonLocation.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonLocation> create(LessonLocation location) async {
    final response = await _apiClient.post(
      '/locations',
      data: location.toJson(),
    );
    return LessonLocation.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonLocation> update(LessonLocation location) async {
    final response = await _apiClient.put(
      '/locations/${location.id}',
      data: location.toJson(),
    );
    return LessonLocation.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> setDefault(String id, String classId) async {
    await _apiClient.patch(
      '/locations/$id/default',
      queryParameters: {'class_id': classId},
    );
  }

  @override
  Future<void> deactivate(String id) async {
    await _apiClient.patch('/locations/$id/deactivate');
  }

  @override
  Future<void> reactivate(String id) async {
    await _apiClient.patch('/locations/$id/reactivate');
  }

  @override
  Stream<List<LessonLocation>> watchByClassId(String classId) async* {
    yield await getByClassId(classId);
  }

  @override
  Stream<List<LessonLocation>> watchByOwnerId(String ownerId) async* {
    yield await getByOwnerId(ownerId);
  }
}
