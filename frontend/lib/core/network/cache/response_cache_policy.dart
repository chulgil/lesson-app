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
  const ResponseCachePolicy({this.allowlist = const <String>{}});

  /// The live policy used in production wiring (see `apiClient`).
  ///
  /// Batch 0 shipped an empty set (runtime no-op). Batch 1 enables the lessons
  /// domain; subsequent batches append their prefixes here.
  ///
  /// NOTE: only domains whose bespoke read-cache has been removed (offline-first
  /// "일원화") may be added — otherwise the HTTP cache double-caches with the
  /// domain's `*CacheStore`. See plan §5 batch ordering.
  static const ResponseCachePolicy active = ResponseCachePolicy(
    allowlist: {'/lessons', '/students'},
  );

  /// Path prefixes eligible for response caching, e.g. `/lessons`.
  ///
  /// Sensitive write-authoritative paths (billing, auth) stay excluded until
  /// their dedicated batch (D3/D6).
  final Set<String> allowlist;

  /// Whether responses for [path] may be cached / served from cache.
  ///
  /// Segment-aware: a prefix `/lessons` matches `/lessons` and `/lessons/123`
  /// but NOT a sibling path like `/lessons-classes`. Returns false when the
  /// allowlist is empty or when no prefix matches.
  bool isCacheable(String path) {
    if (allowlist.isEmpty) return false;
    return allowlist.any(
      (prefix) => path == prefix || path.startsWith('$prefix/'),
    );
  }
}
