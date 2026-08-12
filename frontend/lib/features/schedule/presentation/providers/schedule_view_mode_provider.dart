import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart' show currentUserIdProvider;

part 'schedule_view_mode_provider.g.dart';

/// Schedule view mode enum
enum ScheduleViewMode {
  list, // ≡ Existing list view
  timeline, // ▤ Daily timeline view
  weeklyGrid, // ⊞ Weekly summary grid
}

/// Hive box for persisting per-teacher schedule preferences.
const _hiveBoxName = 'settings';

@Riverpod(keepAlive: true)
class ScheduleViewModeNotifier extends _$ScheduleViewModeNotifier {
  @override
  ScheduleViewMode build() {
    final teacherId = ref.watch(currentUserIdProvider);
    _loadFromHive(teacherId);
    return ScheduleViewMode.list;
  }

  // User-scoped key (mirrors OnboardingProgressStorage) so the last-picked
  // view mode never leaks between accounts on the same device.
  String _hiveKey(String teacherId) => 'teacher:$teacherId:scheduleViewMode';

  Future<void> _loadFromHive(String teacherId) async {
    try {
      final box = await Hive.openBox(_hiveBoxName);
      final savedIndex = box.get(_hiveKey(teacherId), defaultValue: 0) as int;
      if (savedIndex >= 0 && savedIndex < ScheduleViewMode.values.length) {
        state = ScheduleViewMode.values[savedIndex];
      }
    } catch (_) {
      // Silently default to list
    }
  }

  Future<void> setMode(ScheduleViewMode mode) async {
    final teacherId = ref.read(currentUserIdProvider);
    state = mode;
    try {
      final box = await Hive.openBox(_hiveBoxName);
      await box.put(_hiveKey(teacherId), mode.index);
    } catch (_) {
      // Persist failure is non-critical
    }
  }
}
