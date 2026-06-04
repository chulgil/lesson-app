import 'package:hive/hive.dart';

import '../../domain/repositories/practice_repeat_total_repository.dart';

/// Hive-backed implementation. Stores cumulative repeat counts under
/// user-scoped key `{studentUserId}:practiceRepeatTotal` so students stay
/// isolated on shared devices.
///
/// Spec: #508 — feeds [BadgeChecker.onPracticeRepeat] via the practice
/// loop provider.
class HivePracticeRepeatTotalRepository
    implements PracticeRepeatTotalRepository {
  static const String boxName = 'practice_repeat_totals';
  static const String _suffix = ':practiceRepeatTotal';

  Box<int>? _box;

  HivePracticeRepeatTotalRepository();

  Future<Box<int>> _openBox() async {
    final existing = _box;
    if (existing != null && existing.isOpen) return existing;
    if (Hive.isBoxOpen(boxName)) {
      final reused = Hive.box<int>(boxName);
      _box = reused;
      return reused;
    }
    final opened = await Hive.openBox<int>(boxName);
    _box = opened;
    return opened;
  }

  String _key(String studentUserId) => '$studentUserId$_suffix';

  @override
  Future<int> getTotal(String studentUserId) async {
    final box = await _openBox();
    return box.get(_key(studentUserId), defaultValue: 0) ?? 0;
  }

  @override
  Future<void> setTotal({
    required String studentUserId,
    required int total,
  }) async {
    final box = await _openBox();
    final clamped = total < 0 ? 0 : total;
    await box.put(_key(studentUserId), clamped);
  }

  @override
  Future<int> increment({required String studentUserId, int by = 1}) async {
    final box = await _openBox();
    final key = _key(studentUserId);
    final current = box.get(key, defaultValue: 0) ?? 0;
    final next = current + by;
    await box.put(key, next);
    return next;
  }
}
