import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/network/cache/response_cache_store.dart';

void main() {
  late Box<String> box;
  late ResponseCacheStore store;

  setUp(() async {
    await setUpTestHive();
    box = await Hive.openBox<String>('response_cache_test');
    store = ResponseCacheStore(box: box);
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('buildKey', () {
    test('method is upper-cased and path preserved', () {
      expect(
        ResponseCacheStore.buildKey(method: 'get', path: '/lessons'),
        equals('GET /lessons'),
      );
    });

    test('query parameter order does not affect the key', () {
      final a = ResponseCacheStore.buildKey(
        method: 'GET',
        path: '/lessons',
        query: {'b': 2, 'a': 1},
      );
      final b = ResponseCacheStore.buildKey(
        method: 'GET',
        path: '/lessons',
        query: {'a': 1, 'b': 2},
      );
      expect(a, equals(b));
      expect(a, equals('GET /lessons?a=1&b=2'));
    });

    test('empty query produces no query string', () {
      expect(
        ResponseCacheStore.buildKey(method: 'GET', path: '/x', query: {}),
        equals('GET /x'),
      );
    });
  });

  group('put / get roundtrip', () {
    test('stores and returns data, statusCode, cachedAt', () async {
      await store.put(
        'GET /lessons',
        statusCode: 200,
        data: [
          {'id': '1'},
        ],
      );
      final cached = store.get('GET /lessons');
      expect(cached, isNotNull);
      expect(cached!.statusCode, equals(200));
      expect(
        cached.data,
        equals([
          {'id': '1'},
        ]),
      );
      expect(cached.cachedAt, isA<DateTime>());
    });

    test('get on missing key returns null', () {
      expect(store.get('GET /nope'), isNull);
    });

    test('get on corrupt JSON returns null', () async {
      await box.put('GET /corrupt', 'not-json{{{');
      expect(store.get('GET /corrupt'), isNull);
    });

    test('get on entry missing statusCode returns null', () async {
      await box.put(
        'GET /partial',
        jsonEncode({'cachedAt': DateTime.now().toUtc().toIso8601String()}),
      );
      expect(store.get('GET /partial'), isNull);
    });

    test('stored payload includes cachedAt ISO string', () async {
      await store.put('GET /ts', statusCode: 200, data: null);
      final raw = box.get('GET /ts')!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['cachedAt'], isA<String>());
      expect(DateTime.tryParse(map['cachedAt'] as String), isNotNull);
    });
  });

  group('remove / clear', () {
    test('remove deletes a single entry', () async {
      await store.put('GET /a', statusCode: 200, data: 1);
      await store.remove('GET /a');
      expect(store.get('GET /a'), isNull);
    });

    test('clear empties the cache (cross-user isolation)', () async {
      await store.put('GET /a', statusCode: 200, data: 1);
      await store.put('GET /b', statusCode: 200, data: 2);
      await store.clear();
      expect(store.length, equals(0));
      expect(store.get('GET /a'), isNull);
    });
  });

  group('bounded eviction', () {
    test('trims to exactly maxEntries after overflow (not below)', () async {
      final bounded = ResponseCacheStore(box: box, maxEntries: 3);
      for (var i = 0; i < 6; i++) {
        await bounded.put('GET /item/$i', statusCode: 200, data: i);
      }
      expect(box.length, equals(3));
    });

    test('newest retained, oldest evicted down to cap', () async {
      final bounded = ResponseCacheStore(box: box, maxEntries: 2);
      for (var i = 0; i < 3; i++) {
        await bounded.put('GET /old/$i', statusCode: 200, data: i);
      }
      // Strictly-later timestamp guarantees this entry is the newest.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await bounded.put('GET /keep', statusCode: 200, data: 'keep');

      expect(box.length, equals(2));
      expect(bounded.get('GET /keep'), isNotNull, reason: 'newest retained');
      final survivingOld = box.keys.where((k) => '$k'.startsWith('GET /old/'));
      expect(
        survivingOld.length,
        equals(1),
        reason: 'older entries evicted down to the cap',
      );
    });
  });
  group('removeByPathPrefix (N7)', () {
    test('drops base, id, and query variants; keeps siblings/other domains',
        () async {
      await store.put('GET /lessons', statusCode: 200, data: 1);
      await store.put('GET /lessons/abc', statusCode: 200, data: 2);
      await store.put('GET /lessons?date=2026-07-01', statusCode: 200, data: 3);
      await store.put('GET /lessons-classes', statusCode: 200, data: 4);
      await store.put('GET /students', statusCode: 200, data: 5);

      await store.removeByPathPrefix('/lessons');

      expect(store.get('GET /lessons'), isNull);
      expect(store.get('GET /lessons/abc'), isNull);
      expect(store.get('GET /lessons?date=2026-07-01'), isNull);
      expect(store.get('GET /lessons-classes'), isNotNull);
      expect(store.get('GET /students'), isNotNull);
    });
  });
}
