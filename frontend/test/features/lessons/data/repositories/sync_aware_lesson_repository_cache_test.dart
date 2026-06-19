import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:lessonaza/features/lessons/data/local/lesson_cache_store.dart';
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
  late Box<String> hiveBox;
  late LessonCacheStore cacheStore;
  late SyncAwareLessonRepository repo;

  setUpAll(() {
    registerFallbackValue(_fakeEntry());
    registerFallbackValue(_testLesson());
  });

  setUp(() async {
    await setUpTestHive();
    hiveBox = await Hive.openBox<String>('lesson_cache_test');

    remote = MockRemoteLessonRepository();
    connectivity = MockConnectivityService();
    syncService = MockSyncService();
    cacheStore = LessonCacheStore(box: hiveBox);

    repo = SyncAwareLessonRepository(
      remote: remote,
      queue: MutationQueueHelper(
        connectivity: connectivity,
        syncService: syncService,
      ),
      cache: cacheStore,
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('getLessons — cache read-through', () {
    test('online success: result is written to cache', () async {
      final lessons = [_testLesson()];
      when(() => remote.getLessons()).thenAnswer((_) async => lessons);

      final result = await repo.getLessons();
      expect(result, equals(lessons));

      // Cache should now contain the result
      final cached = cacheStore.getLessons(LessonCacheStore.keyAll());
      expect(cached, isNotNull);
      expect(cached!.length, equals(1));
      expect(cached.first.id, equals('test-id'));
    });

    test('NetworkException with cached data: returns cached lessons', () async {
      // Pre-populate cache
      final cachedLessons = [_testLesson(id: 'cached')];
      await cacheStore.putLessons(LessonCacheStore.keyAll(), cachedLessons);

      when(
        () => remote.getLessons(),
      ).thenThrow(const NetworkException(message: 'timeout'));

      final result = await repo.getLessons();
      expect(result.length, equals(1));
      expect(result.first.id, equals('cached'));
    });

    test('NetworkException with no cache: rethrows', () async {
      when(
        () => remote.getLessons(),
      ).thenThrow(const NetworkException(message: 'no internet'));

      expect(() => repo.getLessons(), throwsA(isA<NetworkException>()));
    });

    test('ServerException with cached data: returns cached lessons', () async {
      final cachedLessons = [_testLesson(id: 'cached-server-err')];
      await cacheStore.putLessons(LessonCacheStore.keyAll(), cachedLessons);

      when(
        () => remote.getLessons(),
      ).thenThrow(const ServerException(message: 'server error'));

      final result = await repo.getLessons();
      expect(result.first.id, equals('cached-server-err'));
    });

    test('non-network error (NotFoundException) is NOT caught', () async {
      await cacheStore.putLessons(LessonCacheStore.keyAll(), [_testLesson()]);

      when(
        () => remote.getLessons(),
      ).thenThrow(const NotFoundException(message: '404'));

      expect(() => repo.getLessons(), throwsA(isA<NotFoundException>()));
    });
  });

  group('getLessonsByStudent — cache per studentId', () {
    test('online success: writes to student-scoped key', () async {
      final lessons = [_testLesson()];
      when(
        () => remote.getLessonsByStudent('s-1'),
      ).thenAnswer((_) async => lessons);

      await repo.getLessonsByStudent('s-1');

      final key = LessonCacheStore.keyStudent('s-1');
      expect(cacheStore.getLessons(key), isNotNull);
    });

    test('offline: returns cached per-student list', () async {
      final cached = [_testLesson(id: 'by-student')];
      final key = LessonCacheStore.keyStudent('s-1');
      await cacheStore.putLessons(key, cached);

      when(
        () => remote.getLessonsByStudent('s-1'),
      ).thenThrow(const NetworkException(message: 'no net'));

      final result = await repo.getLessonsByStudent('s-1');
      expect(result.first.id, equals('by-student'));
    });
  });

  group('getLesson (nullable) — cache', () {
    test('online success: caches the single lesson', () async {
      final lesson = _testLesson(id: 'single');
      when(() => remote.getLesson('single')).thenAnswer((_) async => lesson);

      await repo.getLesson('single');

      final key = LessonCacheStore.keyLesson('single');
      expect(cacheStore.getLesson(key), isNotNull);
      expect(cacheStore.getLesson(key)!.id, equals('single'));
    });

    test('NetworkException with cached lesson: returns cached', () async {
      final cached = _testLesson(id: 'single');
      final key = LessonCacheStore.keyLesson('single');
      await cacheStore.putLesson(key, cached);

      when(
        () => remote.getLesson('single'),
      ).thenThrow(const NetworkException(message: 'offline'));

      final result = await repo.getLesson('single');
      expect(result, isNotNull);
      expect(result!.id, equals('single'));
    });

    test('NetworkException with no cache: rethrows', () async {
      when(
        () => remote.getLesson('missing'),
      ).thenThrow(const NetworkException(message: 'offline'));

      expect(() => repo.getLesson('missing'), throwsA(isA<NetworkException>()));
    });
  });

  group('cache key isolation', () {
    test('different studentIds produce different cache entries', () async {
      final l1 = [_testLesson(id: 'a')];
      final l2 = [_testLesson(id: 'b')];

      when(() => remote.getLessonsByStudent('s1')).thenAnswer((_) async => l1);
      when(() => remote.getLessonsByStudent('s2')).thenAnswer((_) async => l2);

      await repo.getLessonsByStudent('s1');
      await repo.getLessonsByStudent('s2');

      expect(
        cacheStore.getLessons(LessonCacheStore.keyStudent('s1'))!.first.id,
        equals('a'),
      );
      expect(
        cacheStore.getLessons(LessonCacheStore.keyStudent('s2'))!.first.id,
        equals('b'),
      );
    });
  });

  group('write→read integration (no read override)', () {
    test('online write then offline read returns same data', () async {
      final lessons = [_testLesson(id: 'int-test')];

      // Step 1: Online read writes to cache
      when(() => remote.getLessons()).thenAnswer((_) async => lessons);
      final online = await repo.getLessons();
      expect(online.first.id, equals('int-test'));

      // Step 2: Subsequent offline read returns cached data
      when(
        () => remote.getLessons(),
      ).thenThrow(const NetworkException(message: 'offline'));
      final offline = await repo.getLessons();
      expect(offline.first.id, equals('int-test'));
    });
  });

  group('LessonCacheStore — raw JSON roundtrip', () {
    test('putLessons / getLessons roundtrip', () async {
      final lessons = [_testLesson(id: 'rt-1'), _testLesson(id: 'rt-2')];
      await cacheStore.putLessons('rt-key', lessons);
      final retrieved = cacheStore.getLessons('rt-key');
      expect(retrieved, isNotNull);
      expect(retrieved!.map((l) => l.id).toList(), equals(['rt-1', 'rt-2']));
    });

    test('getLessons on missing key returns null', () {
      expect(cacheStore.getLessons('no-such-key'), isNull);
    });

    test('getLessons on corrupt JSON returns null', () async {
      await hiveBox.put('corrupt', 'not-valid-json{{{');
      expect(cacheStore.getLessons('corrupt'), isNull);
    });

    test('cachedAt field is present in stored JSON', () async {
      await cacheStore.putLessons('ts-key', [_testLesson()]);
      final raw = hiveBox.get('ts-key')!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['cachedAt'], isA<String>());
    });
  });
}
