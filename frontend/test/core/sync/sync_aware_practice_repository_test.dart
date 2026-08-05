import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:lessonaza/features/practice/data/repositories/remote_practice_repository.dart';
import 'package:lessonaza/features/practice/data/repositories/sync_aware_practice_repository.dart';
import 'package:lessonaza/features/practice/domain/entities/entities.dart';
import 'package:mocktail/mocktail.dart';

class MockRemotePracticeRepository extends Mock
    implements RemotePracticeRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

PracticeLog _testLog({String id = 'log-1'}) {
  return PracticeLog(
    id: id,
    studentId: 'student-1',
    date: DateTime(2026, 5, 9),
    totalMinutes: 30,
    tasks: const [],
    createdAt: DateTime(2026, 5, 9),
  );
}

SyncQueueEntry _fakeEntry() {
  final now = DateTime.now().toUtc();
  return SyncQueueEntry(
    id: 'entry-1',
    domain: 'practice',
    operation: SyncOperationType.create,
    httpMethod: 'POST',
    path: '/practice-logs',
    payload: const {},
    queryParameters: const {},
    status: SyncQueueStatus.pending,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockRemotePracticeRepository remote;
  late MockConnectivityService connectivity;
  late MockSyncService syncService;
  late SyncAwarePracticeRepository repo;

  setUp(() {
    remote = MockRemotePracticeRepository();
    connectivity = MockConnectivityService();
    syncService = MockSyncService();

    repo = SyncAwarePracticeRepository(
      remote: remote,
      queue: MutationQueueHelper(
        connectivity: connectivity,
        syncService: syncService,
      ),
    );
  });

  setUpAll(() {
    registerFallbackValue(_fakeEntry());
    registerFallbackValue(_testLog());
  });

  group('read methods delegate to remote', () {
    test('getPracticeLogs', () async {
      when(() => remote.getPracticeLogs('s1'))
          .thenAnswer((_) async => [_testLog()]);

      final result = await repo.getPracticeLogs('s1');
      expect(result, hasLength(1));
      verify(() => remote.getPracticeLogs('s1')).called(1);
    });

    test('getPracticeLog', () async {
      final log = _testLog();
      when(() => remote.getPracticeLog('log-1'))
          .thenAnswer((_) async => log);

      final result = await repo.getPracticeLog('log-1');
      expect(result, equals(log));
    });

    test('getStreak', () async {
      final streak = PracticeStreak(
        id: 's1',
        studentId: 'student-1',
        currentStreak: 5,
        longestStreak: 10,
        updatedAt: DateTime(2026, 5, 9),
      );
      when(() => remote.getStreak('student-1'))
          .thenAnswer((_) async => streak);

      final result = await repo.getStreak('student-1');
      expect(result.currentStreak, equals(5));
    });
  });

  group('createPracticeLog', () {
    test('online: returns server entity', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      final log = _testLog(id: 'new');
      final serverLog = _testLog(id: 'server-id');
      when(() => remote.createPracticeLog(log))
          .thenAnswer((_) async => serverLog);

      final result = await repo.createPracticeLog(log);
      expect(result.id, equals('server-id'));
    });

    test('offline: returns optimistic with tmp_ prefix', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      final result = await repo.createPracticeLog(_testLog());
      expect(result.id, startsWith('tmp_'));
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'practice',
          httpMethod: 'POST',
          path: '/practice-logs',
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('NetworkException: falls back to queue', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => remote.createPracticeLog(any()))
          .thenThrow(const NetworkException(message: 'timeout'));
      when(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      final result = await repo.createPracticeLog(_testLog());
      expect(result.id, startsWith('tmp_'));
    });
  });

  group('updatePracticeLog', () {
    test('offline: returns input log', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      final log = _testLog();
      final result = await repo.updatePracticeLog(log);
      expect(result.id, equals('log-1'));
    });
  });

  group('deletePracticeLog', () {
    test('online: delegates to remote', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => remote.deletePracticeLog('log-1')).thenAnswer((_) async {});

      await repo.deletePracticeLog('log-1');
      verify(() => remote.deletePracticeLog('log-1')).called(1);
    });

    test('offline: queues without throw', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      await repo.deletePracticeLog('log-1');
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'practice',
          httpMethod: 'DELETE',
          path: '/practice-logs/log-1',
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  group('toggleTask', () {
    test('always delegates to remote (online-only)', () async {
      final task = PracticeTask(
        id: 'task-1',
        title: 'Scale practice',
        isCompleted: true,
      );
      when(() => remote.toggleTask('log-1', 'task-1'))
          .thenAnswer((_) async => task);

      final result = await repo.toggleTask('log-1', 'task-1');
      expect(result.isCompleted, isTrue);
      verify(() => remote.toggleTask('log-1', 'task-1')).called(1);
    });
  });

  group('recordPractice', () {
    test('offline: queues with queryParameters', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      final result = await repo.recordPractice('student-1');
      expect(result.studentId, equals('student-1'));
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'practice',
          httpMethod: 'POST',
          path: '/practice/streak/record',
          payload: const {},
          queryParameters: {'student_id': 'student-1'},
        ),
      ).called(1);
    });
  });
}
