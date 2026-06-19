import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/local/lesson_cache_store.dart';
import '../../data/repositories/mock_lesson_repository.dart';
import '../../data/repositories/remote_lesson_repository.dart';
import '../../data/repositories/sync_aware_lesson_repository.dart';
import '../../domain/repositories/lesson_repository.dart';

part 'lesson_repository_provider.g.dart';

/// Lesson repository provider - switches between Mock and SyncAware (Remote with offline queue).
@Riverpod(keepAlive: true)
LessonRepository lessonRepository(LessonRepositoryRef ref) =>
    createSyncAwareRepository<LessonRepository>(
      ref: ref,
      mock: () => MockLessonRepository(),
      syncAware: (api, queue) => SyncAwareLessonRepository(
        remote: RemoteLessonRepository(api),
        queue: queue,
        cache: LessonCacheStore(
          box: Hive.box<String>(LessonCacheStore.boxName),
        ),
      ),
    );
