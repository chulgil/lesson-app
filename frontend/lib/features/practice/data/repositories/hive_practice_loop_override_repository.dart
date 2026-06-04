import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/practice_loop_override.dart';
import '../../domain/repositories/practice_loop_override_repository.dart';

/// Hive-backed implementation. Stores each override as a JSON-encoded string
/// under a user-scoped key `{studentUserId}:{sectionId}` — keeps students
/// isolated on shared devices and survives schema changes without a custom
/// TypeAdapter.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §5.1
class HivePracticeLoopOverrideRepository
    implements PracticeLoopOverrideRepository {
  static const String boxName = 'practice_loop_overrides';

  Box<String>? _box;

  HivePracticeLoopOverrideRepository();

  Future<Box<String>> _openBox() async {
    final existing = _box;
    if (existing != null && existing.isOpen) return existing;
    if (Hive.isBoxOpen(boxName)) {
      final reused = Hive.box<String>(boxName);
      _box = reused;
      return reused;
    }
    final opened = await Hive.openBox<String>(boxName);
    _box = opened;
    return opened;
  }

  String _key(String studentUserId, String sectionId) =>
      '$studentUserId:$sectionId';

  @override
  Future<PracticeLoopOverride?> findFor({
    required String studentUserId,
    required String sectionId,
  }) async {
    final box = await _openBox();
    final raw = box.get(_key(studentUserId, sectionId));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PracticeLoopOverride.fromJson(json);
    } catch (_) {
      // Corrupt entry — drop silently so the UI falls back to teacher defaults.
      await box.delete(_key(studentUserId, sectionId));
      return null;
    }
  }

  @override
  Future<void> save(PracticeLoopOverride override) async {
    final box = await _openBox();
    final encoded = jsonEncode(override.toJson());
    await box.put(_key(override.studentUserId, override.sectionId), encoded);
  }

  @override
  Future<void> delete({
    required String studentUserId,
    required String sectionId,
  }) async {
    final box = await _openBox();
    await box.delete(_key(studentUserId, sectionId));
  }

  @override
  Future<List<PracticeLoopOverride>> findAllForStudent(
    String studentUserId,
  ) async {
    final box = await _openBox();
    final prefix = '$studentUserId:';
    final results = <PracticeLoopOverride>[];
    for (final key in box.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        results.add(PracticeLoopOverride.fromJson(json));
      } catch (_) {
        // Skip corrupt entry.
      }
    }
    return results;
  }
}
