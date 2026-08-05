import 'package:uuid/uuid.dart';

import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_update_payload.dart';
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
  Future<Lesson> createLesson(Lesson lesson, {String? overflowMode}) =>
      _queue.executeMutation(
        remoteCall:
            () => _remote.createLesson(lesson, overflowMode: overflowMode),
        queueCall:
            (syncService, idempotencyKey) => syncService.queueMutation(
              idempotencyKey: idempotencyKey,
              domain: 'lesson',
              httpMethod: 'POST',
              path: '/lessons',
              payload: {
                ...lesson.toJson(),
                if (overflowMode != null) 'overflow_mode': overflowMode,
              },
              clientUpdatedAt: DateTime.now().toUtc(),
            ),
        optimisticResult: () => lesson.copyWith(id: 'tmp_${const Uuid().v4()}'),
      );

  @override
  Future<Lesson> updateLesson(Lesson lesson) => _queue.executeMutation(
    remoteCall: () => _remote.updateLesson(lesson),
    queueCall:
        (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
          domain: 'lesson',
          httpMethod: 'PUT',
          path: '/lessons/${lesson.id}',
          // Whitelist payload — the queued body must match what the backend
          // accepts (#1238), otherwise the replay 422s once connectivity is back.
          payload: lessonScheduleUpdatePayload(lesson),
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
    optimisticResult: () => lesson,
  );

  @override
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) =>
      _queue.executeMutation(
        remoteCall: () => _remote.updateLessonStatus(lesson, status),
        queueCall:
            (syncService, idempotencyKey) => syncService.queueMutation(
              idempotencyKey: idempotencyKey,
              domain: 'lesson',
              httpMethod: 'PATCH',
              path: '/lessons/${lesson.id}/status',
              payload: {'status': status.name},
              clientUpdatedAt: DateTime.now().toUtc(),
            ),
        // Server-side effects (deduction, notifications) land on replay; the
        // offline value only flips the status so the list stops lying.
        optimisticResult: () => lesson.copyWith(status: status),
      );

  @override
  Future<Lesson> updateLessonFeedback(
    Lesson lesson, {
    String? feedback,
    List<String>? keyPoints,
    String? practiceTips,
  }) => _queue.executeMutation(
    remoteCall: () => _remote.updateLessonFeedback(
      lesson,
      feedback: feedback,
      keyPoints: keyPoints,
      practiceTips: practiceTips,
    ),
    queueCall:
        (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
          domain: 'lesson',
          httpMethod: 'PUT',
          path: '/lessons/${lesson.id}/feedback',
          payload: {
            if (feedback != null) 'feedback': feedback,
            if (keyPoints != null) 'key_points': keyPoints,
            if (practiceTips != null) 'practice_tips': practiceTips,
          },
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
    optimisticResult: () => lesson.copyWith(
      feedback: feedback ?? lesson.feedback,
      keyPoints: keyPoints ?? lesson.keyPoints,
      practiceTips: practiceTips ?? lesson.practiceTips,
    ),
  );

  @override
  Future<void> deleteLesson(String id) => _queue.executeVoidMutation(
    remoteCall: () => _remote.deleteLesson(id),
    queueCall:
        (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
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
    queueCall:
        (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
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
    queueCall:
        (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
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
    queueCall:
        (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
          domain: 'lesson',
          httpMethod: 'PATCH',
          path: '/lessons/$id/unarchive',
          payload: {},
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
  );
}
