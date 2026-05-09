import '../../domain/entities/app_release.dart';
import '../../domain/repositories/app_release_repository.dart';

/// Decorator that caches [AppReleaseSnapshot] in memory with a TTL.
///
/// Falls back to the inner repository on cache miss or expiry.
/// On fetch failure, returns stale cache if available (graceful degradation).
class CachedAppReleaseRepository implements AppReleaseRepository {
  CachedAppReleaseRepository(
    this._inner, {
    this.ttl = const Duration(hours: 1),
  });

  final AppReleaseRepository _inner;
  final Duration ttl;

  AppReleaseSnapshot? _cached;
  DateTime? _cachedAt;

  @override
  Future<AppReleaseSnapshot> fetchReleaseSnapshot() async {
    final cached = _cached;
    final cachedAt = _cachedAt;

    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < ttl) {
      return cached;
    }

    try {
      final fresh = await _inner.fetchReleaseSnapshot();
      _cached = fresh;
      _cachedAt = DateTime.now();
      return fresh;
    } catch (_) {
      // Graceful degradation: return stale cache if available
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
}
