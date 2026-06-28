import 'package:uuid/uuid.dart';

import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'remote_lesson_repository.dart';

/// Decorator that wraps [RemoteLessonRepository] with offline **write-queue**
/// support ([MutationQueueHelper]).
///
/// Reads delegate straight to the remote repository — offline read fallback is
/// provided transparently at the HTTP layer by `ResponseCacheInterceptor`
/// (offline-first plan §3 option A; batch 1 일원화 — the previous Hive
/// read-through cache layer was removed in favour of the single HTTP response
/// cache). Writes are queued when offline and replayed on reconnect.
class SyncAwareLessonRepository implements LessonRepository {
  SyncAwareLessonRepository({
    required RemoteLessonRepository remote,
    required MutationQueueHelper queue,
  }) : _remote = remote,
       _queue = queue;

  final RemoteLessonRepository _remote;
  final MutationQueueHelper _queue;

  // --------------------------------------------------------------------------
  // Read methods — delegate to remote; HTTP response cache handles offline.
  // --------------------------------------------------------------------------

  @override
  Future<List<Lesson>> getLessons() => _remote.getLessons();

  @override
  Future<List<Lesson>> getLessonsByStudent(String studentId) =>
      _remote.getLessonsByStudent(studentId);

  @override
  Future<List<Lesson>> getLessonsByDate(DateTime date) =>
      _remote.getLessonsByDate(date);

  @override
  Future<List<Lesson>> getLessonsByDateRange(DateTime start, DateTime end) =>
      _remote.getLessonsByDateRange(start, end);

  @override
  Future<List<Lesson>> getUpcomingLessons({int limit = 10}) =>
      _remote.getUpcomingLessons(limit: limit);

  @override
  Future<List<Lesson>> getRecentLessons({int limit = 10}) =>
      _remote.getRecentLessons(limit: limit);

  @override
  Future<Lesson?> getLesson(String id) => _remote.getLesson(id);

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
}
