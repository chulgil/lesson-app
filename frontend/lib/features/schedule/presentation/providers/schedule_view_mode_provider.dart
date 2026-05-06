import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_view_mode_provider.g.dart';

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
final scheduleViewModeProvider = scheduleViewModeNotifierProvider;

@Riverpod(keepAlive: true)
class ScheduleViewModeNotifier extends _$ScheduleViewModeNotifier {
  @override
  ScheduleViewMode build() {
    _loadFromHive();
    return ScheduleViewMode.list;
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
