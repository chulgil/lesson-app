import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/sync_adapter_registry.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/data/sync_queue_store.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:mocktail/mocktail.dart';

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity(this._state);
  final ConnectivityResult _state;
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [_state];
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

class _FakeApiClient extends Mock implements ApiClient {}

void main() {
  late Directory tempDir;
  late SyncQueueStore store;
  late _FakeApiClient apiClient;
  final services = <SyncService>[];

  SyncQueueEntry orphan({
    required String id,
    required String method,
    String? idempotencyKey,
    String domain = 'lesson',
  }) {
    final now = DateTime.now().toUtc();
    return SyncQueueEntry(
      id: id,
      domain: domain,
      operation: SyncOperationType.custom,
      httpMethod: method,
      path: '/$id',
      payload: const {},
      status: SyncQueueStatus.syncing, // left over by an app kill mid-replay
      createdAt: now,
      updatedAt: now,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<SyncService> startService(ConnectivityResult connectivity) async {
    final service = SyncService(
      queueStore: store,
      connectivityService: ConnectivityService(_FakeConnectivity(connectivity)),
      adapterRegistry: SyncAdapterRegistry.create(),
      apiClient: apiClient,
      pollingInterval: const Duration(days: 1),
    );
    services.add(service);
    await service.initialize();
    return service;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lessonaza_orphan_test_');
    Hive.init(tempDir.path);
    store = SyncQueueStore(
      boxName: 'sync_queue_test',
      metaBoxName: 'sync_queue_meta_test',
    );
    apiClient = _FakeApiClient();
    when(
      () => apiClient.post<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (invocation) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: invocation.positionalArguments.first as String,
        ),
        statusCode: 200,
      ),
    );
  });

  tearDown(() async {
    for (final service in services.reversed) {
      await service.dispose();
    }
    services.clear();
    await store.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<SyncQueueStatus?> statusOf(String id) async {
    final entry = await store.getById(id);
    return entry?.status;
  }

  group('orphaned syncing recovery (#1162)', () {
    test('recovery matrix — key/method decides pending vs failed', () async {
      await store.upsert(
        orphan(id: 'post-key', method: 'POST', idempotencyKey: 'k'),
      );
      await store.upsert(orphan(id: 'post-nokey', method: 'POST'));
      await store.upsert(orphan(id: 'put-nokey', method: 'PUT'));
      await store.upsert(orphan(id: 'delete-nokey', method: 'DELETE'));
      await store.upsert(orphan(id: 'patch-nokey', method: 'PATCH'));

      // Offline so recovery runs but no replay is attempted.
      await startService(ConnectivityResult.none);

      // has key → safe to replay
      expect(await statusOf('post-key'), SyncQueueStatus.pending);
      // no key, naturally idempotent methods → safe to replay
      expect(await statusOf('put-nokey'), SyncQueueStatus.pending);
      expect(await statusOf('delete-nokey'), SyncQueueStatus.pending);
      expect(await statusOf('patch-nokey'), SyncQueueStatus.pending);
      // no key + POST → unsafe, surfaced as failed (not dropped, not replayed)
      expect(await statusOf('post-nokey'), SyncQueueStatus.failed);
      final failed = await store.getById('post-nokey');
      expect(failed!.errorCode, SyncService.orphanedUnsafeReplayCode);
    });

    test('recovered key POST keeps its idempotency key for replay', () async {
      await store.upsert(
        orphan(id: 'post-key', method: 'POST', idempotencyKey: 'keep-me'),
      );

      await startService(ConnectivityResult.none);

      final recovered = await store.getById('post-key');
      expect(recovered!.status, SyncQueueStatus.pending);
      expect(recovered.idempotencyKey, 'keep-me');
    });

    test('POST orphan without a key is never re-sent when online', () async {
      await store.upsert(orphan(id: 'post-nokey', method: 'POST'));

      await startService(ConnectivityResult.wifi);

      // Recovery marked it failed → the flush must never replay it.
      verifyNever(
        () => apiClient.post<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      );
      expect(await statusOf('post-nokey'), SyncQueueStatus.failed);
    });
  });
}
