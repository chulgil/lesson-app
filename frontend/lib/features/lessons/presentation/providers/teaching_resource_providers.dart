import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../auth/auth_facade.dart';
import '../../data/repositories/mock_teaching_resource_repository.dart';
import '../../data/repositories/remote_teaching_resource_repository.dart';
import '../../domain/entities/teaching_resource.dart';
import '../../domain/repositories/teaching_resource_repository.dart';

part 'teaching_resource_providers.g.dart';

/// Repository provider
@Riverpod(keepAlive: true)
TeachingResourceRepository teachingResourceRepository(
  TeachingResourceRepositoryRef ref,
) => createRepository<TeachingResourceRepository>(
  ref: ref,
  mock: () => MockTeachingResourceRepository(),
  remote: (api) => RemoteTeachingResourceRepository(api),
);

/// All resources for current teacher
@Riverpod(keepAlive: true)
Future<List<TeachingResource>> teacherResources(
  TeacherResourcesRef ref,
  String teacherId,
) async {
  final repository = ref.watch(teachingResourceRepositoryProvider);
  return repository.getByTeacherId(teacherId);
}

/// Resources by IDs (for displaying attached resources on practice items)
@Riverpod(keepAlive: true)
Future<List<TeachingResource>> resourcesByIds(
  ResourcesByIdsRef ref,
  List<String> ids,
) async {
  if (ids.isEmpty) return [];
  final repository = ref.watch(teachingResourceRepositoryProvider);
  return repository.getByIds(ids);
}

/// Notifier for CRUD operations on teaching resources
@Riverpod(keepAlive: true)
class TeachingResourceNotifier extends _$TeachingResourceNotifier {
  TeachingResourceRepository get _repository =>
      ref.read(teachingResourceRepositoryProvider);

  // Owner scope for reads/writes — the signed-in teacher, not a fixed id.
  String get _teacherId => ref.read(currentUserIdProvider);

  @override
  Future<List<TeachingResource>> build() async {
    // watch (not read) so the list reloads when the signed-in user changes.
    final teacherId = ref.watch(currentUserIdProvider);
    return _repository.getByTeacherId(teacherId);
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
      state = await AsyncValue.guard(
        () => _repository.getByTeacherId(_teacherId),
      );
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Create a resource of any type (recording, external link, etc.)
  Future<TeachingResource> createResource({
    required TeachingResourceType type,
    required String title,
    String? description,
    String? audioUrl,
    int? audioDurationSeconds,
    String? externalUrl,
    String? instrument,
    List<String> tags = const [],
  }) async {
    final resource = TeachingResource(
      id: '',
      teacherId: _teacherId,
      type: type,
      title: title,
      description: description,
      audioUrl: audioUrl,
      audioDurationSeconds: audioDurationSeconds,
      externalUrl: externalUrl,
      instrument: instrument,
      tags: tags,
      createdAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    try {
      final created = await _repository.create(resource);
      state = await AsyncValue.guard(
        () => _repository.getByTeacherId(_teacherId),
      );
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
      state = await AsyncValue.guard(
        () => _repository.getByTeacherId(_teacherId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
