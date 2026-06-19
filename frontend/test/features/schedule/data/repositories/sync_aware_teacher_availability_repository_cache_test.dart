import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:lessonaza/features/schedule/data/local/teacher_availability_cache_store.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/data/repositories/sync_aware_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteTeacherAvailabilityRepository extends Mock
    implements RemoteTeacherAvailabilityRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

TeacherAvailability _testAvailability({String teacherId = 'teacher-1'}) {
  return TeacherAvailability(
    id: 'avail-$teacherId',
    teacherId: teacherId,
    slotDurationMinutes: 60,
    weeklySchedules: const [],
    exceptions: const [],
    autoGenerateWeeks: 4,
    createdAt: DateTime(2026, 5, 9),
    slotStartInterval: 60,
    breakTimeBetweenLessons: 0,
    minBookingHours: 24,
  );
}

SyncQueueEntry _fakeEntry() {
  final now = DateTime.now().toUtc();
  return SyncQueueEntry(
    id: 'entry-1',
    domain: 'schedule',
    operation: SyncOperationType.create,
    httpMethod: 'PUT',
    path: '/schedule/availability',
    payload: const {},
    queryParameters: const {},
    status: SyncQueueStatus.pending,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockRemoteTeacherAvailabilityRepository remote;
  late MockConnectivityService connectivity;
  late MockSyncService syncService;
  late Box<String> hiveBox;
  late TeacherAvailabilityCacheStore cacheStore;
  late SyncAwareTeacherAvailabilityRepository repo;

  setUpAll(() {
    registerFallbackValue(_fakeEntry());
    registerFallbackValue(_testAvailability());
  });

  setUp(() async {
    await setUpTestHive();
    hiveBox = await Hive.openBox<String>('teacher_avail_cache_test');

    remote = MockRemoteTeacherAvailabilityRepository();
    connectivity = MockConnectivityService();
    syncService = MockSyncService();
    cacheStore = TeacherAvailabilityCacheStore(box: hiveBox);

    repo = SyncAwareTeacherAvailabilityRepository(
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
  // getAvailability — read-through cache
  // --------------------------------------------------------------------------

  group('getAvailability — cache read-through', () {
    test('online success: result is written to cache', () async {
      final availability = _testAvailability();
      when(
        () => remote.getAvailability('teacher-1'),
      ).thenAnswer((_) async => availability);

      final result = await repo.getAvailability('teacher-1');
      expect(result, isNotNull);
      expect(result!.teacherId, equals('teacher-1'));

      final key = TeacherAvailabilityCacheStore.keyAvailability('teacher-1');
      expect(cacheStore.getAvailability(key), isNotNull);
      expect(cacheStore.getAvailability(key)!.teacherId, equals('teacher-1'));
    });

    test('online returns null (404): null is cached', () async {
      when(
        () => remote.getAvailability('teacher-new'),
      ).thenAnswer((_) async => null);

      final result = await repo.getAvailability('teacher-new');
      expect(result, isNull);

      // null cached — key exists in box with data: null
      final key = TeacherAvailabilityCacheStore.keyAvailability('teacher-new');
      final raw = hiveBox.get(key);
      expect(raw, isNotNull); // entry written
    });

    test(
      'NetworkException with cached data: returns cached availability',
      () async {
        final cached = _testAvailability(teacherId: 'teacher-1');
        final key = TeacherAvailabilityCacheStore.keyAvailability('teacher-1');
        await cacheStore.putAvailability(key, cached);

        when(
          () => remote.getAvailability('teacher-1'),
        ).thenThrow(const NetworkException(message: 'timeout'));

        final result = await repo.getAvailability('teacher-1');
        expect(result, isNotNull);
        expect(result!.teacherId, equals('teacher-1'));
      },
    );

    test('NetworkException with no cache: rethrows', () async {
      when(
        () => remote.getAvailability('teacher-x'),
      ).thenThrow(const NetworkException(message: 'no internet'));

      expect(
        () => repo.getAvailability('teacher-x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('ServerException with cached data: returns cached', () async {
      final cached = _testAvailability(teacherId: 'teacher-2');
      final key = TeacherAvailabilityCacheStore.keyAvailability('teacher-2');
      await cacheStore.putAvailability(key, cached);

      when(
        () => remote.getAvailability('teacher-2'),
      ).thenThrow(const ServerException(message: 'server error'));

      final result = await repo.getAvailability('teacher-2');
      expect(result!.teacherId, equals('teacher-2'));
    });

    test('NotFoundException (non-network) is NOT caught by cache', () async {
      final cached = _testAvailability();
      final key = TeacherAvailabilityCacheStore.keyAvailability('teacher-1');
      await cacheStore.putAvailability(key, cached);

      when(
        () => remote.getAvailability('teacher-1'),
      ).thenThrow(const NotFoundException(message: '404'));

      expect(
        () => repo.getAvailability('teacher-1'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  // --------------------------------------------------------------------------
  // Cache key isolation
  // --------------------------------------------------------------------------

  group('cache key isolation — different teacherIds', () {
    test('separate teachers produce separate cache entries', () async {
      final a1 = _testAvailability(teacherId: 'ta');
      final a2 = _testAvailability(teacherId: 'tb');

      when(() => remote.getAvailability('ta')).thenAnswer((_) async => a1);
      when(() => remote.getAvailability('tb')).thenAnswer((_) async => a2);

      await repo.getAvailability('ta');
      await repo.getAvailability('tb');

      expect(
        cacheStore
            .getAvailability(
              TeacherAvailabilityCacheStore.keyAvailability('ta'),
            )!
            .teacherId,
        equals('ta'),
      );
      expect(
        cacheStore
            .getAvailability(
              TeacherAvailabilityCacheStore.keyAvailability('tb'),
            )!
            .teacherId,
        equals('tb'),
      );
    });
  });

  // --------------------------------------------------------------------------
  // write→read integration (no read override)
  // --------------------------------------------------------------------------

  group('write→read integration (no read override)', () {
    test('online read then offline read returns same availability', () async {
      final availability = _testAvailability(teacherId: 'int-teacher');

      // Step 1: Online read writes to cache
      when(
        () => remote.getAvailability('int-teacher'),
      ).thenAnswer((_) async => availability);
      final online = await repo.getAvailability('int-teacher');
      expect(online!.teacherId, equals('int-teacher'));

      // Step 2: Subsequent offline read returns cached data
      when(
        () => remote.getAvailability('int-teacher'),
      ).thenThrow(const NetworkException(message: 'offline'));
      final offline = await repo.getAvailability('int-teacher');
      expect(offline!.teacherId, equals('int-teacher'));
    });
  });

  // --------------------------------------------------------------------------
  // TeacherAvailabilityCacheStore — raw JSON roundtrip
  // --------------------------------------------------------------------------

  group('TeacherAvailabilityCacheStore — raw JSON roundtrip', () {
    test('putAvailability / getAvailability roundtrip', () async {
      final availability = _testAvailability();
      await cacheStore.putAvailability('rt-key', availability);
      final retrieved = cacheStore.getAvailability('rt-key');
      expect(retrieved, isNotNull);
      expect(retrieved!.teacherId, equals('teacher-1'));
    });

    test('getAvailability on missing key returns null', () {
      expect(cacheStore.getAvailability('no-such-key'), isNull);
    });

    test('getAvailability on corrupt JSON returns null', () async {
      await hiveBox.put('corrupt', 'not-valid-json{{{');
      expect(cacheStore.getAvailability('corrupt'), isNull);
    });

    test('cachedAt field is present in stored JSON', () async {
      await cacheStore.putAvailability('ts-key', _testAvailability());
      final raw = hiveBox.get('ts-key')!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['cachedAt'], isA<String>());
    });

    test('putAvailability with null stores null data field', () async {
      await cacheStore.putAvailability('null-key', null);
      final raw = hiveBox.get('null-key')!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['data'], isNull);
      expect(cacheStore.getAvailability('null-key'), isNull);
    });
  });
}
