import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/cache/response_cache_policy.dart';

void main() {
  group('isCacheable — segment-aware prefix matching', () {
    const policy = ResponseCachePolicy(allowlist: {'/lessons'});

    test('exact prefix matches', () {
      expect(policy.isCacheable('/lessons'), isTrue);
    });

    test('sub-path matches', () {
      expect(policy.isCacheable('/lessons/123'), isTrue);
      expect(policy.isCacheable('/lessons/123/notes'), isTrue);
    });

    test('sibling path with shared text prefix does NOT match', () {
      // Guards against double-caching: `/lessons-classes` belongs to the
      // students domain (still SyncAware-cached) and must not be HTTP-cached
      // just because it shares the `/lessons` text prefix.
      expect(policy.isCacheable('/lessons-classes'), isFalse);
      expect(policy.isCacheable('/lessons-classes/5'), isFalse);
    });

    test('unrelated path does not match', () {
      expect(policy.isCacheable('/students'), isFalse);
    });
  });

  group('empty allowlist (no-op)', () {
    test('matches nothing', () {
      const empty = ResponseCachePolicy();
      expect(empty.isCacheable('/lessons'), isFalse);
    });
  });

  group('active policy (batch 1)', () {
    test('enables lessons only, not yet-unmigrated domains', () {
      expect(ResponseCachePolicy.active.isCacheable('/lessons'), isTrue);
      // students/subscription/schedule keep their SyncAware cache until their
      // own consolidation batch — must stay out of the HTTP allowlist.
      expect(ResponseCachePolicy.active.isCacheable('/students'), isFalse);
      expect(ResponseCachePolicy.active.isCacheable('/subscriptions'), isFalse);
      expect(ResponseCachePolicy.active.isCacheable('/bookings'), isFalse);
      expect(
        ResponseCachePolicy.active.isCacheable('/lessons-classes'),
        isFalse,
      );
    });
  });
}
