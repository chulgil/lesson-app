import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/core/sync/data/sync_queue_store.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';

void main() {
  group('SyncQueueStore runMigrations', () {
    late Directory tempDir;
    late SyncQueueStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'lessonaza_sync_queue_store_test_',
      );
      Hive.init(tempDir.path);

      store = SyncQueueStore(
        boxName: 'sync_queue_test',
        metaBoxName: 'sync_queue_meta_test',
      );
    });

    tearDown(() async {
      await store.close();
      await Hive.close();

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    SyncQueueEntry makeLegacyEntry({
      required String id,
      SyncQueueStatus status = SyncQueueStatus.pending,
    }) {
      return SyncQueueEntry(
        id: id,
        domain: 'lesson',
        operation: SyncOperationType.create,
        httpMethod: 'POST',
        path: '/lessons',
        payload: {'name': 'Test'},
        status: status,
        createdAt: DateTime.utc(2026, 5, 1),
        updatedAt: DateTime.utc(2026, 5, 1),
        queryParameters: {'v': 'legacy'},
      );
    }

    test('legacy items key를 entries map으로 정리한다', () async {
      final queueBox = await Hive.openBox<dynamic>(store.boxName);

      await queueBox.put('items', [
        makeLegacyEntry(id: 'legacy-1').toMap(),
        makeLegacyEntry(id: 'legacy-2').toMap(),
      ]);

      await store.runMigrations();

      final entries = await store.fetchAll();

      expect(entries, hasLength(2));
      expect(
        entries.map((entry) => entry.id),
        containsAll(['legacy-1', 'legacy-2']),
      );
      expect(queueBox.get('items'), isNull);
      expect(
        await store.schemaVersion,
        equals(SyncQueueStore.targetSchemaVersion),
      );
    });

    test('컴팩트 시 유효하지 않은 엔트리는 삭제한다', () async {
      final queueBox = await Hive.openBox<dynamic>(store.boxName);
      final validEntry = makeLegacyEntry(id: 'valid');

      await queueBox.put('invalid-primitive', 1);
      await queueBox.put('invalid-map', {'id': 1});
      await queueBox.put(validEntry.id, validEntry.toMap());

      await store.runMigrations();

      final entries = await store.fetchAll();
      expect(entries, hasLength(1));
      expect(entries.single.id, equals('valid'));
    });
  });

  group('SyncQueueStore cleanup (INV-3)', () {
    late Directory tempDir;
    late SyncQueueStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'lessonaza_sync_cleanup_test_',
      );
      Hive.init(tempDir.path);
      store = SyncQueueStore(
        boxName: 'sync_cleanup_test',
        metaBoxName: 'sync_cleanup_meta_test',
      );
    });

    tearDown(() async {
      await store.close();
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> put(
      String id,
      SyncQueueStatus status, {
      DateTime? createdAt,
    }) async {
      final box = await Hive.openBox<dynamic>(store.boxName);
      final at = createdAt ?? DateTime.utc(2026, 6, 1);
      await box.put(
        id,
        SyncQueueEntry(
          id: id,
          domain: 'lesson',
          operation: SyncOperationType.create,
          httpMethod: 'POST',
          path: '/lessons',
          payload: {'name': id},
          queryParameters: const {},
          status: status,
          createdAt: at,
          updatedAt: at,
        ).toMap(),
      );
    }

    test('removes synced entries but keeps pending', () async {
      await put('s1', SyncQueueStatus.synced);
      await put('p1', SyncQueueStatus.pending);

      final result = await store.cleanup();

      expect(result.syncedRemoved, 1);
      expect(result.expiredFailedRemoved, 0);
      expect((await store.fetchAll()).map((e) => e.id), ['p1']);
    });

    test('never removes pending, even far beyond maxEntries (INV-3)', () async {
      for (var i = 0; i < 600; i++) {
        await put(
          'p$i',
          SyncQueueStatus.pending,
          createdAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        );
      }

      final result = await store.cleanup(maxEntries: 500);

      expect(
        result.totalRemoved,
        0,
        reason: 'unsent writes must not be dropped',
      );
      expect((await store.fetchAll()).length, 600);
    });

    test(
      'removes failed older than expireAfter, keeps recent failed',
      () async {
        final now = DateTime.now().toUtc();
        await put(
          'old',
          SyncQueueStatus.failed,
          createdAt: now.subtract(const Duration(days: 8)),
        );
        await put(
          'recent',
          SyncQueueStatus.failed,
          createdAt: now.subtract(const Duration(days: 1)),
        );

        final result = await store.cleanup();

        expect(
          result.expiredFailedRemoved,
          1,
          reason: 'lost-write count for user notice',
        );
        expect((await store.fetchAll()).map((e) => e.id), ['recent']);
      },
    );

    test('never removes syncing entries', () async {
      await put('sync1', SyncQueueStatus.syncing);

      final result = await store.cleanup();

      expect(result.totalRemoved, 0);
      expect((await store.fetchAll()).single.id, 'sync1');
    });

    test(
      'clearAll empties the queue and returns the unsent count (INV-4)',
      () async {
        await put('p1', SyncQueueStatus.pending);
        await put('f1', SyncQueueStatus.failed);
        await put('sync1', SyncQueueStatus.syncing);
        await put('s1', SyncQueueStatus.synced); // delivered — not "unsent"

        final dropped = await store.clearAll();

        expect(dropped, 3, reason: 'pending + failed + syncing, not synced');
        expect(await store.fetchAll(), isEmpty);
      },
    );
  });
}
