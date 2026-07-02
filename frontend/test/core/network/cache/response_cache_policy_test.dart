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

  group('active policy (batch 1e)', () {
    test('enables consolidated domains, not yet-unmigrated ones', () {
      // Consolidated batches: lessons (batch 1), students (batch 1c),
      // subscriptions (batch 1d), schedule availability/slots (batch 1e).
      expect(ResponseCachePolicy.active.isCacheable('/lessons'), isTrue);
      expect(ResponseCachePolicy.active.isCacheable('/students'), isTrue);
      expect(ResponseCachePolicy.active.isCacheable('/students/123'), isTrue);
      expect(ResponseCachePolicy.active.isCacheable('/subscriptions'), isTrue);
      expect(
        ResponseCachePolicy.active.isCacheable('/subscriptions/abc'),
        isTrue,
      );
      // schedule availability + computed slots (batch 1e).
      expect(
        ResponseCachePolicy.active.isCacheable('/schedule/availability'),
        isTrue,
      );
      expect(
        ResponseCachePolicy.active.isCacheable('/schedule/availability/t1'),
        isTrue,
      );
      expect(ResponseCachePolicy.active.isCacheable('/schedule/slots'), isTrue);
      // The bare /schedule prefix is intentionally NOT allowlisted, so other
      // schedule-feature repos (booking, group_class, vacation — still
      // createRepository, no cache) must not be HTTP-cached.
      expect(ResponseCachePolicy.active.isCacheable('/schedule'), isFalse);
      expect(
        ResponseCachePolicy.active.isCacheable('/schedule/weekly'),
        isFalse,
      );
      // bookings repo is NOT consolidated (different repo, createRepository) —
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
  group('ttlFor (N15 / D3)', () {
    const policy = ResponseCachePolicy(
      allowlist: {'/subscriptions'},
      sensitivePrefixes: {'/subscriptions/payment-pending'},
      sensitiveTtl: Duration(minutes: 15),
    );

    test('sensitive prefix and its subpaths get the short TTL', () {
      expect(
        policy.ttlFor('/subscriptions/payment-pending'),
        const Duration(minutes: 15),
      );
      expect(
        policy.ttlFor('/subscriptions/payment-pending/123'),
        const Duration(minutes: 15),
      );
    });

    test('non-sensitive paths never expire', () {
      expect(policy.ttlFor('/subscriptions'), isNull);
      expect(policy.ttlFor('/subscriptions/abc'), isNull);
      expect(policy.ttlFor('/lessons'), isNull);
    });

    test('active policy marks payment-pending as sensitive', () {
      expect(
        ResponseCachePolicy.active.ttlFor('/subscriptions/payment-pending'),
        isNotNull,
      );
      expect(ResponseCachePolicy.active.ttlFor('/subscriptions'), isNull);
    });
  });
}
