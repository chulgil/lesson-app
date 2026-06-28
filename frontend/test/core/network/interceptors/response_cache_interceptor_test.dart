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
}
