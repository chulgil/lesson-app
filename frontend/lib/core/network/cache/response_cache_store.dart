import 'dart:convert';

import 'package:hive/hive.dart';

/// A single cached HTTP response entry.
class CachedHttpResponse {
  const CachedHttpResponse({
    required this.cachedAt,
    required this.statusCode,
    required this.data,
  });

  final DateTime cachedAt;
  final int statusCode;
  final Object? data;
}

/// Hive-backed cache of raw HTTP GET responses, keyed by method + path + query.
///
/// Powers offline read fallback (offline-first migration plan §3, option A):
/// [ResponseCacheInterceptor] writes successful GET responses here and serves
/// them when a later request fails with a network error.
///
/// Storage: `Box<String>` + JSON (same pattern as the per-domain
/// `*CacheStore`s — no TypeAdapter). Each entry:
/// ```json
/// { "cachedAt": "<iso8601>", "statusCode": 200, "data": <raw json> }
/// ```
///
/// Bounded: when [maxEntries] is exceeded, the oldest-written entries are
/// evicted (write-order eviction by `cachedAt`; precise LRU is unnecessary for
/// a response cache). Per-user isolation is handled by [clear] on logout /
/// data-mode switch, not by per-user keys.
class ResponseCacheStore {
  ResponseCacheStore({required Box<String> box, int maxEntries = 300})
    : _box = box,
      _maxEntries = maxEntries;

  static const String boxName = 'response_cache_v1';

  final Box<String> _box;
  final int _maxEntries;

  /// Builds a stable cache key from method + path + query.
  ///
  /// Query keys are sorted so parameter order does not affect the key.
  static String buildKey({
    required String method,
    required String path,
    Map<String, dynamic>? query,
  }) {
    final normalizedMethod = method.toUpperCase();
    if (query == null || query.isEmpty) {
      return '$normalizedMethod $path';
    }
    final entries =
        query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final queryString = entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$normalizedMethod $path?$queryString';
  }

  /// Stores a response body under [key]. Evicts oldest entries past the cap.
  Future<void> put(
    String key, {
    required int statusCode,
    required Object? data,
  }) async {
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'statusCode': statusCode,
      'data': data,
    });
    await _box.put(key, payload);
    await _evictIfNeeded();
  }

  /// Returns the cached response for [key], or null on miss / corrupt entry.
  CachedHttpResponse? get(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAtRaw = map['cachedAt'] as String?;
      final statusCode = map['statusCode'] as int?;
      if (cachedAtRaw == null || statusCode == null) return null;
      final cachedAt = DateTime.tryParse(cachedAtRaw);
      if (cachedAt == null) return null;
      return CachedHttpResponse(
        cachedAt: cachedAt,
        statusCode: statusCode,
        data: map['data'],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) => _box.delete(key);

  /// Clears all cached responses — call on logout / data-mode switch to prevent
  /// cross-user leakage.
  Future<void> clear() => _box.clear();

  int get length => _box.length;

  Future<void> _evictIfNeeded() async {
    final overflow = _box.length - _maxEntries;
    if (overflow <= 0) return;
    final dated = <MapEntry<dynamic, DateTime>>[
      for (final k in _box.keys) MapEntry(k, _cachedAtOf(k)),
    ];
    dated.sort((a, b) => a.value.compareTo(b.value));
    final toRemove = dated.take(overflow).map((e) => e.key).toList();
    await _box.deleteAll(toRemove);
  }

  DateTime _cachedAtOf(dynamic key) {
    try {
      final raw = _box.get(key);
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      return DateTime.tryParse(map['cachedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}
