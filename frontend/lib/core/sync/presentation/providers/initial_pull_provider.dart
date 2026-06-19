import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/lessons/data/local/lesson_cache_store.dart';
import '../../../../features/lessons/data/repositories/remote_lesson_repository.dart';
import '../../../network/api_client.dart';
import '../../application/initial_pull_service.dart';
import 'sync_provider.dart';

part 'initial_pull_provider.g.dart';

/// Provider for [InitialPullService].
///
/// keepAlive: true so the service instance is shared across auth state changes.
/// Only instantiated in remote mode (mock mode has no network layer).
@Riverpod(keepAlive: true)
InitialPullService initialPullService(InitialPullServiceRef ref) {
  final apiClient = ref.read(apiClientProvider);
  final connectivity = ref.read(connectivityServiceProvider);
  return InitialPullService(
    remoteLessons: RemoteLessonRepository(apiClient),
    lessonCache: LessonCacheStore(
      box: Hive.box<String>(LessonCacheStore.boxName),
    ),
    connectivity: connectivity,
  );
}
