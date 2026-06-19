import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:lessonaza/features/subscription/data/local/subscription_cache_store.dart';
import 'package:lessonaza/features/subscription/data/repositories/remote_subscription_repository.dart';
import 'package:lessonaza/features/subscription/data/repositories/sync_aware_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_usage.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteSubscriptionRepository extends Mock
    implements RemoteSubscriptionRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

Subscription _testSubscription({String id = 'sub-1'}) {
  final now = DateTime(2026, 6, 1);
  return Subscription(
    id: id,
    studentId: 'student-1',
    membershipId: 'membership-1',
    type: SubscriptionType.package,
    totalLessons: 8,
    usedLessons: 2,
    startDate: now,
    endDate: now.add(const Duration(days: 30)),
    amount: 320000,
    status: SubscriptionStatus.active,
    createdAt: now,
    paymentConfirmed: true,
  );
}

SubscriptionUsage _testUsage({String id = 'usage-1'}) {
  final now = DateTime(2026, 6, 1);
  return SubscriptionUsage(
    id: id,
    subscriptionId: 'sub-1',
    lessonId: 'lesson-1',
    usedAt: now,
    createdAt: now,
    usageType: UsageType.normal,
    deducted: true,
  );
}

SyncQueueEntry _fakeEntry() {
  final now = DateTime.now().toUtc();
  return SyncQueueEntry(
    id: 'entry-1',
    domain: 'subscription',
    operation: SyncOperationType.create,
    httpMethod: 'POST',
    path: '/subscriptions',
    payload: const {},
    queryParameters: const {},
    status: SyncQueueStatus.pending,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockRemoteSubscriptionRepository remote;
  late MockConnectivityService connectivity;
  late MockSyncService syncService;
  late Box<String> hiveBox;
  late SubscriptionCacheStore cacheStore;
  late SyncAwareSubscriptionRepository repo;

  setUpAll(() {
    registerFallbackValue(_fakeEntry());
    registerFallbackValue(_testSubscription());
    registerFallbackValue(_testUsage());
  });

  setUp(() async {
    await setUpTestHive();
    hiveBox = await Hive.openBox<String>('subscription_cache_test');

    remote = MockRemoteSubscriptionRepository();
    connectivity = MockConnectivityService();
    syncService = MockSyncService();
    cacheStore = SubscriptionCacheStore(box: hiveBox);

    repo = SyncAwareSubscriptionRepository(
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

  // ─────────────────────────────────────────────────────────────────
  // getByStudentId
  // ─────────────────────────────────────────────────────────────────

  group('getByStudentId — cache read-through', () {
    test('online success: result is written to cache', () async {
      final subs = [_testSubscription()];
      when(
        () => remote.getByStudentId('student-1'),
      ).thenAnswer((_) async => subs);

      final result = await repo.getByStudentId('student-1');
      expect(result, equals(subs));

      final cached = cacheStore.getSubscriptions(
        SubscriptionCacheStore.keyStudent('student-1'),
      );
      expect(cached, isNotNull);
      expect(cached!.first.id, equals('sub-1'));
    });

    test('NetworkException with cached data: returns cached list', () async {
      final cached = [_testSubscription(id: 'cached-sub')];
      await cacheStore.putSubscriptions(
        SubscriptionCacheStore.keyStudent('student-1'),
        cached,
      );

      when(
        () => remote.getByStudentId('student-1'),
      ).thenThrow(const NetworkException(message: 'timeout'));

      final result = await repo.getByStudentId('student-1');
      expect(result.length, equals(1));
      expect(result.first.id, equals('cached-sub'));
    });

    test('NetworkException with no cache: rethrows', () async {
      when(
        () => remote.getByStudentId('student-x'),
      ).thenThrow(const NetworkException(message: 'no internet'));

      expect(
        () => repo.getByStudentId('student-x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('ServerException with cached data: returns cached list', () async {
      final cached = [_testSubscription(id: 'server-err-cached')];
      await cacheStore.putSubscriptions(
        SubscriptionCacheStore.keyStudent('student-1'),
        cached,
      );

      when(
        () => remote.getByStudentId('student-1'),
      ).thenThrow(const ServerException(message: '503'));

      final result = await repo.getByStudentId('student-1');
      expect(result.first.id, equals('server-err-cached'));
    });

    test(
      'non-network error (NotFoundException) is NOT caught by cache',
      () async {
        await cacheStore.putSubscriptions(
          SubscriptionCacheStore.keyStudent('student-1'),
          [_testSubscription()],
        );

        when(
          () => remote.getByStudentId('student-1'),
        ).thenThrow(const NotFoundException(message: '404'));

        expect(
          () => repo.getByStudentId('student-1'),
          throwsA(isA<NotFoundException>()),
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────
  // getById (nullable)
  // ─────────────────────────────────────────────────────────────────

  group('getById — nullable cache', () {
    test('online success: caches the subscription', () async {
      final sub = _testSubscription(id: 'sub-abc');
      when(() => remote.getById('sub-abc')).thenAnswer((_) async => sub);

      await repo.getById('sub-abc');

      final key = SubscriptionCacheStore.keySub('sub-abc');
      expect(cacheStore.getSubscription(key), isNotNull);
      expect(cacheStore.getSubscription(key)!.id, equals('sub-abc'));
    });

    test('NetworkException with cached value: returns cached', () async {
      final sub = _testSubscription(id: 'sub-cached');
      final key = SubscriptionCacheStore.keySub('sub-cached');
      await cacheStore.putSubscription(key, sub);

      when(
        () => remote.getById('sub-cached'),
      ).thenThrow(const NetworkException(message: 'offline'));

      final result = await repo.getById('sub-cached');
      expect(result, isNotNull);
      expect(result!.id, equals('sub-cached'));
    });

    test(
      'NetworkException with no cache: returns null (not rethrow)',
      () async {
        // _readNullableWithCache returns null (cache miss for nullable result)
        when(
          () => remote.getById('sub-missing'),
        ).thenThrow(const NetworkException(message: 'offline'));

        final result = await repo.getById('sub-missing');
        expect(result, isNull);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────
  // getExpiringSoon
  // ─────────────────────────────────────────────────────────────────

  group('getExpiringSoon — shared cache key', () {
    test('online success: caches with expiring_soon key', () async {
      final subs = [_testSubscription(id: 'expiring')];
      when(() => remote.getExpiringSoon()).thenAnswer((_) async => subs);

      await repo.getExpiringSoon();

      final cached = cacheStore.getSubscriptions(
        SubscriptionCacheStore.keyExpiringSoon(),
      );
      expect(cached, isNotNull);
      expect(cached!.first.id, equals('expiring'));
    });

    test('NetworkException returns cached expiring list', () async {
      final cached = [_testSubscription(id: 'expiring-cached')];
      await cacheStore.putSubscriptions(
        SubscriptionCacheStore.keyExpiringSoon(),
        cached,
      );

      when(
        () => remote.getExpiringSoon(),
      ).thenThrow(const NetworkException(message: 'no net'));

      final result = await repo.getExpiringSoon();
      expect(result.first.id, equals('expiring-cached'));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // getUsageHistory
  // ─────────────────────────────────────────────────────────────────

  group('getUsageHistory — SubscriptionUsage cache', () {
    test('online success: caches usage list', () async {
      final usages = [_testUsage()];
      when(
        () => remote.getUsageHistory('sub-1'),
      ).thenAnswer((_) async => usages);

      await repo.getUsageHistory('sub-1');

      final key = SubscriptionCacheStore.keyUsage('sub-1');
      final cached = cacheStore.getUsageHistory(key);
      expect(cached, isNotNull);
      expect(cached!.first.id, equals('usage-1'));
    });

    test('NetworkException returns cached usage list', () async {
      final cached = [_testUsage(id: 'usage-cached')];
      await cacheStore.putUsageHistory(
        SubscriptionCacheStore.keyUsage('sub-1'),
        cached,
      );

      when(
        () => remote.getUsageHistory('sub-1'),
      ).thenThrow(const NetworkException(message: 'offline'));

      final result = await repo.getUsageHistory('sub-1');
      expect(result.first.id, equals('usage-cached'));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Cache key isolation
  // ─────────────────────────────────────────────────────────────────

  group('cache key isolation', () {
    test(
      'different studentIds use separate cache keys and do not interfere',
      () async {
        final subsA = [_testSubscription(id: 'sub-a')];
        final subsB = [
          _testSubscription(id: 'sub-b1'),
          _testSubscription(id: 'sub-b2'),
        ];

        when(
          () => remote.getByStudentId('student-A'),
        ).thenAnswer((_) async => subsA);
        when(
          () => remote.getByStudentId('student-B'),
        ).thenAnswer((_) async => subsB);

        await repo.getByStudentId('student-A');
        await repo.getByStudentId('student-B');

        final cachedA = cacheStore.getSubscriptions(
          SubscriptionCacheStore.keyStudent('student-A'),
        );
        final cachedB = cacheStore.getSubscriptions(
          SubscriptionCacheStore.keyStudent('student-B'),
        );

        expect(cachedA!.length, equals(1));
        expect(cachedB!.length, equals(2));
        expect(cachedA.first.id, equals('sub-a'));
        expect(cachedB.first.id, equals('sub-b1'));
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────
  // Write → read integration
  // ─────────────────────────────────────────────────────────────────

  group('write → read integration', () {
    test(
      'online call populates cache; subsequent offline call returns it',
      () async {
        final subs = [_testSubscription(id: 'online-then-offline')];
        when(
          () => remote.getByStudentId('s-int'),
        ).thenAnswer((_) async => subs);

        // First call: online → writes to cache
        await repo.getByStudentId('s-int');

        // Now simulate offline
        when(
          () => remote.getByStudentId('s-int'),
        ).thenThrow(const NetworkException(message: 'no net'));

        // Second call: offline → cache hit
        final result = await repo.getByStudentId('s-int');
        expect(result.first.id, equals('online-then-offline'));
      },
    );
  });
}
