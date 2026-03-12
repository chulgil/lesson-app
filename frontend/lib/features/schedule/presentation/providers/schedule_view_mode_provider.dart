import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Schedule view mode enum
enum ScheduleViewMode {
  list, // ≡ Existing list view
  timeline, // ▤ Daily timeline view
  weeklyGrid, // ⊞ Weekly summary grid
}

/// Hive box key for persisting view mode
const _hiveBoxName = 'settings';
const _hiveKey = 'schedule_view_mode';

/// Provider for schedule view mode with Hive persistence.
final scheduleViewModeProvider =
    StateNotifierProvider<ScheduleViewModeNotifier, ScheduleViewMode>((ref) {
  return ScheduleViewModeNotifier();
});

class ScheduleViewModeNotifier extends StateNotifier<ScheduleViewMode> {
  ScheduleViewModeNotifier() : super(ScheduleViewMode.list) {
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    try {
      final box = await Hive.openBox(_hiveBoxName);
      final savedIndex = box.get(_hiveKey, defaultValue: 0) as int;
      if (savedIndex >= 0 && savedIndex < ScheduleViewMode.values.length) {
        state = ScheduleViewMode.values[savedIndex];
      }
    } catch (_) {
      // Silently default to list
    }
  }

  Future<void> setMode(ScheduleViewMode mode) async {
    state = mode;
    try {
      final box = await Hive.openBox(_hiveBoxName);
      await box.put(_hiveKey, mode.index);
    } catch (_) {
      // Persist failure is non-critical
    }
  }
}
