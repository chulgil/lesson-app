import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:lessonaza/features/students/data/repositories/remote_student_repository.dart';
import 'package:lessonaza/features/students/data/repositories/sync_aware_student_repository.dart';
import 'package:lessonaza/features/students/domain/entities/entities.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteStudentRepository extends Mock
    implements RemoteStudentRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

Student _testStudent({String id = 'test-id'}) {
  return Student(
    id: id,
    name: 'Test Student',
    instrument: 'violin',
    status: StudentStatus.active,
    createdAt: DateTime(2026, 5, 9),
  );
}

SyncQueueEntry _fakeEntry() {
  final now = DateTime.now().toUtc();
  return SyncQueueEntry(
    id: 'entry-1',
    domain: 'student',
    operation: SyncOperationType.create,
    httpMethod: 'POST',
    path: '/students',
    payload: const {},
    queryParameters: const {},
    status: SyncQueueStatus.pending,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockRemoteStudentRepository remote;
  late MockConnectivityService connectivity;
  late MockSyncService syncService;
  late SyncAwareStudentRepository repo;

  setUpAll(() {
    registerFallbackValue(_fakeEntry());
    registerFallbackValue(_testStudent());
  });

  setUp(() {
    remote = MockRemoteStudentRepository();
    connectivity = MockConnectivityService();
    syncService = MockSyncService();

    repo = SyncAwareStudentRepository(
      remote: remote,
      queue: MutationQueueHelper(
        connectivity: connectivity,
        syncService: syncService,
      ),
    );
  });

  group('read methods delegate to remote', () {
    test('getStudents', () async {
      final students = [_testStudent()];
      when(() => remote.getStudents()).thenAnswer((_) async => students);

      final result = await repo.getStudents();
      expect(result, equals(students));
      verify(() => remote.getStudents()).called(1);
    });

    test('getStudent', () async {
      final student = _testStudent();
      when(() => remote.getStudent('test-id')).thenAnswer((_) async => student);

      final result = await repo.getStudent('test-id');
      expect(result, equals(student));
    });

    test('getMyProfile', () async {
      final student = _testStudent(id: 'me');
      when(() => remote.getMyProfile()).thenAnswer((_) async => student);

      final result = await repo.getMyProfile();
      expect(result.id, equals('me'));
    });

    test('searchStudents', () async {
      when(() => remote.searchStudents('q')).thenAnswer((_) async => []);

      final result = await repo.searchStudents('q');
      expect(result, isEmpty);
    });

    test('getStudentsByStatus', () async {
      when(
        () => remote.getStudentsByStatus(StudentStatus.active),
      ).thenAnswer((_) async => []);

      final result = await repo.getStudentsByStatus(StudentStatus.active);
      expect(result, isEmpty);
    });
  });

  group('createStudent', () {
    test('online: returns server entity', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      final student = _testStudent(id: 'new');
      final serverStudent = _testStudent(id: 'server-assigned');
      when(
        () => remote.createStudent(student),
      ).thenAnswer((_) async => serverStudent);

      final result = await repo.createStudent(student);
      expect(result.id, equals('server-assigned'));
    });

    test('offline: returns optimistic entity with tmp_ prefix', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      final student = _testStudent(id: 'new');
      final result = await repo.createStudent(student);

      expect(result.id, startsWith('tmp_'));
      verify(
        () => syncService.queueMutation(
          domain: 'student',
          httpMethod: 'POST',
          path: '/students',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('NetworkException: falls back to queue', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remote.createStudent(any()),
      ).thenThrow(const NetworkException(message: 'timeout'));
      when(
        () => syncService.queueMutation(
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      final result = await repo.createStudent(_testStudent());
      expect(result.id, startsWith('tmp_'));
    });
  });

  group('updateStudent', () {
    test('online: returns server entity', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      final student = _testStudent();
      when(
        () => remote.updateStudent(student),
      ).thenAnswer((_) async => student);

      final result = await repo.updateStudent(student);
      expect(result.id, equals('test-id'));
    });

    test('offline: returns input student', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      final student = _testStudent();
      final result = await repo.updateStudent(student);
      expect(result.id, equals('test-id'));
    });
  });

  group('deleteStudent', () {
    test('online: delegates to remote', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => remote.deleteStudent('id-1')).thenAnswer((_) async {});

      await repo.deleteStudent('id-1');
      verify(() => remote.deleteStudent('id-1')).called(1);
    });

    test('offline: queues without throw', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      await repo.deleteStudent('id-1');
      verify(
        () => syncService.queueMutation(
          domain: 'student',
          httpMethod: 'DELETE',
          path: '/students/id-1',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });
  });

  group('updateStudentStatus', () {
    test('offline: queues PATCH with status payload', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      // Optimistic result throws UnimplementedError when offline by design;
      // verify the mutation is queued before that surfaces.
      await expectLater(
        () => repo.updateStudentStatus('id-1', StudentStatus.inactive),
        throwsA(isA<UnimplementedError>()),
      );
      verify(
        () => syncService.queueMutation(
          domain: 'student',
          httpMethod: 'PATCH',
          path: '/students/id-1/status',
          payload: {'status': 'inactive'},
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });
  });

  group('archiveStudent / unarchiveStudent', () {
    test('offline: archive queues PATCH', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      await repo.archiveStudent('id-1');
      verify(
        () => syncService.queueMutation(
          domain: 'student',
          httpMethod: 'PATCH',
          path: '/students/id-1/archive',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('offline: unarchive queues PATCH', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      await repo.unarchiveStudent('id-1');
      verify(
        () => syncService.queueMutation(
          domain: 'student',
          httpMethod: 'PATCH',
          path: '/students/id-1/unarchive',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });
  });
}
