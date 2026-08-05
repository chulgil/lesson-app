import 'package:uuid/uuid.dart';

import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_repository.dart';
import 'remote_practice_repository.dart';

/// Decorator for [RemotePracticeRepository] with offline-queue support.
///
/// Read operations delegate directly to the remote repository.
/// Write operations (create, update, delete) use [MutationQueueHelper] for offline resilience.
///
/// Note: [toggleTask] requires server state to determine the result, so it remains online-only.
class SyncAwarePracticeRepository implements PracticeRepository {
  SyncAwarePracticeRepository({
    required RemotePracticeRepository remote,
    required MutationQueueHelper queue,
  }) : _remote = remote,
       _queue = queue;

  final RemotePracticeRepository _remote;
  final MutationQueueHelper _queue;

  // --- Read operations (online-only) ---

  @override
  Future<List<PracticeLog>> getPracticeLogs(String studentId) =>
      _remote.getPracticeLogs(studentId);

  @override
  Future<PracticeLog?> getPracticeLog(String id) => _remote.getPracticeLog(id);

  @override
  Future<PracticeLog?> getPracticeLogByDate(String studentId, DateTime date) =>
      _remote.getPracticeLogByDate(studentId, date);

  @override
  Future<Map<DateTime, PracticeLog>> getPracticeLogsByMonth(
    String studentId,
    int year,
    int month,
  ) =>
      _remote.getPracticeLogsByMonth(studentId, year, month);

  @override
  Future<PracticeStats> getPracticeStats(
    String studentId,
    int year,
    int month,
  ) =>
      _remote.getPracticeStats(studentId, year, month);

  @override
  Future<List<bool>> getWeeklyPractice(String studentId) =>
      _remote.getWeeklyPractice(studentId);

  @override
  Future<PracticeStreak> getStreak(String studentId) =>
      _remote.getStreak(studentId);

  // --- Write operations (with queue support) ---

  @override
  Future<PracticeLog> createPracticeLog(PracticeLog log) =>
      _queue.executeMutation<PracticeLog>(
        remoteCall: () => _remote.createPracticeLog(log),
        queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
          domain: 'practice',
          httpMethod: 'POST',
          path: '/practice-logs',
          payload: {
            'id': log.id,
            'student_id': log.studentId,
            'date': log.date.toIso8601String(),
            'total_minutes': log.totalMinutes,
            'notes': log.notes,
          },
        ),
        optimisticResult: () =>
            log.copyWith(id: 'tmp_${const Uuid().v4()}'),
      );

  @override
  Future<PracticeLog> updatePracticeLog(PracticeLog log) =>
      // #1119 (D4): practice is a Last-Write-Wins domain. `log.updatedAt` is
      // the base version the client edited from — sent as the
      // If-Unmodified-Since precondition on the direct send and stored as
      // `clientUpdatedAt` on the queued replay, so the server rejects (412) a
      // write it has since superseded. Null (never round-tripped) → applies.
      _queue.executeMutation<PracticeLog>(
        remoteCall: () =>
            _remote.updatePracticeLog(log, ifUnmodifiedSince: log.updatedAt),
        queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
          domain: 'practice',
          httpMethod: 'PUT',
          path: '/practice-logs/${log.id}',
          clientUpdatedAt: log.updatedAt,
          payload: {
            'id': log.id,
            'student_id': log.studentId,
            'date': log.date.toIso8601String(),
            'total_minutes': log.totalMinutes,
            'notes': log.notes,
          },
        ),
        optimisticResult: () => log,
      );

  @override
  Future<void> deletePracticeLog(String id) =>
      _queue.executeVoidMutation(
        remoteCall: () => _remote.deletePracticeLog(id),
        queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
          domain: 'practice',
          httpMethod: 'DELETE',
          path: '/practice-logs/$id',
          payload: const {},
        ),
      );

  // --- Task operations ---

  @override
  // Online-only: requires server state to determine toggle result
  Future<PracticeTask> toggleTask(String logId, String taskId) =>
      _remote.toggleTask(logId, taskId);

  // --- Streak operations (with queue support) ---

  @override
  Future<PracticeStreak> updateStreak(String studentId) =>
      _queue.executeMutation<PracticeStreak>(
        remoteCall: () => _remote.updateStreak(studentId),
        queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
          domain: 'practice',
          httpMethod: 'PUT',
          path: '/practice/streak',
          payload: const {},
          queryParameters: {'student_id': studentId},
        ),
        optimisticResult: () => PracticeStreak(
          id: '',
          studentId: studentId,
          currentStreak: 0,
          longestStreak: 0,
          lastPracticeDate: null,
          updatedAt: DateTime.now(),
        ),
      );

  @override
  Future<PracticeStreak> recordPractice(String studentId) =>
      _queue.executeMutation<PracticeStreak>(
        remoteCall: () => _remote.recordPractice(studentId),
        queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
          domain: 'practice',
          httpMethod: 'POST',
          path: '/practice/streak/record',
          payload: const {},
          queryParameters: {'student_id': studentId},
        ),
        optimisticResult: () => PracticeStreak(
          id: '',
          studentId: studentId,
          currentStreak: 0,
          longestStreak: 0,
          lastPracticeDate: null,
          updatedAt: DateTime.now(),
        ),
      );
}
