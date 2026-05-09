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
}
