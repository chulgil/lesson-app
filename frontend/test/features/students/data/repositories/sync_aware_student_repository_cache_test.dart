import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:lessonaza/features/students/data/local/student_cache_store.dart';
import 'package:lessonaza/features/students/data/repositories/remote_student_repository.dart';
import 'package:lessonaza/features/students/data/repositories/sync_aware_student_repository.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteStudentRepository extends Mock
    implements RemoteStudentRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

Student _testStudent({String id = 'test-student'}) {
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
  late Box<String> hiveBox;
  late StudentCacheStore cacheStore;
  late SyncAwareStudentRepository repo;

  setUpAll(() {
    registerFallbackValue(_fakeEntry());
    registerFallbackValue(_testStudent());
  });

  setUp(() async {
    await setUpTestHive();
    hiveBox = await Hive.openBox<String>('student_cache_test');

    remote = MockRemoteStudentRepository();
    connectivity = MockConnectivityService();
    syncService = MockSyncService();
    cacheStore = StudentCacheStore(box: hiveBox);

    repo = SyncAwareStudentRepository(
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

  // --------------------------------------------------------------------------
  // getStudents — list cache read-through
  // --------------------------------------------------------------------------

  group('getStudents — cache read-through', () {
    test('online success: result is written to cache', () async {
      final students = [_testStudent()];
      when(() => remote.getStudents()).thenAnswer((_) async => students);

      final result = await repo.getStudents();
      expect(result, equals(students));

      final cached = cacheStore.getStudents(StudentCacheStore.keyAll());
      expect(cached, isNotNull);
      expect(cached!.length, equals(1));
      expect(cached.first.id, equals('test-student'));
    });

    test(
      'NetworkException with cached data: returns cached students',
      () async {
        final cachedStudents = [_testStudent(id: 'cached')];
        await cacheStore.putStudents(
          StudentCacheStore.keyAll(),
          cachedStudents,
        );

        when(
          () => remote.getStudents(),
        ).thenThrow(const NetworkException(message: 'timeout'));

        final result = await repo.getStudents();
        expect(result.length, equals(1));
        expect(result.first.id, equals('cached'));
      },
    );

    test('NetworkException with no cache: rethrows', () async {
      when(
        () => remote.getStudents(),
      ).thenThrow(const NetworkException(message: 'no internet'));

      expect(() => repo.getStudents(), throwsA(isA<NetworkException>()));
    });

    test('ServerException with cached data: returns cached students', () async {
      final cachedStudents = [_testStudent(id: 'cached-server-err')];
      await cacheStore.putStudents(StudentCacheStore.keyAll(), cachedStudents);

      when(
        () => remote.getStudents(),
      ).thenThrow(const ServerException(message: 'server error'));

      final result = await repo.getStudents();
      expect(result.first.id, equals('cached-server-err'));
    });

    test('NotFoundException (non-network) is NOT caught by cache', () async {
      await cacheStore.putStudents(StudentCacheStore.keyAll(), [
        _testStudent(),
      ]);

      when(
        () => remote.getStudents(),
      ).thenThrow(const NotFoundException(message: '404'));

      expect(() => repo.getStudents(), throwsA(isA<NotFoundException>()));
    });
  });

  // --------------------------------------------------------------------------
  // getStudent (nullable single)
  // --------------------------------------------------------------------------

  group('getStudent — single student cache', () {
    test('online success: caches the single student', () async {
      final student = _testStudent(id: 'single');
      when(() => remote.getStudent('single')).thenAnswer((_) async => student);

      await repo.getStudent('single');

      final key = StudentCacheStore.keyStudent('single');
      expect(cacheStore.getStudent(key), isNotNull);
      expect(cacheStore.getStudent(key)!.id, equals('single'));
    });

    test('NetworkException with cached student: returns cached', () async {
      final cached = _testStudent(id: 'single');
      final key = StudentCacheStore.keyStudent('single');
      await cacheStore.putStudent(key, cached);

      when(
        () => remote.getStudent('single'),
      ).thenThrow(const NetworkException(message: 'offline'));

      final result = await repo.getStudent('single');
      expect(result, isNotNull);
      expect(result!.id, equals('single'));
    });

    test('NetworkException with no cache: rethrows', () async {
      when(
        () => remote.getStudent('missing'),
      ).thenThrow(const NetworkException(message: 'offline'));

      expect(
        () => repo.getStudent('missing'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // --------------------------------------------------------------------------
  // searchStudents — query-scoped cache
  // --------------------------------------------------------------------------

  group('searchStudents — query-scoped cache', () {
    test('online success: writes to query-scoped key', () async {
      final students = [_testStudent()];
      when(
        () => remote.searchStudents('violin'),
      ).thenAnswer((_) async => students);

      await repo.searchStudents('violin');

      final key = StudentCacheStore.keySearch('violin');
      expect(cacheStore.getStudents(key), isNotNull);
    });

    test('offline: returns cached search result', () async {
      final cached = [_testStudent(id: 'search-result')];
      final key = StudentCacheStore.keySearch('piano');
      await cacheStore.putStudents(key, cached);

      when(
        () => remote.searchStudents('piano'),
      ).thenThrow(const NetworkException(message: 'no net'));

      final result = await repo.searchStudents('piano');
      expect(result.first.id, equals('search-result'));
    });
  });

  // --------------------------------------------------------------------------
  // getStudentsByStatus — status-scoped cache
  // --------------------------------------------------------------------------

  group('getStudentsByStatus — status-scoped cache', () {
    test('online success: writes to status-scoped key', () async {
      final students = [_testStudent()];
      when(
        () => remote.getStudentsByStatus(StudentStatus.active),
      ).thenAnswer((_) async => students);

      await repo.getStudentsByStatus(StudentStatus.active);

      final key = StudentCacheStore.keyStatus(StudentStatus.active.name);
      expect(cacheStore.getStudents(key), isNotNull);
    });

    test('offline: returns cached status list', () async {
      final cached = [_testStudent(id: 'archived')];
      final key = StudentCacheStore.keyStatus(StudentStatus.inactive.name);
      await cacheStore.putStudents(key, cached);

      when(
        () => remote.getStudentsByStatus(StudentStatus.inactive),
      ).thenThrow(const NetworkException(message: 'no net'));

      final result = await repo.getStudentsByStatus(StudentStatus.inactive);
      expect(result.first.id, equals('archived'));
    });
  });

  // --------------------------------------------------------------------------
  // write→read integration (no read override)
  // --------------------------------------------------------------------------

  group('write→read integration (no read override)', () {
    test('online write then offline read returns same data', () async {
      final students = [_testStudent(id: 'int-test')];

      // Step 1: Online read writes to cache
      when(() => remote.getStudents()).thenAnswer((_) async => students);
      final online = await repo.getStudents();
      expect(online.first.id, equals('int-test'));

      // Step 2: Subsequent offline read returns cached data
      when(
        () => remote.getStudents(),
      ).thenThrow(const NetworkException(message: 'offline'));
      final offline = await repo.getStudents();
      expect(offline.first.id, equals('int-test'));
    });
  });

  // --------------------------------------------------------------------------
  // StudentCacheStore — raw JSON roundtrip
  // --------------------------------------------------------------------------

  group('StudentCacheStore — raw JSON roundtrip', () {
    test('putStudents / getStudents roundtrip', () async {
      final students = [_testStudent(id: 'rt-1'), _testStudent(id: 'rt-2')];
      await cacheStore.putStudents('rt-key', students);
      final retrieved = cacheStore.getStudents('rt-key');
      expect(retrieved, isNotNull);
      expect(retrieved!.map((s) => s.id).toList(), equals(['rt-1', 'rt-2']));
    });

    test('getStudents on missing key returns null', () {
      expect(cacheStore.getStudents('no-such-key'), isNull);
    });

    test('getStudents on corrupt JSON returns null', () async {
      await hiveBox.put('corrupt', 'not-valid-json{{{');
      expect(cacheStore.getStudents('corrupt'), isNull);
    });

    test('cachedAt field is present in stored JSON', () async {
      await cacheStore.putStudents('ts-key', [_testStudent()]);
      final raw = hiveBox.get('ts-key')!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['cachedAt'], isA<String>());
    });
  });
}
