import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'practice_scratch_mode_storage_provider.g.dart';

/// Per-user preference for the practice repeat-count stamp interaction
/// (`ScratchStampSheet`, P1 daily-satisfaction gamification).
///
/// When enabled ("빠른 체크 모드"), tapping an empty practice-repeat slot
/// increments the count immediately without opening the scratch popup.
/// Default is disabled — the founder's vision is the tactile
/// scratch-to-color ritual; quick-check is an opt-in escape hatch for
/// students who find the ritual tedious.
///
/// Keys follow the user-scoped convention so multiple students on the same
/// device do not share this preference.
@Riverpod(keepAlive: true)
class PracticeScratchModeStorage extends _$PracticeScratchModeStorage {
  static const _boxName = 'practice_scratch_mode_storage';

  @override
  Future<bool> build(String studentId) async {
    return _load();
  }

  Future<bool> _load() async {
    try {
      final box = await Hive.openBox<bool>(_boxName);
      return box.get(_keyForStudent(studentId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Persists the "다음부터 빠르게 체크" preference for [studentId].
  Future<void> setQuickCheckEnabled(bool enabled) async {
    state = AsyncData(enabled);
    try {
      final box = await Hive.openBox<bool>(_boxName);
      await box.put(_keyForStudent(studentId), enabled);
    } catch (_) {
      // Persistence best-effort; in-memory state already updated.
    }
  }

  static String _keyForStudent(String studentId) =>
      'student:$studentId:practice_scratch_quick_mode';
}
