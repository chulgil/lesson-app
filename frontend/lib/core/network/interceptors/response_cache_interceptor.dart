import 'package:dio/dio.dart';

import '../cache/response_cache_policy.dart';
import '../cache/response_cache_store.dart';

/// Dio interceptor implementing offline read fallback
/// (offline-first migration plan §3, option A).
///
/// - [onResponse]: caches successful (2xx) GET responses for allowlisted paths.
/// - [onError]: on a transport-level network failure (connection / timeout) for
///   an allowlisted GET with a cache hit, resolves the request with the cached
///   response so the UI shows last-known-good data instead of an error. Every
///   other case — cache miss, business errors (4xx/5xx HTTP responses),
///   non-GET, non-allowlisted path — propagates unchanged.
///
/// Gated by [ResponseCachePolicy]: with an empty allowlist (batch 0) this is a
/// complete no-op (zero behaviour change, zero blast radius).
///
/// Placement: added LAST in the Dio chain so [onResponse] observes the final
/// (post token-refresh) success and [onError] observes the terminal error.
class ResponseCacheInterceptor extends Interceptor {
  ResponseCacheInterceptor({
    required ResponseCacheStore store,
    required ResponseCachePolicy policy,
  }) : _store = store,
       _policy = policy;

  final ResponseCacheStore _store;
  final ResponseCachePolicy _policy;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    final statusCode = response.statusCode ?? 0;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    if (_isGet(options) && isSuccess && _policy.isCacheable(options.path)) {
      try {
        await _store.put(
          _keyFor(options),
          statusCode: statusCode,
          data: response.data,
        );
      } catch (_) {
        // Cache write is best-effort; never block or fail the response.
      }
    } else if (!_isGet(options) && isSuccess) {
      // N7: a successful write makes the domain's cached reads stale.
      // Covers direct online writes AND queued-mutation replays (both pass
      // through this interceptor). Cross-domain effects (e.g. a booking
      // creating lessons) are intentionally out of scope — prefix-local only.
      final prefix = _policy.matchingPrefix(options.path);
      if (prefix != null) {
        try {
          await _store.removeByPathPrefix(prefix);
        } catch (_) {
          // Invalidation is best-effort; never block the response.
        }
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    if (_isGet(options) &&
        _isNetworkFailure(err) &&
        _policy.isCacheable(options.path)) {
      final cached = _store.get(_keyFor(options));
      if (cached != null && !_isExpired(cached, options.path)) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: cached.data,
            statusCode: cached.statusCode,
            extra: const {'fromCache': true},
          ),
        );
        return;
      }
    }
    handler.next(err);
  }

  bool _isGet(RequestOptions options) => options.method.toUpperCase() == 'GET';

  /// N15/D3: sensitive entries (payment-pending) age out after the policy
  /// TTL; everything else is stale-until-reconnect (no TTL).
  bool _isExpired(CachedHttpResponse cached, String path) {
    final ttl = _policy.ttlFor(path);
    if (ttl == null) return false;
    return DateTime.now().toUtc().difference(cached.cachedAt) > ttl;
  }

  String _keyFor(RequestOptions options) => ResponseCacheStore.buildKey(
    method: options.method,
    path: options.path,
    query: options.queryParameters,
  );

  /// True only for transport-level failures (no connectivity / timeout) — this
  /// is independent of error-mapping interceptor order. HTTP business errors
  /// (4xx/5xx responses) are intentionally NOT treated as network failures:
  /// stale cache must not mask a real server response.
  ///
  /// NB: this is narrower than `MutationQueueHelper`, which also queues *writes*
  /// on 5xx. For reads we stay conservative (transport-only) in batch 0; whether
  /// to also serve cache on 5xx is a batch-1 decision (offline-first plan §4).
  bool _isNetworkFailure(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      default:
        return false;
    }
  }
}
