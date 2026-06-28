/// Path-prefix allowlist gating which GET responses the
/// `ResponseCacheInterceptor` caches and serves offline.
///
/// Reconciles option A's *global* Dio interceptor with the *per-batch* rollout
/// (offline-first migration plan §5): the interceptor is always installed, but
/// only requests whose path starts with an allowlisted prefix are cached or
/// served from cache.
///
/// Batch 0 ships an EMPTY allowlist → the interceptor is a runtime no-op
/// (zero behaviour change, zero blast radius). Each subsequent batch adds its
/// domain's path prefixes to [allowlist] — this class is the single edit point
/// for the rollout.
class ResponseCachePolicy {
  const ResponseCachePolicy({this.allowlist = const <String>{}});

  /// Path prefixes eligible for response caching, e.g. `/lessons`.
  ///
  /// Empty in batch 0. Batch 1 adds `/lessons`, `/schedule`, `/subscriptions`,
  /// `/students`; later batches extend further. Sensitive write-authoritative
  /// paths (billing, auth) stay excluded until their dedicated batch (D3/D6).
  final Set<String> allowlist;

  /// Whether responses for [path] may be cached / served from cache.
  ///
  /// Returns false when the allowlist is empty (batch 0 no-op) or when no
  /// prefix matches.
  bool isCacheable(String path) {
    if (allowlist.isEmpty) return false;
    return allowlist.any(path.startsWith);
  }
}
