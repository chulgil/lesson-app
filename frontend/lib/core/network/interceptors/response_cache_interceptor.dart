import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../cache/response_cache_policy.dart';
import '../cache/response_cache_store.dart';

/// Dio interceptor implementing offline read fallback + stale-while-revalidate
/// (offline-first migration plan §3 option A; sync spec §6 SN-1, gap G-04).
///
/// Two layers of read resilience, both gated by [ResponseCachePolicy]:
///
/// 1. **onError fallback** (always on): on a transport-level network failure
///    (connection / timeout) for an allowlisted GET with a cache hit, resolves
///    the request with the cached response (last-known-good). Every other case
///    — cache miss, business errors (4xx/5xx), non-GET, non-allowlisted —
///    propagates unchanged.
///
/// 2. **onRequest stale-while-revalidate** (active only when [revalidate] is
///    injected): when an allowlisted GET has a fresh-enough cache hit, a single
///    background revalidation is fired and raced against [swrSoftTimeout]:
///    - the revalidation returns within the soft window → the caller gets the
///      FRESH response (fast networks never see stale);
///    - the soft window elapses first → the caller is served the cached
///      response immediately (slow networks stop waiting the full ~30s
///      timeout), the background revalidation keeps running and updates the
///      store, and — if the fresh body differs from what was served — a
///      [onRevalidated] event lets subscribed providers refresh live.
///    With [revalidate] null (batch-0 / most unit tests) onRequest is a no-op
///    and only layer 1 applies — preserving legacy behaviour exactly.
///
/// [onResponse] caches successful (2xx) allowlisted GETs and, on a successful
/// non-GET, invalidates the domain's cached reads (N7).
///
/// Placement: added LAST in the Dio chain so [onResponse] observes the final
/// (post token-refresh) success and [onError] observes the terminal error.
class ResponseCacheInterceptor extends Interceptor {
  ResponseCacheInterceptor({
    required ResponseCacheStore store,
    required ResponseCachePolicy policy,
    void Function(DateTime cachedAt)? onCacheServed,
    void Function()? onFreshServed,
    void Function(String path)? onRevalidated,
    Future<Response<dynamic>> Function(RequestOptions options)? revalidate,
    Duration swrSoftTimeout = const Duration(milliseconds: 2500),
  }) : _store = store,
       _policy = policy,
       _onCacheServed = onCacheServed,
       _onFreshServed = onFreshServed,
       _onRevalidated = onRevalidated,
       _revalidate = revalidate,
       _swrSoftTimeout = swrSoftTimeout;

  /// RequestOptions.extra flag marking a background revalidation request, so it
  /// skips the onRequest cache-first shortcut (no recursion) and the onError
  /// cache serve (its caller was already served by the primary request).
  static const String swrBackgroundKey = 'swrBackground';

  final ResponseCacheStore _store;
  final ResponseCachePolicy _policy;

  /// N14/D2: notified with the served entry's `cachedAt` whenever a request is
  /// resolved from cache, so the offline/slow-network banner can show freshness.
  final void Function(DateTime cachedAt)? _onCacheServed;

  /// D2/G-06: notified when a caller receives a genuinely live (non-cache)
  /// allowlisted response, so the staleness banner can clear.
  final void Function()? _onFreshServed;

  /// G-04/SN-1: notified with the allowlist prefix when a background
  /// revalidation produced data that differs from what the caller was served
  /// stale — the revalidation bus turns this into a targeted provider refresh.
  final void Function(String path)? _onRevalidated;

  /// Fires a background revalidation GET for [options] (must carry the
  /// [swrBackgroundKey] flag). Null disables stale-while-revalidate.
  final Future<Response<dynamic>> Function(RequestOptions options)? _revalidate;

  /// How long a caller waits for a background revalidation before being served
  /// the cached response. Small = snappier stale serve on slow links; large =
  /// more chances to return fresh. Fast networks resolve well under this.
  final Duration _swrSoftTimeout;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final revalidate = _revalidate;
    // No SWR when disabled, non-GET, a background revalidation itself, or a
    // non-allowlisted path — fall through to the normal network-first flow
    // (onError still provides last-known-good on transport failure).
    if (revalidate == null ||
        !_isGet(options) ||
        options.extra[swrBackgroundKey] == true ||
        !_policy.isCacheable(options.path)) {
      handler.next(options);
      return;
    }

    final cached = _store.get(_keyFor(options));
    if (cached == null || _isExpired(cached, options.path)) {
      // Nothing (fresh) to serve — must wait for the network.
      handler.next(options);
      return;
    }

    // Cache hit: race a single background revalidation against the soft timeout.
    var settled = false;
    final servedStaleJson = jsonEncode(cached.data);

    void serveStale() {
      if (settled) return;
      settled = true;
      _onCacheServed?.call(cached.cachedAt);
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          data: cached.data,
          statusCode: cached.statusCode,
          extra: const {'fromCache': true},
        ),
      );
    }

    revalidate(options)
        .then((fresh) {
          if (!settled) {
            // Fresh returned within the soft window — caller gets live data.
            settled = true;
            _onFreshServed?.call();
            handler.resolve(fresh);
            return;
          }
          // Caller already served stale; refresh the UI only if data changed.
          try {
            if (jsonEncode(fresh.data) != servedStaleJson) {
              _onRevalidated?.call(
                _policy.matchingPrefix(options.path) ?? options.path,
              );
            }
          } catch (_) {
            // Comparison is best-effort; never surface a background error.
          }
        })
        .catchError((Object _) {
          // Background revalidation failed within the soft window → serve cache now.
          serveStale();
        });

    // Serve cache if the network hasn't answered within the soft window.
    Future<void>.delayed(_swrSoftTimeout, serveStale);
  }

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
      // A live allowlisted read reaching a caller (not a background
      // revalidation) means on-screen data is now fresh → clear the banner.
      if (options.extra[swrBackgroundKey] != true) {
        _onFreshServed?.call();
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
    // Background revalidation failures are handled by the primary request's
    // own race (serveStale) — never serve/notify from here for them.
    if (options.extra[swrBackgroundKey] != true &&
        _isGet(options) &&
        _isNetworkFailure(err) &&
        _policy.isCacheable(options.path)) {
      final cached = _store.get(_keyFor(options));
      if (cached != null && !_isExpired(cached, options.path)) {
        _onCacheServed?.call(cached.cachedAt);
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
