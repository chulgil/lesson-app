import 'package:uuid/uuid.dart';

import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/student_repository.dart';
import 'remote_student_repository.dart';

/// Decorator that wraps [RemoteStudentRepository] with offline **write-queue**
/// support ([MutationQueueHelper]).
///
/// Reads delegate straight to the remote repository — offline read fallback is
/// provided transparently at the HTTP layer by `ResponseCacheInterceptor`
/// (offline-first plan §3 option A; batch 1 일원화 — the previous Hive
/// read-through cache layer was removed in favour of the single HTTP response
/// cache). Writes are queued when offline and replayed on reconnect.
class SyncAwareStudentRepository implements StudentRepository {
  SyncAwareStudentRepository({
    required RemoteStudentRepository remote,
    required MutationQueueHelper queue,
  }) : _remote = remote,
       _queue = queue;

  final RemoteStudentRepository _remote;
  final MutationQueueHelper _queue;

  // --------------------------------------------------------------------------
  // Read methods — delegate to remote; HTTP response cache handles offline.
  // --------------------------------------------------------------------------

  @override
  Future<List<Student>> getStudents() => _remote.getStudents();

  @override
  Future<Student?> getStudent(String id) => _remote.getStudent(id);

  @override
  Future<Student> getMyProfile() => _remote.getMyProfile();

  @override
  Future<List<Student>> searchStudents(String query) =>
      _remote.searchStudents(query);

  @override
  Future<List<Student>> getStudentsByStatus(StudentStatus status) =>
      _remote.getStudentsByStatus(status);

  // --------------------------------------------------------------------------
  // Mutation methods — use MutationQueueHelper for offline support
  // --------------------------------------------------------------------------

  @override
  Future<Student> createStudent(Student student) => _queue.executeMutation(
    remoteCall: () => _remote.createStudent(student),
    queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
      idempotencyKey: idempotencyKey,
      domain: 'student',
      httpMethod: 'POST',
      path: '/students',
      payload: student.toJson(),
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => student.copyWith(id: 'tmp_${const Uuid().v4()}'),
  );

  @override
  Future<Student> updateStudent(Student student) => _queue.executeMutation(
    remoteCall: () => _remote.updateStudent(student),
    queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
      idempotencyKey: idempotencyKey,
      domain: 'student',
      httpMethod: 'PUT',
      path: '/students/${student.id}',
      payload: student.toJson(),
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => student,
  );

  @override
  Future<void> deleteStudent(String id) => _queue.executeVoidMutation(
    remoteCall: () => _remote.deleteStudent(id),
    queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
      idempotencyKey: idempotencyKey,
      domain: 'student',
      httpMethod: 'DELETE',
      path: '/students/$id',
      payload: {},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<Student> updateStudentStatus(String studentId, StudentStatus status) =>
      _queue.executeMutation(
        remoteCall: () => _remote.updateStudentStatus(studentId, status),
        queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
          idempotencyKey: idempotencyKey,
          domain: 'student',
          httpMethod: 'PATCH',
          path: '/students/$studentId/status',
          payload: {'status': status.name},
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
        optimisticResult: () => throw UnimplementedError(
          'updateStudentStatus optimistic result not supported offline',
        ),
      );

  @override
  Future<void> archiveStudent(String id) => _queue.executeVoidMutation(
    remoteCall: () => _remote.archiveStudent(id),
    queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
      idempotencyKey: idempotencyKey,
      domain: 'student',
      httpMethod: 'PATCH',
      path: '/students/$id/archive',
      payload: {},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<void> unarchiveStudent(String id) => _queue.executeVoidMutation(
    remoteCall: () => _remote.unarchiveStudent(id),
    queueCall: (syncService, idempotencyKey) => syncService.queueMutation(
      idempotencyKey: idempotencyKey,
      domain: 'student',
      httpMethod: 'PATCH',
      path: '/students/$id/unarchive',
      payload: {},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
  );
}
