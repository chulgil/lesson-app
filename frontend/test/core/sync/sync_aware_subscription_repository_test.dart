import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
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
  return Subscription(
    id: id,
    membershipId: 'mem-1',
    studentId: 'student-1',
    type: SubscriptionType.package,
    totalLessons: 4,
    usedLessons: 1,
    amount: 200000,
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 6, 1),
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 5, 1),
  );
}

SubscriptionUsage _testUsage() {
  return SubscriptionUsage(
    id: 'usage-1',
    subscriptionId: 'sub-1',
    usedAt: DateTime(2026, 5, 9),
    createdAt: DateTime(2026, 5, 9),
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
  late SyncAwareSubscriptionRepository repo;

  setUp(() {
    remote = MockRemoteSubscriptionRepository();
    connectivity = MockConnectivityService();
    syncService = MockSyncService();

    repo = SyncAwareSubscriptionRepository(
      remote: remote,
      queue: MutationQueueHelper(
        connectivity: connectivity,
        syncService: syncService,
      ),
    );
  });

  setUpAll(() {
    registerFallbackValue(_fakeEntry());
    registerFallbackValue(_testSubscription());
    registerFallbackValue(_testUsage());
    registerFallbackValue(SubscriptionStatus.active);
    registerFallbackValue(SubscriptionPaymentMethod.bankTransfer);
  });

  group('read methods delegate to remote', () {
    test('getByStudentId', () async {
      when(
        () => remote.getByStudentId('s1'),
      ).thenAnswer((_) async => [_testSubscription()]);

      final result = await repo.getByStudentId('s1');
      expect(result, hasLength(1));
      verify(() => remote.getByStudentId('s1')).called(1);
    });

    test('getById', () async {
      final sub = _testSubscription();
      when(() => remote.getById('sub-1')).thenAnswer((_) async => sub);

      final result = await repo.getById('sub-1');
      expect(result?.id, equals('sub-1'));
    });

    test('watchByStudentId delegates to remote', () {
      when(
        () => remote.watchByStudentId('s1'),
      ).thenAnswer((_) => Stream.value([_testSubscription()]));

      final stream = repo.watchByStudentId('s1');
      expect(stream, isA<Stream<List<Subscription>>>());
      verify(() => remote.watchByStudentId('s1')).called(1);
    });
  });

  group('create', () {
    test('online: returns server entity', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      final sub = _testSubscription(id: 'new');
      final serverSub = _testSubscription(id: 'server-id');
      when(() => remote.create(sub)).thenAnswer((_) async => serverSub);

      final result = await repo.create(sub);
      expect(result.id, equals('server-id'));
    });

    test(
      'NetworkException: rethrows — issuance is online-required (#1248)',
      () async {
        // A queued create used to fabricate a tmp_ id that downstream direct-
        // HTTP steps (confirmPayment, orphan cleanup) ran against, leaving the
        // replayed real subscription an orphan. The contract is now fail-fast.
        when(
          () => remote.create(any()),
        ).thenThrow(const NetworkException(message: 'timeout'));

        await expectLater(
          () async => repo.create(_testSubscription()),
          throwsA(isA<NetworkException>()),
        );
        verifyNever(
          () => syncService.queueMutation(
            idempotencyKey: any(named: 'idempotencyKey'),
            domain: any(named: 'domain'),
            httpMethod: any(named: 'httpMethod'),
            path: any(named: 'path'),
            payload: any(named: 'payload'),
          ),
        );
      },
    );
  });

  group('update', () {
    test('offline: returns input subscription', () async {
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

      final sub = _testSubscription();
      final result = await repo.update(sub);
      expect(result.id, equals('sub-1'));
    });
  });

  group('updateStatus', () {
    test('offline: queues PATCH with status', () async {
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

      await repo.updateStatus('sub-1', SubscriptionStatus.paused);
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'subscription',
          httpMethod: 'PATCH',
          path: '/subscriptions/sub-1/status',
          payload: {'status': 'paused'},
        ),
      ).called(1);
    });
  });

  group('online-only methods', () {
    test('useLesson delegates to remote', () async {
      final sub = _testSubscription();
      when(
        () => remote.useLesson(
          'sub-1',
          lessonId: any(named: 'lessonId'),
          teacherName: any(named: 'teacherName'),
          instrument: any(named: 'instrument'),
        ),
      ).thenAnswer((_) async => sub);

      final result = await repo.useLesson(
        'sub-1',
        lessonId: 'l1',
        instrument: 'violin',
      );
      expect(result.id, equals('sub-1'));
    });

    test('useReschedule delegates to remote', () async {
      final sub = _testSubscription();
      when(() => remote.useReschedule('sub-1')).thenAnswer((_) async => sub);

      final result = await repo.useReschedule('sub-1');
      expect(result.id, equals('sub-1'));
    });

    test('confirmPayment delegates to remote', () async {
      final sub = _testSubscription();
      when(
        () => remote.confirmPayment(
          'sub-1',
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer((_) async => sub);

      final result = await repo.confirmPayment(
        'sub-1',
        paymentMethod: SubscriptionPaymentMethod.bankTransfer,
      );
      expect(result.id, equals('sub-1'));
    });
  });

  group('addUsage', () {
    test('offline: queues and returns optimistic usage', () async {
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

      final usage = _testUsage();
      final result = await repo.addUsage(usage);
      expect(result.id, equals('usage-1'));
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'subscription',
          httpMethod: 'POST',
          path: '/subscriptions/sub-1/usage',
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });
}
