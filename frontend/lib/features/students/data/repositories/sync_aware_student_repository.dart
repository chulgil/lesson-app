import 'package:uuid/uuid.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/student_repository.dart';
import '../local/student_cache_store.dart';
import 'remote_student_repository.dart';

/// Decorator that wraps [RemoteStudentRepository] with:
///   1. Hive read-through cache — successful remote reads are persisted.
///   2. Offline queue support for mutations.
///
/// Read behaviour (per method):
///   - Online success → write to cache, return result.
///   - Network failure ([NetworkException] / [ServerException]) → return cached
///     last-known-good if available, otherwise rethrow.
///   - Cache miss + network failure → rethrow original error.
class SyncAwareStudentRepository implements StudentRepository {
  SyncAwareStudentRepository({
    required RemoteStudentRepository remote,
    required MutationQueueHelper queue,
    required StudentCacheStore cache,
  }) : _remote = remote,
       _queue = queue,
       _cache = cache;

  final RemoteStudentRepository _remote;
  final MutationQueueHelper _queue;
  final StudentCacheStore _cache;

  // --------------------------------------------------------------------------
  // Read methods — with cache fallback
  // --------------------------------------------------------------------------

  @override
  Future<List<Student>> getStudents() =>
      _readListWithCache(StudentCacheStore.keyAll(), _remote.getStudents);

  @override
  Future<Student?> getStudent(String id) async {
    final key = StudentCacheStore.keyStudent(id);
    try {
      final result = await _remote.getStudent(id);
      await _cache.putStudent(key, result);
      return result;
    } on Exception catch (e) {
      if (_isNetworkFailure(e)) {
        final cached = _cache.getStudent(key);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<List<Student>> searchStudents(String query) => _readListWithCache(
    StudentCacheStore.keySearch(query),
    () => _remote.searchStudents(query),
  );

  @override
  Future<List<Student>> getStudentsByStatus(StudentStatus status) =>
      _readListWithCache(
        StudentCacheStore.keyStatus(status.name),
        () => _remote.getStudentsByStatus(status),
      );

  // --------------------------------------------------------------------------
  // Shared list read helper
  // --------------------------------------------------------------------------

  Future<List<Student>> _readListWithCache(
    String key,
    Future<List<Student>> Function() fetch,
  ) async {
    try {
      final result = await fetch();
      await _cache.putStudents(key, result);
      return result;
    } on Exception catch (e) {
      if (_isNetworkFailure(e)) {
        final cached = _cache.getStudents(key);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Mutation methods — use MutationQueueHelper for offline support
  // --------------------------------------------------------------------------

  @override
  Future<Student> createStudent(Student student) => _queue.executeMutation(
    remoteCall: () => _remote.createStudent(student),
    queueCall: (syncService) => syncService.queueMutation(
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
    queueCall: (syncService) => syncService.queueMutation(
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
    queueCall: (syncService) => syncService.queueMutation(
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
        queueCall: (syncService) => syncService.queueMutation(
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
    queueCall: (syncService) => syncService.queueMutation(
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
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'student',
      httpMethod: 'PATCH',
      path: '/students/$id/unarchive',
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
