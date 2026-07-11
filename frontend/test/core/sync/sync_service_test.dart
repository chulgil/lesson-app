import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/sync_adapter_registry.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/data/sync_queue_store.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:mocktail/mocktail.dart';

class FakeConnectivity implements Connectivity {
  FakeConnectivity(ConnectivityResult initialState) : _state = [initialState];

  List<ConnectivityResult> _state;

  final StreamController<List<ConnectivityResult>> _streamController =
      StreamController<List<ConnectivityResult>>.broadcast();

  void setState(ConnectivityResult state, {bool emit = true}) {
    _state = [state];
    if (emit) {
      _streamController.add(_state);
    }
  }

  Future<void> close() async {
    await _streamController.close();
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return List<ConnectivityResult>.from(_state);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _streamController.stream;
}

class FakeApiClient extends Mock implements ApiClient {}

void main() {
  group('SyncService', () {
    late Directory tempDir;
    late SyncQueueStore store;
    FakeConnectivity? fakeConnectivity;
    late FakeApiClient apiClient;
    final services = <SyncService>[];

    Response<dynamic> makeApiResponse(String path) {
      return Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
      );
    }

    Future<SyncService> createService({
      ConnectivityResult initialConnectivity = ConnectivityResult.none,
      Duration pollingInterval = const Duration(seconds: 9999),
      int defaultMaxRetryCount = 5,
      Future<void> Function(String path)? invalidateCachedReads,
    }) async {
      fakeConnectivity = FakeConnectivity(initialConnectivity);

      final service = SyncService(
        queueStore: store,
        connectivityService: ConnectivityService(fakeConnectivity),
        adapterRegistry: SyncAdapterRegistry.create(),
        apiClient: apiClient,
        invalidateCachedReads: invalidateCachedReads,
        pollingInterval: pollingInterval,
        defaultMaxRetryCount: defaultMaxRetryCount,
      );

      services.add(service);
      await service.initialize();
      return service;
    }

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'lessonaza_sync_service_test_',
      );
      Hive.init(tempDir.path);
      store = SyncQueueStore(
        boxName: 'sync_queue_test',
        metaBoxName: 'sync_queue_meta_test',
      );
      apiClient = FakeApiClient();
      when(
        () => apiClient.post<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        return makeApiResponse(invocation.positionalArguments.first as String);
      });
    });

    tearDown(() async {
      for (final service in services.reversed) {
        await service.dispose();
      }
      services.clear();

      if (fakeConnectivity != null) {
        await fakeConnectivity!.close();
      }

      await store.close();
      await Hive.close();

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('오프라인에서 mutation은 pending 상태로 유지된다', () async {
      final service = await createService(
        initialConnectivity: ConnectivityResult.none,
        pollingInterval: const Duration(days: 1),
      );

      await service.queueMutation(
        domain: 'lesson',
        httpMethod: 'POST',
        path: '/offline-test',
        payload: {'case': 'offline'},
      );

      await service.syncPending();

      final entries = await store.fetchAll();
      expect(entries, hasLength(1));
      expect(entries.single.status, equals(SyncQueueStatus.pending));

      verifyNever(
        () => apiClient.post<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      );
    });

    test('온라인 복귀 시 큐가 자동 동기화된다', () async {
      final service = await createService(
        initialConnectivity: ConnectivityResult.none,
      );

      when(
        () => apiClient.post<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        return makeApiResponse(invocation.positionalArguments.first as String);
      });

      await service.queueMutation(
        domain: 'lesson',
        httpMethod: 'POST',
        path: '/reconnect-test',
        payload: {'case': 'reconnect'},
      );

      expect(await service.currentStats().then((stats) => stats.pending), 1);

      fakeConnectivity!.setState(ConnectivityResult.wifi);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      // cleanup() removes synced entries, so verify via API call count
      // and confirm the queue is empty (synced + cleaned up)
      final entries = await store.fetchAll();
      expect(
        entries.isEmpty || entries.single.status == SyncQueueStatus.synced,
        isTrue,
      );

      verify(
        () => apiClient.post<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('첫 동기화 실패 후 재시도하여 완료된다', () async {
      int attempt = 0;
      when(
        () => apiClient.post<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        attempt += 1;
        if (attempt == 1) {
          throw Exception('network unstable');
        }
        return makeApiResponse(invocation.positionalArguments.first as String);
      });

      final service = await createService(
        initialConnectivity: ConnectivityResult.none,
      );

      await service.queueMutation(
        domain: 'lesson',
        httpMethod: 'POST',
        path: '/retry-test',
        payload: {'case': 'retry'},
      );

      fakeConnectivity!.setState(ConnectivityResult.wifi, emit: false);

      await service.syncPending();
      final first = await store.fetchAll();
      expect(first.single.status, equals(SyncQueueStatus.pending));
      expect(first.single.retryCount, equals(1));

      // Wait for backoff period (1 second for retryCount=1) before retrying
      await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

      await service.syncPending();
      final second = await store.fetchAll();
      // cleanup() may remove synced entries, so check either synced or empty
      if (second.isNotEmpty) {
        expect(second.single.status, equals(SyncQueueStatus.synced));
        expect(second.single.retryCount, equals(0));
        expect(second.single.errorCode, isNull);
      }
      expect(attempt, equals(2));
    });

    test('지원하지 않는 도메인은 NO_ADAPTER 실패 처리된다', () async {
      final service = await createService(
        initialConnectivity: ConnectivityResult.wifi,
      );

      await service.queueMutation(
        domain: 'unsupported-domain',
        httpMethod: 'POST',
        path: '/bad-domain',
        payload: {'case': 'bad-domain'},
      );

      await service.syncPending();
      final entries = await store.fetchAll();
      expect(entries.single.status, equals(SyncQueueStatus.failed));
      expect(entries.single.errorCode, equals('NO_ADAPTER'));
      expect(
        entries.single.errorMessage,
        contains('No sync adapter found for domain: unsupported-domain'),
      );

      verifyNever(
        () => apiClient.post<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      );
    });

    test('dispose 직후 connectivity 이벤트가 와도 통계 스트림 add 오류를 발생시키지 않는다', () async {
      final errors = <Object>[];
      await runZonedGuarded(
        () async {
          final service = await createService(
            initialConnectivity: ConnectivityResult.none,
            pollingInterval: const Duration(milliseconds: 1),
          );

          when(
            () => apiClient.post<dynamic>(
              any(),
              data: any(named: 'data'),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            ),
          ).thenAnswer((invocation) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return makeApiResponse(
              invocation.positionalArguments.first as String,
            );
          });

          await service.queueMutation(
            domain: 'lesson',
            httpMethod: 'POST',
            path: '/dispose-safe-test',
            payload: {'case': 'dispose-safe'},
          );

          fakeConnectivity!.setState(ConnectivityResult.wifi);
          await service.dispose();
        },
        (error, stack) {
          errors.add(error);
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(errors, isEmpty);
    });

    test('지수 백오프: retryCount 증가하면 재시도 지연이 증가한다', () async {
      when(
        () => apiClient.post<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(Exception('persistent failure'));

      final service = await createService(
        initialConnectivity: ConnectivityResult.wifi,
        pollingInterval: const Duration(days: 1),
      );

      // 첫 시도: 0초 지연 (retryCount=0)
      await service.queueMutation(
        domain: 'lesson',
        httpMethod: 'POST',
        path: '/backoff-test',
        payload: {'case': 'backoff'},
      );

      // 첫 번째 실패
      await service.syncPending();
      var entries = await store.fetchAll();
      expect(entries.single.retryCount, equals(1));
      expect(entries.single.status, equals(SyncQueueStatus.pending));

      // retryCount=1이므로 1초 백오프 필요 → 즉시 재시도 불가
      await service.syncPending();
      entries = await store.fetchAll();
      expect(entries.single.retryCount, equals(1)); // 변화 없음

      // 1초 이상 경과 후 재시도 → retryCount=2로 증가, 2초 백오프 필요
      await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));
      await service.syncPending();
      entries = await store.fetchAll();
      expect(entries.single.retryCount, equals(2));

      // retryCount=2 → 2초 백오프, 즉시 재시도 불가
      await service.syncPending();
      entries = await store.fetchAll();
      expect(entries.single.retryCount, equals(2));

      // 2초 이상 경과 후 재시도 → retryCount=3으로 증가, 4초 백오프 필요
      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));
      await service.syncPending();
      entries = await store.fetchAll();
      expect(entries.single.retryCount, equals(3));

      // retryCount 증가로 백오프 지연이 지수 증가함을 검증
      verify(
        () => apiClient.post<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).called(greaterThanOrEqualTo(3));
    });

    test('큐 적재 시 invalidateCachedReads 콜백이 경로와 함께 호출된다 (N7)', () async {
      final invalidated = <String>[];
      final service = await createService(
        initialConnectivity: ConnectivityResult.none,
        pollingInterval: const Duration(days: 1),
        invalidateCachedReads: (path) async => invalidated.add(path),
      );

      await service.queueMutation(
        domain: 'lesson',
        httpMethod: 'POST',
        path: '/lessons',
        payload: const {'x': 1},
      );

      expect(invalidated, ['/lessons']);
    });

    test(
      '#1119 LWW 거절(CONFLICT_LWW_REJECTED) → 즉시 terminal failed + errorCode 보존 + rejection 이벤트',
      () async {
        final service = await createService(
          initialConnectivity: ConnectivityResult.none,
          pollingInterval: const Duration(days: 1),
        );

        when(
          () => apiClient.put<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          const ApiException(
            message: '충돌',
            statusCode: 412,
            data: {
              'error': {'code': 'CONFLICT_LWW_REJECTED'},
            },
          ),
        );

        final events = <SyncRejectionEvent>[];
        final sub = service.rejectionStream.listen(events.add);
        addTearDown(sub.cancel);

        // Enqueue while offline so it stays pending, then go online and flush.
        await service.queueMutation(
          domain: 'practice',
          httpMethod: 'PUT',
          path: '/practice-logs/1',
          payload: const {'x': 1},
          clientUpdatedAt: DateTime.utc(2026, 6, 1),
        );

        fakeConnectivity!.setState(ConnectivityResult.wifi, emit: false);
        await service.syncPending();
        // Let the broadcast rejection event reach the listener.
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final entry = (await store.fetchAll()).single;
        expect(entry.status, SyncQueueStatus.failed);
        expect(entry.errorCode, 'CONFLICT_LWW_REJECTED');
        // Terminal: retries are pointless (the write is deterministically stale).
        expect(entry.retryCount, entry.maxRetryCount);
        expect(events, hasLength(1));
        expect(events.single.code, 'CONFLICT_LWW_REJECTED');
        expect(events.single.domain, 'practice');

        // Only one attempt — no retry storm on a deterministic rejection.
        verify(
          () => apiClient.put<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).called(1);
      },
    );

    test(
      '#1120 failedEntries / deleteEntry / retryEntry (terminal 재전송 동의)',
      () async {
        final service = await createService(
          initialConnectivity: ConnectivityResult.none,
          pollingInterval: const Duration(days: 1),
        );

        final now = DateTime.now().toUtc();
        SyncQueueEntry terminalFailed() => SyncQueueEntry(
          id: 'f1',
          domain: 'practice',
          operation: SyncOperationType.update,
          httpMethod: 'PUT',
          path: '/practice-logs/1',
          payload: const {},
          status: SyncQueueStatus.failed,
          createdAt: now,
          updatedAt: now,
          retryCount: 5,
          maxRetryCount: 5,
          errorCode: 'CONFLICT_LWW_REJECTED',
          errorMessage: 'stale',
        );

        await store.upsert(terminalFailed());
        expect(await service.failedEntries(), hasLength(1));

        await service.deleteEntry('f1');
        expect(await service.failedEntries(), isEmpty);

        // Retry resets a terminal entry to pending with a fresh retry budget —
        // the user's tap IS the explicit consent to re-send.
        await store.upsert(terminalFailed());
        await service.retryEntry('f1');

        final retried = await store.getById('f1');
        expect(retried, isNotNull);
        expect(retried!.status, SyncQueueStatus.pending);
        expect(retried.retryCount, 0);
        expect(retried.errorCode, isNull);
      },
    );
  });
}
