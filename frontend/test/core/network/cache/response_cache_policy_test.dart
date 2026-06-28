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

  group('active policy (batch 1d)', () {
    test('enables consolidated domains, not yet-unmigrated ones', () {
      // Consolidated batches: lessons (batch 1), students (batch 1c),
      // subscriptions (batch 1d).
      expect(ResponseCachePolicy.active.isCacheable('/lessons'), isTrue);
      expect(ResponseCachePolicy.active.isCacheable('/students'), isTrue);
      expect(ResponseCachePolicy.active.isCacheable('/students/123'), isTrue);
      expect(ResponseCachePolicy.active.isCacheable('/subscriptions'), isTrue);
      expect(
        ResponseCachePolicy.active.isCacheable('/subscriptions/abc'),
        isTrue,
      );
      // schedule keeps its SyncAware cache until its own consolidation batch —
      // must stay out of the HTTP allowlist.
      expect(ResponseCachePolicy.active.isCacheable('/bookings'), isFalse);
      // Sibling text prefixes must not match consolidated domains. The proposal
      // and template repos use plain createRepository (no cache) and must NOT
      // be HTTP-cached just because they share the `/subscriptions` text prefix.
      expect(
        ResponseCachePolicy.active.isCacheable('/lessons-classes'),
        isFalse,
      );
      expect(
        ResponseCachePolicy.active.isCacheable('/subscriptions-proposals'),
        isFalse,
      );
      expect(
        ResponseCachePolicy.active.isCacheable('/subscriptions-templates'),
        isFalse,
      );
    });
  });
}
