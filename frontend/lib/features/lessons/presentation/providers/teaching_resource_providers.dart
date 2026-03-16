import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/mock_teaching_resource_repository.dart';
import '../../data/repositories/remote_teaching_resource_repository.dart';
import '../../domain/entities/teaching_resource.dart';
import '../../domain/repositories/teaching_resource_repository.dart';

/// Repository provider
final teachingResourceRepositoryProvider =
    Provider<TeachingResourceRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockTeachingResourceRepository();
  }
  return RemoteTeachingResourceRepository(ref.read(apiClientProvider));
});

/// All resources for current teacher
final teacherResourcesProvider =
    FutureProvider.family<List<TeachingResource>, String>(
        (ref, teacherId) async {
  final repository = ref.watch(teachingResourceRepositoryProvider);
  return repository.getByTeacherId(teacherId);
});

/// Resources by IDs (for displaying attached resources on practice items)
final resourcesByIdsProvider =
    FutureProvider.family<List<TeachingResource>, List<String>>(
        (ref, ids) async {
  if (ids.isEmpty) return [];
  final repository = ref.watch(teachingResourceRepositoryProvider);
  return repository.getByIds(ids);
});

/// Notifier for CRUD operations on teaching resources
class TeachingResourceNotifier extends AsyncNotifier<List<TeachingResource>> {
  TeachingResourceRepository get _repository =>
      ref.read(teachingResourceRepositoryProvider);

  // Default teacher ID - will be replaced with auth provider
  String get _teacherId => 'teacher_1';

  @override
  Future<List<TeachingResource>> build() async {
    return _repository.getByTeacherId(_teacherId);
  }

  /// Create a new YouTube resource
  Future<TeachingResource> addYoutubeResource({
    required String title,
    required String youtubeUrl,
    String? youtubeVideoId,
    String? youtubeThumbnail,
    int? startSeconds,
    int? endSeconds,
    String? description,
    String? instrument,
    List<String> tags = const [],
  }) async {
    final resource = TeachingResource(
      id: '',
      teacherId: _teacherId,
      type: TeachingResourceType.youtube,
      title: title,
      description: description,
      youtubeUrl: youtubeUrl,
      youtubeVideoId: youtubeVideoId,
      youtubeThumbnail: youtubeThumbnail,
      youtubeStartSeconds: startSeconds,
      youtubeEndSeconds: endSeconds,
      instrument: instrument,
      tags: tags,
      createdAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    try {
      final created = await _repository.create(resource);
      state = await AsyncValue.guard(() => _repository.getByTeacherId(_teacherId));
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete a resource
  Future<void> deleteResource(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      state = await AsyncValue.guard(() => _repository.getByTeacherId(_teacherId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final teachingResourceNotifierProvider =
    AsyncNotifierProvider<TeachingResourceNotifier, List<TeachingResource>>(
  TeachingResourceNotifier.new,
);
