/// Path-prefix allowlist gating which GET responses the
/// `ResponseCacheInterceptor` caches and serves offline.
///
/// Reconciles option A's *global* Dio interceptor with the *per-batch* rollout
/// (offline-first migration plan §5): the interceptor is always installed, but
/// only requests whose path matches an allowlisted prefix are cached or served
/// from cache.
///
/// [active] is the single edit point for the rollout — each batch adds its
/// domain's path prefixes there.
class ResponseCachePolicy {
  const ResponseCachePolicy({
    this.allowlist = const <String>{},
    this.sensitivePrefixes = const <String>{},
    this.sensitiveTtl = const Duration(minutes: 15),
  });

  /// The live policy used in production wiring (see `apiClient`).
  ///
  /// Batch 0 shipped an empty set (runtime no-op). Batch 1 enables the lessons
  /// domain; subsequent batches append their prefixes here.
  ///
  /// NOTE: only domains whose bespoke read-cache has been removed (offline-first
  /// "일원화") may be added — otherwise the HTTP cache double-caches with the
  /// domain's `*CacheStore`. See plan §5 batch ordering.
  static const ResponseCachePolicy active = ResponseCachePolicy(
    allowlist: {
      '/lessons',
      '/students',
      '/subscriptions',
      '/schedule/availability',
      '/schedule/slots',
    },
    // D3: money-adjacent reads must not be served stale for long.
    sensitivePrefixes: {'/subscriptions/payment-pending'},
  );

  /// Path prefixes eligible for response caching, e.g. `/lessons`.
  ///
  /// Sensitive write-authoritative paths (billing, auth) stay excluded until
  /// their dedicated batch (D3/D6).
  final Set<String> allowlist;

  /// Allowlisted sub-prefixes whose cached responses expire after
  /// [sensitiveTtl] (offline plan D3). Display-only domains have no TTL —
  /// stale-until-reconnect is the adopted policy (D2).
  final Set<String> sensitivePrefixes;

  /// Max age an entry under [sensitivePrefixes] may be served offline.
  final Duration sensitiveTtl;

  /// Whether responses for [path] may be cached / served from cache.
  ///
  /// Segment-aware: a prefix `/lessons` matches `/lessons` and `/lessons/123`
  /// but NOT a sibling path like `/lessons-classes`. Returns false when the
  /// allowlist is empty or when no prefix matches.
  bool isCacheable(String path) => matchingPrefix(path) != null;

  /// The allowlisted prefix covering [path], or null when none matches.
  ///
  /// Write-invalidation (N7) uses this to scope which cached reads a
  /// mutation on [path] makes stale.
  String? matchingPrefix(String path) {
    for (final prefix in allowlist) {
      if (path == prefix || path.startsWith('$prefix/')) return prefix;
    }
    return null;
  }

  /// TTL for [path], or null when the entry never expires (D3: only
  /// sensitive prefixes age out; display domains are stale-until-reconnect).
  Duration? ttlFor(String path) {
    final sensitive = sensitivePrefixes.any(
      (prefix) => path == prefix || path.startsWith('$prefix/'),
    );
    return sensitive ? sensitiveTtl : null;
  }
}
