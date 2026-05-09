import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockConnectivityService connectivity;
  late MockSyncService syncService;
  late MutationQueueHelper helper;

  setUp(() {
    connectivity = MockConnectivityService();
    syncService = MockSyncService();
    helper = MutationQueueHelper(
      connectivity: connectivity,
      syncService: syncService,
    );
  });

  SyncQueueEntry _fakeEntry() {
    final now = DateTime.now().toUtc();
    return SyncQueueEntry(
      id: 'test-id',
      domain: 'test',
      operation: SyncOperationType.create,
      httpMethod: 'POST',
      path: '/test',
      payload: const {},
      queryParameters: const {},
      status: SyncQueueStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('executeMutation', () {
    test('online: calls remoteCall and returns its result', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      final result = await helper.executeMutation<String>(
        remoteCall: () async => 'server-result',
        queueCall: (_) async {},
        optimisticResult: () => 'optimistic',
      );

      expect(result, equals('server-result'));
      verifyNever(
        () => syncService.queueMutation(
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('offline: calls queueCall and returns optimistic result', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => syncService.queueMutation(
          domain: any(named: 'domain'),
          httpMethod: any(named: 'httpMethod'),
          path: any(named: 'path'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => _fakeEntry());

      var queueCallInvoked = false;
      final result = await helper.executeMutation<String>(
        remoteCall: () async => throw StateError('should not be called'),
        queueCall: (svc) async {
          queueCallInvoked = true;
          await svc.queueMutation(
            domain: 'test',
            httpMethod: 'POST',
            path: '/test',
            payload: const {},
          );
        },
        optimisticResult: () => 'optimistic',
      );

      expect(result, equals('optimistic'));
      expect(queueCallInvoked, isTrue);
    });

    test('online but NetworkException: falls back to queue', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      var queueCallInvoked = false;
      final result = await helper.executeMutation<String>(
        remoteCall: () async =>
            throw const NetworkException(message: 'no network'),
        queueCall: (_) async {
          queueCallInvoked = true;
        },
        optimisticResult: () => 'optimistic',
      );

      expect(result, equals('optimistic'));
      expect(queueCallInvoked, isTrue);
    });

    test('online but ServerException (500): falls back to queue', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      var queueCallInvoked = false;
      final result = await helper.executeMutation<String>(
        remoteCall: () async =>
            throw const ServerException(message: 'internal error'),
        queueCall: (_) async {
          queueCallInvoked = true;
        },
        optimisticResult: () => 'optimistic',
      );

      expect(result, equals('optimistic'));
      expect(queueCallInvoked, isTrue);
    });

    test('online but ApiException 400: propagates (no queue)', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      expect(
        () => helper.executeMutation<String>(
          remoteCall: () async => throw const ApiException(
            message: 'bad request',
            statusCode: 400,
          ),
          queueCall: (_) async {
            fail('queueCall should not be called for 4xx');
          },
          optimisticResult: () => 'optimistic',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('online but ValidationException (422): propagates (no queue)',
        () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      expect(
        () => helper.executeMutation<String>(
          remoteCall: () async => throw const ValidationException(),
          queueCall: (_) async {
            fail('queueCall should not be called');
          },
          optimisticResult: () => 'optimistic',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('executeVoidMutation', () {
    test('online: calls remoteCall, completes normally', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      var remoteCalled = false;
      await helper.executeVoidMutation(
        remoteCall: () async {
          remoteCalled = true;
        },
        queueCall: (_) async {},
      );

      expect(remoteCalled, isTrue);
    });

    test('offline: calls queueCall, completes normally', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      var queueCallInvoked = false;
      await helper.executeVoidMutation(
        remoteCall: () async => throw StateError('should not be called'),
        queueCall: (_) async {
          queueCallInvoked = true;
        },
      );

      expect(queueCallInvoked, isTrue);
    });

    test('online but NetworkException: falls back to queue', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      var queueCallInvoked = false;
      await helper.executeVoidMutation(
        remoteCall: () async =>
            throw const NetworkException(message: 'timeout'),
        queueCall: (_) async {
          queueCallInvoked = true;
        },
      );

      expect(queueCallInvoked, isTrue);
    });
  });
}
