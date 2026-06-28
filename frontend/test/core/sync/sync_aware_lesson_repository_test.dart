import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:lessonaza/features/lessons/data/repositories/remote_lesson_repository.dart';
import 'package:lessonaza/features/lessons/data/repositories/sync_aware_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/entities.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteLessonRepository extends Mock
    implements RemoteLessonRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

Lesson _testLesson({String id = 'test-id'}) {
  return Lesson(
    id: id,
    studentId: 'student-1',
    studentName: 'Test Student',
    teacherId: 'teacher-1',
    instrument: 'violin',
    date: DateTime(2026, 5, 9),
    startTime: '10:00',
    status: LessonStatus.scheduled,
    createdAt: DateTime(2026, 5, 9),
  );
}

SyncQueueEntry _fakeEntry() {
  final now = DateTime.now().toUtc();
  return SyncQueueEntry(
    id: 'entry-1',
    domain: 'lesson',
    operation: SyncOperationType.create,
    httpMethod: 'POST',
    path: '/lessons',
    payload: const {},
    queryParameters: const {},
    status: SyncQueueStatus.pending,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockRemoteLessonRepository remote;
  late MockConnectivityService connectivity;
  late MockSyncService syncService;
  late SyncAwareLessonRepository repo;

  setUpAll(() {
    registerFallbackValue(_fakeEntry());
    registerFallbackValue(_testLesson());
  });

  setUp(() {
    remote = MockRemoteLessonRepository();
    connectivity = MockConnectivityService();
    syncService = MockSyncService();

    repo = SyncAwareLessonRepository(
      remote: remote,
      queue: MutationQueueHelper(
        connectivity: connectivity,
        syncService: syncService,
      ),
    );
  });

  group('read methods delegate to remote', () {
    test('getLessons', () async {
      final lessons = [_testLesson()];
      when(() => remote.getLessons()).thenAnswer((_) async => lessons);

      final result = await repo.getLessons();
      expect(result, equals(lessons));
      verify(() => remote.getLessons()).called(1);
    });

    test('getLesson', () async {
      final lesson = _testLesson();
      when(() => remote.getLesson('test-id')).thenAnswer((_) async => lesson);

      final result = await repo.getLesson('test-id');
      expect(result, equals(lesson));
    });

    test('getLessonsByStudent', () async {
      when(() => remote.getLessonsByStudent('s1')).thenAnswer((_) async => []);

      final result = await repo.getLessonsByStudent('s1');
      expect(result, isEmpty);
    });
  });

  group('createLesson', () {
    test('online: returns server entity', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      final lesson = _testLesson(id: 'new');
      final serverLesson = _testLesson(id: 'server-assigned');
      when(
        () => remote.createLesson(lesson),
      ).thenAnswer((_) async => serverLesson);

      final result = await repo.createLesson(lesson);
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

      final lesson = _testLesson(id: 'new');
      final result = await repo.createLesson(lesson);

      expect(result.id, startsWith('tmp_'));
      verify(
        () => syncService.queueMutation(
          domain: 'lesson',
          httpMethod: 'POST',
          path: '/lessons',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('NetworkException: falls back to queue', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remote.createLesson(any()),
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

      final result = await repo.createLesson(_testLesson());
      expect(result.id, startsWith('tmp_'));
    });
  });

  group('updateLesson', () {
    test('online: returns server entity', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      final lesson = _testLesson();
      when(() => remote.updateLesson(lesson)).thenAnswer((_) async => lesson);

      final result = await repo.updateLesson(lesson);
      expect(result.id, equals('test-id'));
    });

    test('offline: returns input lesson', () async {
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

      final lesson = _testLesson();
      final result = await repo.updateLesson(lesson);
      expect(result.id, equals('test-id'));
    });
  });

  group('deleteLesson', () {
    test('online: delegates to remote', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => remote.deleteLesson('id-1')).thenAnswer((_) async {});

      await repo.deleteLesson('id-1');
      verify(() => remote.deleteLesson('id-1')).called(1);
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

      await repo.deleteLesson('id-1');
      verify(
        () => syncService.queueMutation(
          domain: 'lesson',
          httpMethod: 'DELETE',
          path: '/lessons/id-1',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });
  });

  group('cancelLesson', () {
    test('offline: queues PATCH with cancelled status', () async {
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

      await repo.cancelLesson('id-1');
      verify(
        () => syncService.queueMutation(
          domain: 'lesson',
          httpMethod: 'PATCH',
          path: '/lessons/id-1/status',
          payload: {'status': 'cancelled'},
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });
  });
}
