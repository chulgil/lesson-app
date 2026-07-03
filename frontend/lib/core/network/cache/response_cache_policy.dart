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
  /// NOTE: only domains that do NOT keep a bespoke read-cache may be added —
  /// otherwise the HTTP cache double-caches with the domain's `*CacheStore`.
  /// Batch-1 domains removed their SyncAware read-cache ("일원화"); batch-2
  /// domains (#1116 G-05) are plain `createRepository` remotes with no bespoke
  /// cache, verified per-domain. See plan §5 batch ordering.
  static const ResponseCachePolicy active = ResponseCachePolicy(
    allowlist: {
      // batch 1 — consolidated SyncAware domains
      '/lessons',
      '/students',
      '/subscriptions',
      '/schedule/availability',
      '/schedule/slots',
      // batch 2 (#1116 G-05 / SN-2) — highest-frequency user screens, all
      // plain remotes with no bespoke cache (double-cache risk verified nil).
      '/parents', // parent_home
      '/manual-teachers', // student_home
      '/practice', // practice hub (segment-aware: excludes /practice-logs)
      '/practice-logs', // practice logs (sibling of /practice)
      '/recordings', // recording list metadata (audio itself is local)
      '/teachers', // teacher profiles read by practice + search
      '/gamification', // gamification state (heatmap is separate local Hive)
    },
    // D3: money-adjacent reads must not be served stale for long.
    sensitivePrefixes: {
      '/subscriptions/payment-pending',
      // Billing target (which parent pays) must stay fresh — short TTL, not
      // stale-until-reconnect like display reads.
      '/parents/billing-target',
    },
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
