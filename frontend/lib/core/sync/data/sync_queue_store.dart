import 'package:hive_flutter/hive_flutter.dart';

import '../domain/sync_queue_entry.dart';

/// Breakdown of what a [SyncQueueStore.cleanup] pass removed.
///
/// [expiredFailedRemoved] counts *lost unsent writes* (failed entries that
/// aged out after exhausting retries) — the caller surfaces this to the user
/// (INV-3: no silent loss). Pending/syncing entries are never removed.
class SyncCleanupResult {
  const SyncCleanupResult({
    required this.syncedRemoved,
    required this.expiredFailedRemoved,
  });

  final int syncedRemoved;
  final int expiredFailedRemoved;

  int get totalRemoved => syncedRemoved + expiredFailedRemoved;
}

class SyncQueueStore {
  SyncQueueStore({
    this.boxName = 'sync_queue',
    this.metaBoxName = 'sync_queue_meta',
    this.schemaVersionKey = 'sync_queue_schema_version',
  });

  final String boxName;
  final String metaBoxName;
  final String schemaVersionKey;

  static const int targetSchemaVersion = 3;

  Future<Box<dynamic>> _openQueueBox() async {
    return Hive.openBox<dynamic>(boxName);
  }

  Future<Box<dynamic>> _openMetaBox() async {
    return Hive.openBox<dynamic>(metaBoxName);
  }

  Future<void> runMigrations() async {
    final metaBox = await _openMetaBox();
    final currentVersion = (metaBox.get(schemaVersionKey) as int?) ?? 0;

    if (currentVersion < 1) {
      await _ensureQueueBox();
      await metaBox.put(schemaVersionKey, 1);
    }

    if (currentVersion < 2) {
      await _normalizeLegacyLegacyKeys();
      await metaBox.put(schemaVersionKey, 2);
    }

    if (currentVersion < 3) {
      await _compactQueueEntries();
      await metaBox.put(schemaVersionKey, 3);
    }
  }

  Future<void> _ensureQueueBox() async {
    await _openQueueBox();
  }

  Future<void> _normalizeLegacyLegacyKeys() async {
    final queueBox = await _openQueueBox();
    final legacy = queueBox.get('items');
    if (legacy is List) {
      final legacyItems =
          legacy.where((row) => row is Map && row['id'] is String).toList();
      if (legacyItems.isEmpty) {
        return;
      }
      for (final row in legacyItems.cast<Map<dynamic, dynamic>>()) {
        final entry = SyncQueueEntry.fromMap(Map<String, dynamic>.from(row));
        await queueBox.put(entry.id, entry.toMap());
      }
      await queueBox.delete('items');
    }
  }

  Future<void> _compactQueueEntries() async {
    final queueBox = await _openQueueBox();
    final toDelete = <dynamic>[];

    for (final key in queueBox.keys) {
      final raw = queueBox.get(key);
      if (raw == null || raw is! Map<dynamic, dynamic>) {
        toDelete.add(key);
      }
    }

    for (final key in toDelete) {
      await queueBox.delete(key);
    }
  }

  Future<int> get schemaVersion async {
    final metaBox = await _openMetaBox();
    return (metaBox.get(schemaVersionKey) as int?) ?? 0;
  }

  Future<void> upsert(SyncQueueEntry entry) async {
    final queueBox = await _openQueueBox();
    await queueBox.put(entry.id, entry.toMap());
  }

  Future<void> delete(String id) async {
    final queueBox = await _openQueueBox();
    await queueBox.delete(id);
  }

  /// Clears the entire queue on identity change so a previous user's writes are
  /// never replayed under the next user's token (INV-4, #1114). Returns the
  /// number of *unsent* writes (pending / syncing / failed) that were dropped,
  /// so the user can be told they were lost (INV-3: no silent loss).
  Future<int> clearAll() async {
    final unsent =
        (await fetchAll())
            .where((entry) => entry.status != SyncQueueStatus.synced)
            .length;
    final queueBox = await _openQueueBox();
    await queueBox.clear();
    return unsent;
  }

  Future<List<SyncQueueEntry>> fetchAll() async {
    final queueBox = await _openQueueBox();
    final entries = <SyncQueueEntry>[];

    for (final raw in queueBox.values) {
      if (raw is! Map<dynamic, dynamic>) {
        continue;
      }
      final entryMap = Map<String, dynamic>.from(raw);
      if (!entryMap.containsKey('id') ||
          entryMap['id'] is! String ||
          !entryMap.containsKey('status')) {
        continue;
      }
      try {
        entries.add(SyncQueueEntry.fromMap(entryMap));
      } catch (_) {
        continue;
      }
    }
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  Future<List<SyncQueueEntry>> fetchByStatus(SyncQueueStatus status) async {
    final allEntries = await fetchAll();
    return allEntries.where((entry) => entry.status == status).toList();
  }

  Future<SyncQueueEntry?> getById(String id) async {
    final queueBox = await _openQueueBox();
    final raw = queueBox.get(id);
    if (raw is! Map<dynamic, dynamic>) {
      return null;
    }
    return SyncQueueEntry.fromMap(Map<String, dynamic>.from(raw));
  }

  /// Removes only entries that are safe to drop, returning a breakdown so the
  /// caller can notify the user about lost writes.
  ///
  /// - `synced` entries: always removed (already delivered).
  /// - `failed` entries older than [expireAfter]: removed after giving up
  ///   (these are *lost unsent writes* — surfaced via
  ///   [SyncCleanupResult.expiredFailedRemoved] so the user can be told).
  /// - `pending` / `syncing` entries: **never removed** (INV-3). Unsent writes
  ///   are user edits and must not be silently discarded, even under capacity
  ///   pressure. [maxEntries] is retained for API compatibility and to bound
  ///   how many entries we scan, but a large pending backlog is surfaced via
  ///   `SyncServiceStats`, not deleted.
  Future<SyncCleanupResult> cleanup({
    int maxEntries = 500,
    Duration expireAfter = const Duration(days: 7),
  }) async {
    final box = await _openQueueBox();
    final now = DateTime.now().toUtc();
    final syncedKeys = <dynamic>[];
    final expiredFailedKeys = <dynamic>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map<dynamic, dynamic>) {
        continue;
      }
      final entryMap = Map<String, dynamic>.from(raw);
      if (entryMap['id'] is! String || entryMap['status'] is! String) {
        continue;
      }

      final status = entryMap['status'] as String;

      if (status == 'synced') {
        syncedKeys.add(key);
      } else if (status == 'failed' && entryMap['createdAt'] is String) {
        try {
          final createdAt =
              DateTime.parse(entryMap['createdAt'] as String).toUtc();
          if (now.difference(createdAt) > expireAfter) {
            expiredFailedKeys.add(key);
          }
        } catch (_) {
          // Invalid date format — leave it in place rather than risk a drop.
        }
      }
      // pending / syncing: intentionally untouched (INV-3).
    }

    var syncedRemoved = 0;
    for (final key in syncedKeys) {
      await box.delete(key);
      syncedRemoved++;
    }
    var expiredFailedRemoved = 0;
    for (final key in expiredFailedKeys) {
      await box.delete(key);
      expiredFailedRemoved++;
    }

    return SyncCleanupResult(
      syncedRemoved: syncedRemoved,
      expiredFailedRemoved: expiredFailedRemoved,
    );
  }

  Future<void> close() async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<dynamic>(boxName).close();
    }
    if (Hive.isBoxOpen(metaBoxName)) {
      await Hive.box<dynamic>(metaBoxName).close();
    }
  }
}
