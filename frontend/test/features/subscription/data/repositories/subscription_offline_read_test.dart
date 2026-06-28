import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/network/cache/response_cache_policy.dart';
import 'package:lessonaza/core/network/cache/response_cache_store.dart';
import 'package:lessonaza/core/network/interceptors/response_cache_interceptor.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/features/subscription/data/repositories/remote_subscription_repository.dart';
import 'package:lessonaza/features/subscription/data/repositories/sync_aware_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:mocktail/mocktail.dart';

/// Batch 1d (일원화) end-to-end: the subscriptions stack — SyncAware (no own
/// cache) → Remote → ApiClient + ResponseCacheInterceptor — serves
/// last-known-good data offline via the single HTTP response cache
/// (offline-first plan §3 / §5). Uses the single-object `getById` endpoint
/// (`GET /subscriptions/$id`) so the fake adapter body is one Subscription.

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

enum _Mode { online, offline }

class _FakeAdapter implements HttpClientAdapter {
  _Mode mode = _Mode.online;
  String body = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (mode == _Mode.offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Subscription _subscription({String id = 'sub-1'}) => Subscription(
  id: id,
  studentId: 'student-1',
  membershipId: 'membership-1',
  type: SubscriptionType.package,
  totalLessons: 8,
  usedLessons: 2,
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 7, 1),
  amount: 320000,
  status: SubscriptionStatus.active,
  createdAt: DateTime(2026, 6, 1),
);

String _single(Subscription subscription) => jsonEncode(subscription.toJson());

void main() {
  late _FakeAdapter adapter;
  late Box<String> box;
  late SyncAwareSubscriptionRepository repo;

  setUp(() async {
    await setUpTestHive();
    box = await Hive.openBox<String>(ResponseCacheStore.boxName);

    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      ResponseCacheInterceptor(
        store: ResponseCacheStore(box: box),
        policy: ResponseCachePolicy.active,
      ),
    );

    repo = SyncAwareSubscriptionRepository(
      remote: RemoteSubscriptionRepository(ApiClient(dio)),
      queue: MutationQueueHelper(
        connectivity: MockConnectivityService(),
        syncService: MockSyncService(),
      ),
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  test('online read populates the HTTP cache and returns data', () async {
    adapter
      ..mode = _Mode.online
      ..body = _single(_subscription(id: 'online-1'));

    final result = await repo.getById('online-1');

    expect(result?.id, equals('online-1'));
    expect(
      box.get('GET /subscriptions/online-1'),
      isNotNull,
      reason: 'cached by interceptor',
    );
  });

  test(
    'offline read after a prior online read returns cached subscription',
    () async {
      // Prime online.
      adapter
        ..mode = _Mode.online
        ..body = _single(_subscription(id: 'last-known-good'));
      await repo.getById('last-known-good');

      // Go offline — no SyncAware cache exists; HTTP interceptor must serve.
      adapter.mode = _Mode.offline;
      final offline = await repo.getById('last-known-good');

      expect(offline?.id, equals('last-known-good'));
    },
  );

  test(
    'offline read with no prior cache propagates the network error',
    () async {
      adapter.mode = _Mode.offline;
      expect(() => repo.getById('sub-x'), throwsA(isA<ApiException>()));
    },
  );
}
