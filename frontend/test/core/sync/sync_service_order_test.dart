// S3 (audit 2026-07-10) — dependency order across a flush pass.
//
// Writes to one domain are causally ordered (create → update → delete). When
// the create is still waiting on its retry backoff, the later update must NOT
// be replayed first: the server row does not exist yet, so the update 404s,
// burns its retries and the write is lost (#1115-class silent loss).

import 'dart:async';
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

  final List<ConnectivityResult> _state;
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  Future<void> close() async => _controller.close();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      List<ConnectivityResult>.from(_state);

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeApiClient extends Mock implements ApiClient {}

void main() {
  late Directory tempDir;
  late SyncQueueStore store;
  late _FakeApiClient apiClient;
  late _FakeConnectivity connectivity;
  final services = <SyncService>[];

  Response<dynamic> ok(String path) => Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lessonaza_sync_order_');
    Hive.init(tempDir.path);
    store = SyncQueueStore(
      boxName: 'sync_queue_order_test',
      metaBoxName: 'sync_queue_order_meta_test',
    );
    apiClient = _FakeApiClient();
    connectivity = _FakeConnectivity([ConnectivityResult.wifi]);

    // create (POST) always fails → stays pending in backoff.
    when(
      () => apiClient.post<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenThrow(Exception('create failed'));

    // update (PUT) would succeed if it were ever attempted.
    when(
      () => apiClient.put<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((i) async => ok(i.positionalArguments.first as String));
  });

  tearDown(() async {
    for (final s in services.reversed) {
      await s.dispose();
    }
    services.clear();
    await connectivity.close();
    await store.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// `queueMutation` kicks off a background flush (`unawaited(syncPending())`),
  /// so wait for it to finish before asserting on queue state.
  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Future<SyncService> createService() async {
    final service = SyncService(
      queueStore: store,
      connectivityService: ConnectivityService(connectivity),
      adapterRegistry: SyncAdapterRegistry.create(),
      apiClient: apiClient,
      pollingInterval: const Duration(days: 1),
    );
    services.add(service);
    await service.initialize();
    return service;
  }

  test('create 가 백오프 대기 중이면 같은 도메인의 update 를 앞질러 보내지 않는다', () async {
    final service = await createService();

    await service.queueMutation(
      domain: 'lesson',
      httpMethod: 'POST',
      path: '/lessons',
      payload: {'title': 'new'},
    );
    await service.queueMutation(
      domain: 'lesson',
      httpMethod: 'PUT',
      path: '/lessons/tmp_1',
      payload: {'title': 'edited'},
    );

    // Pass 1 (the background flush queueMutation started): create fails →
    // pending with retryCount=1 (backoff starts).
    await settle();

    final entries = await store.fetchAll();
    final create = entries.firstWhere((e) => e.httpMethod == 'POST');
    final update = entries.firstWhere((e) => e.httpMethod == 'PUT');
    expect(create.retryCount, 1);
    expect(create.status, SyncQueueStatus.pending);

    verifyNever(
      () => apiClient.put<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    );
    expect(
      update.status,
      SyncQueueStatus.pending,
      reason: 'create 가 미전송인데 update 가 먼저 나가면 서버에 행이 없어 404 (S3)',
    );

    // Pass 2: create still inside its 1s backoff → update must keep waiting.
    await service.syncPending();
    await settle();
    verifyNever(
      () => apiClient.put<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    );
  });

  test('다른 도메인의 쓰기는 막힌 도메인 때문에 지연되지 않는다', () async {
    final service = await createService();

    await service.queueMutation(
      domain: 'lesson',
      httpMethod: 'POST',
      path: '/lessons',
      payload: {'title': 'new'},
    );
    await service.queueMutation(
      domain: 'student',
      httpMethod: 'PUT',
      path: '/students/s1',
      payload: {'name': 'edited'},
    );

    await settle();

    // The student write went out even though the lesson domain is blocked.
    // (Synced entries are removed by `cleanup()`, so assert on the call.)
    verify(
      () => apiClient.put<dynamic>(
        '/students/s1',
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).called(1);

    final remaining = await store.fetchAll();
    expect(
      remaining.where((e) => e.domain == 'student'),
      isEmpty,
      reason: '도메인 경계를 넘어 head-of-line blocking 이 생기면 안 됨',
    );
  });
}
