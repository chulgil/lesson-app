// #1115 (INV-3) — cleanup must never silently delete unsent (pending) writes.
// Capacity trimming may only remove synced/failed entries.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/core/sync/data/sync_queue_store.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';

void main() {
  group('SyncQueueStore cleanup (INV-3)', () {
    late Directory tempDir;
    late SyncQueueStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'lessonaza_sync_queue_cleanup_test_',
      );
      Hive.init(tempDir.path);

      store = SyncQueueStore(
        boxName: 'sync_queue_cleanup_test',
        metaBoxName: 'sync_queue_cleanup_meta_test',
      );
    });

    tearDown(() async {
      await store.close();
      await Hive.close();

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    SyncQueueEntry makeEntry({
      required String id,
      required SyncQueueStatus status,
      required DateTime createdAt,
    }) {
      return SyncQueueEntry(
        id: id,
        domain: 'lesson',
        operation: SyncOperationType.create,
        httpMethod: 'POST',
        path: '/lessons',
        payload: const {'title': 'x'},
        status: status,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
    }

    test('maxEntries 초과여도 pending 엔트리는 삭제하지 않는다', () async {
      final base = DateTime.utc(2026, 7, 9);
      for (var i = 0; i < 6; i++) {
        await store.upsert(
          makeEntry(
            id: 'pending_$i',
            status: SyncQueueStatus.pending,
            createdAt: base.add(Duration(minutes: i)),
          ),
        );
      }

      final removed = await store.cleanup(maxEntries: 3);

      final rest = await store.fetchAll();
      expect(removed, 0, reason: 'pending 은 용량 초과여도 삭제 금지 (INV-3)');
      expect(rest.length, 6);
      expect(rest.where((e) => e.status == SyncQueueStatus.pending).length, 6);
    });

    test('용량 초과분은 synced/failed 에서만 제거하고 pending 은 유지한다', () async {
      final base = DateTime.utc(2026, 7, 9);
      // Oldest 2 = pending (would be trimmed first by the old buggy logic).
      for (var i = 0; i < 2; i++) {
        await store.upsert(
          makeEntry(
            id: 'pending_$i',
            status: SyncQueueStatus.pending,
            createdAt: base.add(Duration(minutes: i)),
          ),
        );
      }
      // 4 recent failed entries (not yet expired).
      for (var i = 0; i < 4; i++) {
        await store.upsert(
          makeEntry(
            id: 'failed_$i',
            status: SyncQueueStatus.failed,
            createdAt: base.add(Duration(minutes: 10 + i)),
          ),
        );
      }

      // 6 entries, cap 3 → excess 3 must come from failed only.
      await store.cleanup(
        maxEntries: 3,
        expireAfter: const Duration(days: 3650),
      );

      final rest = await store.fetchAll();
      final pendingIds =
          rest
              .where((e) => e.status == SyncQueueStatus.pending)
              .map((e) => e.id)
              .toSet();
      expect(pendingIds, {'pending_0', 'pending_1'});
      expect(
        rest.where((e) => e.status == SyncQueueStatus.failed).length,
        1,
        reason: '초과분 3건은 failed 에서 오래된 순으로 제거',
      );
    });
  });
}
