import 'package:hive_flutter/hive_flutter.dart';

import '../domain/sync_queue_entry.dart';

class SyncQueueStore {
  /// Default Hive box name — shared with logout cleanup (#1114, INV-4).
  static const String defaultBoxName = 'sync_queue';

  SyncQueueStore({
    this.boxName = defaultBoxName,
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

  /// Remove synced entries and expired failed entries.
  /// Keeps up to [maxEntries] pending entries (oldest removed first).
  /// Failed entries older than [expireAfter] are deleted regardless of maxEntries.
  Future<int> cleanup({
    int maxEntries = 500,
    Duration expireAfter = const Duration(days: 7),
  }) async {
    final box = await _openQueueBox();
    int removed = 0;
    final now = DateTime.now().toUtc();
    final entriesToDelete = <dynamic>[];

    // Collect all synced entries and expired failed entries
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

      // Remove all synced entries
      if (status == 'synced') {
        entriesToDelete.add(key);
        continue;
      }

      // Remove failed entries older than expireAfter
      if (status == 'failed' && entryMap['createdAt'] is String) {
        try {
          final createdAt =
              DateTime.parse(entryMap['createdAt'] as String).toUtc();
          if (now.difference(createdAt) > expireAfter) {
            entriesToDelete.add(key);
          }
        } catch (_) {
          // Invalid date format, skip
        }
      }
    }

    // Delete collected entries
    for (final key in entriesToDelete) {
      await box.delete(key);
      removed++;
    }

    // If still over maxEntries, remove oldest pending entries
    if (removed < entriesToDelete.length) {
      return removed; // Some deletions failed, return what succeeded
    }

    final allEntries = await fetchAll();
    if (allEntries.length > maxEntries) {
      final excess = allEntries.length - maxEntries;
      // INV-3 (#1115): capacity trimming must never silently drop unsent
      // writes — only synced/failed entries may be removed (oldest first).
      // The box may stay over maxEntries when the excess is all pending.
      final trimmable = allEntries
          .where(
            (e) =>
                e.status != SyncQueueStatus.pending &&
                e.status != SyncQueueStatus.syncing,
          )
          .take(excess)
          .toList();
      for (final entry in trimmable) {
        await box.delete(entry.id);
        removed++;
      }
    }

    return removed;
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
