import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/network/cache/response_cache_policy.dart';
import 'package:lessonaza/core/network/cache/response_cache_store.dart';
import 'package:lessonaza/core/network/interceptors/response_cache_interceptor.dart';

enum _Mode { success, networkError, serverError }

/// Fake adapter that returns canned responses or throws a transport error,
/// switchable per test to drive the interceptor through a real Dio chain.
class _FakeAdapter implements HttpClientAdapter {
  _Mode mode = _Mode.success;
  Map<String, dynamic> body = const {'ok': true};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    switch (mode) {
      case _Mode.success:
        return ResponseBody.fromString(
          jsonEncode(body),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      case _Mode.serverError:
        return ResponseBody.fromString(
          jsonEncode({'detail': 'boom'}),
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      case _Mode.networkError:
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
    }
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Box<String> box;
  late ResponseCacheStore store;
  late _FakeAdapter adapter;

  Dio buildDio(ResponseCachePolicy policy) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      ResponseCacheInterceptor(store: store, policy: policy),
    );
    return dio;
  }

  setUp(() async {
    await setUpTestHive();
    box = await Hive.openBox<String>('response_cache_itc_test');
    store = ResponseCacheStore(box: box);
    adapter = _FakeAdapter();
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  const allowlisted = ResponseCachePolicy(allowlist: {'/lessons'});
  const empty = ResponseCachePolicy();

  group('caching (allowlisted GET)', () {
    test('successful GET response is cached', () async {
      final dio = buildDio(allowlisted);
      adapter.mode = _Mode.success;

      final res = await dio.get<dynamic>('/lessons');
      expect(res.statusCode, equals(200));

      final key = ResponseCacheStore.buildKey(method: 'GET', path: '/lessons');
      final cached = store.get(key);
      expect(cached, isNotNull);
      expect(cached!.statusCode, equals(200));
      expect(cached.data, equals({'ok': true}));
    });
  });

  group('serving (allowlisted GET, network failure)', () {
    test('cache hit → resolves with cached data + fromCache flag', () async {
      final dio = buildDio(allowlisted);

      // Prime the cache with a successful response.
      adapter.mode = _Mode.success;
      adapter.body = const {'value': 'last-known-good'};
      await dio.get<dynamic>('/lessons');

      // Now go offline.
      adapter.mode = _Mode.networkError;
      final res = await dio.get<dynamic>('/lessons');

      expect(res.data, equals({'value': 'last-known-good'}));
      expect(res.extra['fromCache'], isTrue);
    });

    test('cache miss → error propagates', () async {
      final dio = buildDio(allowlisted);
      adapter.mode = _Mode.networkError;

      expect(() => dio.get<dynamic>('/lessons'), throwsA(isA<DioException>()));
    });
  });

  group('batch-0 no-op (empty allowlist)', () {
    test('non-allowlisted success is NOT cached', () async {
      final dio = buildDio(empty);
      adapter.mode = _Mode.success;

      await dio.get<dynamic>('/lessons');

      expect(store.length, equals(0));
    });

    test('non-allowlisted network error is NOT served from cache', () async {
      final dio = buildDio(empty);

      // Pre-seed a cache entry for this exact key.
      final key = ResponseCacheStore.buildKey(method: 'GET', path: '/lessons');
      await store.put(key, statusCode: 200, data: {'stale': true});

      adapter.mode = _Mode.networkError;
      expect(() => dio.get<dynamic>('/lessons'), throwsA(isA<DioException>()));
    });
  });

  group('exclusions', () {
    test('non-GET (POST) is not cached', () async {
      final dio = buildDio(allowlisted);
      adapter.mode = _Mode.success;

      await dio.post<dynamic>('/lessons', data: {'x': 1});

      expect(store.length, equals(0));
    });

    test(
      '5xx business error is NOT served from cache (transport-only)',
      () async {
        final dio = buildDio(allowlisted);

        // Prime cache.
        adapter.mode = _Mode.success;
        await dio.get<dynamic>('/lessons');

        // Server returns 500 — must propagate, not serve stale cache.
        adapter.mode = _Mode.serverError;
        expect(
          () => dio.get<dynamic>('/lessons'),
          throwsA(isA<DioException>()),
        );
      },
    );
  });
  group('write-invalidation (N7)', () {
    test('successful POST drops the domain cached reads', () async {
      final dio = buildDio(allowlisted);
      adapter.mode = _Mode.success;
      await dio.get<dynamic>('/lessons');
      await dio.get<dynamic>('/lessons/42');
      expect(store.length, equals(2));

      await dio.post<dynamic>('/lessons/42/complete', data: {'x': 1});

      expect(store.length, equals(0));
    });

    test('write to a non-allowlisted path leaves the cache untouched',
        () async {
      final dio = buildDio(allowlisted);
      adapter.mode = _Mode.success;
      await dio.get<dynamic>('/lessons');
      expect(store.length, equals(1));

      await dio.post<dynamic>('/bookings', data: {'x': 1});

      expect(store.length, equals(1));
    });

    test('offline read right after an online write propagates the error '
        'instead of serving pre-write stale data', () async {
      final dio = buildDio(allowlisted);
      adapter.mode = _Mode.success;
      await dio.get<dynamic>('/lessons');
      await dio.post<dynamic>('/lessons', data: {'x': 1});

      adapter.mode = _Mode.networkError;
      await expectLater(
        dio.get<dynamic>('/lessons'),
        throwsA(isA<DioException>()),
      );
    });
  });
  group('sensitive TTL (N15 / offline plan D3)', () {
    Future<void> seedAged(String key, Duration age) async {
      await box.put(
        key,
        jsonEncode({
          'cachedAt':
              DateTime.now().toUtc().subtract(age).toIso8601String(),
          'statusCode': 200,
          'data': {'stale': true},
        }),
      );
    }

    const sensitivePolicy = ResponseCachePolicy(
      allowlist: {'/subscriptions'},
      sensitivePrefixes: {'/subscriptions/payment-pending'},
      sensitiveTtl: Duration(minutes: 15),
    );

    test('display-only domains have no TTL — 30-day-old entry still serves',
        () async {
      final dio = buildDio(allowlisted);
      await seedAged('GET /lessons', const Duration(days: 30));

      adapter.mode = _Mode.networkError;
      final res = await dio.get<dynamic>('/lessons');

      expect(res.data, {'stale': true});
    });

    test('expired payment-pending entry is NOT served offline', () async {
      final dio = buildDio(sensitivePolicy);
      await seedAged(
        'GET /subscriptions/payment-pending',
        const Duration(hours: 1),
      );

      adapter.mode = _Mode.networkError;
      await expectLater(
        dio.get<dynamic>('/subscriptions/payment-pending'),
        throwsA(isA<DioException>()),
      );
    });

    test('payment-pending within TTL still serves; sibling path unaffected',
        () async {
      final dio = buildDio(sensitivePolicy);
      await seedAged(
        'GET /subscriptions/payment-pending',
        const Duration(minutes: 5),
      );
      await seedAged('GET /subscriptions', const Duration(hours: 1));

      adapter.mode = _Mode.networkError;
      final fresh = await dio.get<dynamic>('/subscriptions/payment-pending');
      expect(fresh.data, {'stale': true});

      final sibling = await dio.get<dynamic>('/subscriptions');
      expect(sibling.data, {'stale': true});
    });
  });
  group('onCacheServed (N14 / D2)', () {
    test('fires with the served entry cachedAt on offline serve only',
        () async {
      final served = <DateTime>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        ResponseCacheInterceptor(
          store: store,
          policy: allowlisted,
          onCacheServed: served.add,
        ),
      );

      adapter.mode = _Mode.success;
      await dio.get<dynamic>('/lessons');
      expect(served, isEmpty, reason: 'live responses must not notify');

      adapter.mode = _Mode.networkError;
      final res = await dio.get<dynamic>('/lessons');
      expect(res.data, {'ok': true});
      expect(served, hasLength(1));
      expect(
        DateTime.now().toUtc().difference(served.single).inMinutes,
        lessThan(2),
      );
    });
  });
}
