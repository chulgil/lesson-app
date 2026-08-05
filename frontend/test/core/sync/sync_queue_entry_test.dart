import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';

void main() {
  SyncQueueEntry baseEntry({String? idempotencyKey}) {
    final now = DateTime.utc(2026, 7, 10, 12);
    return SyncQueueEntry(
      id: 'e1',
      domain: 'lesson',
      operation: SyncOperationType.create,
      httpMethod: 'POST',
      path: '/lessons',
      payload: const {'title': 'x'},
      status: SyncQueueStatus.pending,
      createdAt: now,
      updatedAt: now,
      idempotencyKey: idempotencyKey,
    );
  }

  group('SyncQueueEntry idempotencyKey (#1117)', () {
    test('round-trips through toMap/fromMap', () {
      final entry = baseEntry(idempotencyKey: 'idem-123');
      final restored = SyncQueueEntry.fromMap(entry.toMap());
      expect(restored.idempotencyKey, equals('idem-123'));
    });

    test('legacy map without the field deserializes to null (back-compat)', () {
      // Simulate an entry persisted before idempotency support existed.
      final legacyMap = baseEntry().toMap()..remove('idempotencyKey');
      expect(legacyMap.containsKey('idempotencyKey'), isFalse);

      final restored = SyncQueueEntry.fromMap(legacyMap);
      expect(restored.idempotencyKey, isNull);
      // Other fields still deserialize unchanged.
      expect(restored.id, equals('e1'));
      expect(restored.httpMethod, equals('POST'));
    });

    test('copyWith preserves the key across a status change', () {
      final entry = baseEntry(idempotencyKey: 'idem-123');
      final synced = entry.copyWith(status: SyncQueueStatus.pending);
      expect(synced.idempotencyKey, equals('idem-123'));
    });

    test('null key stays null through a round-trip', () {
      final restored = SyncQueueEntry.fromMap(baseEntry().toMap());
      expect(restored.idempotencyKey, isNull);
    });
  });
}
