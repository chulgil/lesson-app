import 'package:hive/hive.dart';

import '../../domain/entities/practice_loop_stats.dart';
import '../../domain/repositories/practice_loop_stats_repository.dart';

/// Offline-aware sync queue for loop stats (#512).
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §5 — 세션 종료
/// 시점에 배치 동기화. 오프라인이면 Hive 큐에 보관 후 다음 온라인 시 flush.
///
/// Storage model:
/// - Hive box ``practice_loop_stats_queue``.
/// - Key ``{studentUserId}:{sectionId}`` keeps one pending row per section
///   (clients overwrite their own latest delta — server still gets the
///   cumulative max via [syncStudent]).
class LoopStatsSyncService {
  static const String boxName = 'practice_loop_stats_queue';

  final PracticeLoopStatsRepository _repository;
  Box<Map>? _box;

  LoopStatsSyncService(this._repository);

  Future<Box<Map>> _openBox() async {
    final existing = _box;
    if (existing != null && existing.isOpen) return existing;
    if (Hive.isBoxOpen(boxName)) {
      final reused = Hive.box<Map>(boxName);
      _box = reused;
      return reused;
    }
    final opened = await Hive.openBox<Map>(boxName);
    _box = opened;
    return opened;
  }

  String _key(String studentUserId, String sectionId) =>
      '$studentUserId:$sectionId';

  /// Queue one (section, count) delta. Idempotent — replaces any earlier
  /// pending row for the same (studentUserId, sectionId) pair.
  Future<void> enqueue({
    required String studentUserId,
    required PendingLoopStatsSync entry,
  }) async {
    final box = await _openBox();
    await box.put(_key(studentUserId, entry.sectionId), entry.toJson());
  }

  /// Read the currently pending entries for a given student.
  Future<List<PendingLoopStatsSync>> pendingFor(String studentUserId) async {
    final box = await _openBox();
    final prefix = '$studentUserId:';
    final result = <PendingLoopStatsSync>[];
    for (final key in box.keys.cast<String>()) {
      if (!key.startsWith(prefix)) continue;
      final raw = box.get(key);
      if (raw is Map) {
        result.add(
          PendingLoopStatsSync.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    }
    return result;
  }

  /// Flush all pending entries for [studentUserId] to the backend.
  ///
  /// On success the queue is cleared. On error the queue is preserved so the
  /// next flush (re-)attempts the same payload — idempotent on the server.
  Future<PracticeLoopStatsSyncResult> flush(String studentUserId) async {
    final pending = await pendingFor(studentUserId);
    if (pending.isEmpty) {
      return const PracticeLoopStatsSyncResult();
    }
    try {
      final result = await _repository.syncStudent(entries: pending);
      await _clearFor(studentUserId);
      return result;
    } catch (_) {
      // Preserve queue for retry. Callers may inspect by re-fetching pending.
      rethrow;
    }
  }

  Future<void> _clearFor(String studentUserId) async {
    final box = await _openBox();
    final prefix = '$studentUserId:';
    final keysToDelete = box.keys
        .cast<String>()
        .where((k) => k.startsWith(prefix))
        .toList();
    if (keysToDelete.isEmpty) return;
    await box.deleteAll(keysToDelete);
  }
}
