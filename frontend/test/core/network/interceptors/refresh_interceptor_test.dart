// Regression tests for RefreshInterceptor token-clearing policy.
//
// Beta incident 2026-07-30: a backend worker died while the refresh POST was
// in flight. The old interceptor cleared BOTH tokens on ANY DioException from
// the refresh call, so a transient connection reset silently destroyed the
// session — every subsequent request 401'd with no refresh token left and the
// student home (수강권 포함) failed wholesale. Tokens must be cleared ONLY when
// the server explicitly rejects the refresh token (401/403).

import 'dart:typed_data';

import 'package:lessonaza/core/auth/token_storage.dart';
import 'package:lessonaza/core/network/interceptors/refresh_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory TokenStorage double that records clearTokens calls.
class _FakeTokenStorage implements TokenStorage {
  String? access;
  String? refresh;
  int clearCalls = 0;

  _FakeTokenStorage({this.access, this.refresh});

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<bool> hasTokens() async => access != null && refresh != null;

  @override
  Future<void> clearTokens() async {
    clearCalls++;
    access = null;
    refresh = null;
  }
}

/// Adapter stub — routes each request through [onFetch].
class _StubAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  _StubAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => onFetch(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, int status) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  /// Builds an outer Dio whose '/protected' 401s unless the retried request
  /// carries the refreshed token.
  Dio buildOuterDio() {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.httpClientAdapter = _StubAdapter((options) async {
      if (options.headers['Authorization'] == 'Bearer NEW_AT') {
        return _json('{"ok": true}', 200);
      }
      return _json('{"detail": "expired"}', 401);
    });
    return dio;
  }

  Dio buildRefreshDio(Future<ResponseBody> Function(RequestOptions) onFetch) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.httpClientAdapter = _StubAdapter(onFetch);
    return dio;
  }

  test('refresh 성공 시 새 토큰 저장 + 원요청 재시도 성공', () async {
    final storage = _FakeTokenStorage(access: 'OLD_AT', refresh: 'OLD_RT');
    final outer = buildOuterDio();
    outer.interceptors.add(
      RefreshInterceptor(
        outer,
        storage,
        refreshDioFactory: () => buildRefreshDio(
          (options) async => _json(
            '{"access_token": "NEW_AT", "refresh_token": "NEW_RT"}',
            200,
          ),
        ),
      ),
    );

    final response = await outer.get<dynamic>('/protected');

    expect(response.statusCode, 200);
    expect(storage.access, 'NEW_AT');
    expect(storage.refresh, 'NEW_RT');
    expect(storage.clearCalls, 0);
  });

  test('refresh 네트워크 단절(워커 재기동) 시 토큰 보존 — 세션 파괴 금지', () async {
    final storage = _FakeTokenStorage(access: 'OLD_AT', refresh: 'OLD_RT');
    final outer = buildOuterDio();
    outer.interceptors.add(
      RefreshInterceptor(
        outer,
        storage,
        refreshDioFactory: () => buildRefreshDio((options) async {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'connection reset (worker died mid-request)',
          );
        }),
      ),
    );

    await expectLater(
      outer.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );

    // The fix: transient failure must NOT clear the session.
    expect(storage.clearCalls, 0);
    expect(storage.refresh, 'OLD_RT');
  });

  test('refresh 5xx(서버 오류) 시 토큰 보존', () async {
    final storage = _FakeTokenStorage(access: 'OLD_AT', refresh: 'OLD_RT');
    final outer = buildOuterDio();
    outer.interceptors.add(
      RefreshInterceptor(
        outer,
        storage,
        refreshDioFactory: () => buildRefreshDio(
          (options) async => _json('{"detail": "boom"}', 500),
        ),
      ),
    );

    await expectLater(
      outer.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(storage.clearCalls, 0);
    expect(storage.refresh, 'OLD_RT');
  });

  test('refresh 401(토큰 명시 거부) 시에만 세션 폐기', () async {
    final storage = _FakeTokenStorage(access: 'OLD_AT', refresh: 'OLD_RT');
    final outer = buildOuterDio();
    outer.interceptors.add(
      RefreshInterceptor(
        outer,
        storage,
        refreshDioFactory: () => buildRefreshDio(
          (options) async => _json('{"detail": "revoked"}', 401),
        ),
      ),
    );

    await expectLater(
      outer.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(storage.clearCalls, 1);
    expect(storage.refresh, isNull);
  });

  test('refresh 토큰 부재 시 401 전파 (기존 동작 가드)', () async {
    final storage = _FakeTokenStorage(access: 'OLD_AT', refresh: null);
    final outer = buildOuterDio();
    outer.interceptors.add(
      RefreshInterceptor(
        outer,
        storage,
        refreshDioFactory: () => buildRefreshDio(
          (options) async => fail('refresh must not be attempted'),
        ),
      ),
    );

    await expectLater(
      outer.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );
  });
}
