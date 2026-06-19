import 'package:uuid/uuid.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../local/lesson_cache_store.dart';
import 'remote_lesson_repository.dart';

/// Decorator that wraps [RemoteLessonRepository] with:
///   1. Hive read-through cache — successful remote reads are persisted.
///   2. Offline queue support for mutations.
///
/// Read behaviour (per method):
///   - Online success → write to cache, return result.
///   - Network failure ([NetworkException] / [ServerException]) → return cached
///     last-known-good if available, otherwise rethrow.
///   - Cache miss + network failure → rethrow original error.
class SyncAwareLessonRepository implements LessonRepository {
  SyncAwareLessonRepository({
    required RemoteLessonRepository remote,
    required MutationQueueHelper queue,
    required LessonCacheStore cache,
  }) : _remote = remote,
       _queue = queue,
       _cache = cache;

  final RemoteLessonRepository _remote;
  final MutationQueueHelper _queue;
  final LessonCacheStore _cache;

  // --------------------------------------------------------------------------
  // Read methods — with cache fallback
  // --------------------------------------------------------------------------

  @override
  Future<List<Lesson>> getLessons() =>
      _readListWithCache(LessonCacheStore.keyAll(), _remote.getLessons);

  @override
  Future<List<Lesson>> getLessonsByStudent(String studentId) =>
      _readListWithCache(
        LessonCacheStore.keyStudent(studentId),
        () => _remote.getLessonsByStudent(studentId),
      );

  @override
  Future<List<Lesson>> getLessonsByDate(DateTime date) => _readListWithCache(
    LessonCacheStore.keyDate(date),
    () => _remote.getLessonsByDate(date),
  );

  @override
  Future<List<Lesson>> getLessonsByDateRange(DateTime start, DateTime end) =>
      _readListWithCache(
        LessonCacheStore.keyRange(start, end),
        () => _remote.getLessonsByDateRange(start, end),
      );

  @override
  Future<List<Lesson>> getUpcomingLessons({int limit = 10}) =>
      _readListWithCache(
        LessonCacheStore.keyUpcoming(limit),
        () => _remote.getUpcomingLessons(limit: limit),
      );

  @override
  Future<List<Lesson>> getRecentLessons({int limit = 10}) => _readListWithCache(
    LessonCacheStore.keyRecent(limit),
    () => _remote.getRecentLessons(limit: limit),
  );

  @override
  Future<Lesson?> getLesson(String id) async {
    final key = LessonCacheStore.keyLesson(id);
    try {
      final result = await _remote.getLesson(id);
      await _cache.putLesson(key, result);
      return result;
    } on Exception catch (e) {
      if (_isNetworkFailure(e)) {
        final cached = _cache.getLesson(key);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Shared list read helper
  // --------------------------------------------------------------------------

  Future<List<Lesson>> _readListWithCache(
    String key,
    Future<List<Lesson>> Function() fetch,
  ) async {
    try {
      final result = await fetch();
      await _cache.putLessons(key, result);
      return result;
    } on Exception catch (e) {
      if (_isNetworkFailure(e)) {
        final cached = _cache.getLessons(key);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Mutation methods — use MutationQueueHelper for offline support
  // --------------------------------------------------------------------------

  @override
  Future<Lesson> createLesson(Lesson lesson) => _queue.executeMutation(
    remoteCall: () => _remote.createLesson(lesson),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'lesson',
      httpMethod: 'POST',
      path: '/lessons',
      payload: lesson.toJson(),
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => lesson.copyWith(id: 'tmp_${const Uuid().v4()}'),
  );

  @override
  Future<Lesson> updateLesson(Lesson lesson) => _queue.executeMutation(
    remoteCall: () => _remote.updateLesson(lesson),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'lesson',
      httpMethod: 'PUT',
      path: '/lessons/${lesson.id}',
      payload: lesson.toJson(),
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => lesson,
  );

  @override
  Future<void> deleteLesson(String id) => _queue.executeVoidMutation(
    remoteCall: () => _remote.deleteLesson(id),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'lesson',
      httpMethod: 'DELETE',
      path: '/lessons/$id',
      payload: {},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<void> cancelLesson(String id) => _queue.executeVoidMutation(
    remoteCall: () => _remote.cancelLesson(id),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'lesson',
      httpMethod: 'PATCH',
      path: '/lessons/$id/status',
      payload: {'status': 'cancelled'},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<void> archiveLesson(String id) => _queue.executeVoidMutation(
    remoteCall: () => _remote.archiveLesson(id),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'lesson',
      httpMethod: 'PATCH',
      path: '/lessons/$id/archive',
      payload: {},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<void> unarchiveLesson(String id) => _queue.executeVoidMutation(
    remoteCall: () => _remote.unarchiveLesson(id),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'lesson',
      httpMethod: 'PATCH',
      path: '/lessons/$id/unarchive',
      payload: {},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
  );

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  bool _isNetworkFailure(Exception e) {
    if (e is NetworkException) return true;
    if (e is ServerException) return true;
    if (e is ApiException && e.statusCode != null && e.statusCode! >= 500) {
      return true;
    }
    return false;
  }
}
