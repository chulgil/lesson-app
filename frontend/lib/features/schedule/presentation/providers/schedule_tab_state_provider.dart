import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../student_home/student_home_ui_facade.dart';

part 'schedule_tab_state_provider.g.dart';

/// Hive box for persisting per-teacher schedule preferences (shared with
/// [ScheduleViewModeNotifier]).
const _hiveBoxName = 'settings';

/// State provider for teacher selected date
@Riverpod(keepAlive: true)
class TeacherSelectedDate extends _$TeacherSelectedDate {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  DateTime get state => super.state;

  @override
  set state(DateTime value) => super.state = value;
}

/// State provider for teacher lesson sort type. Persists the last selection
/// per teacher so it survives app restarts.
@Riverpod(keepAlive: true)
class TeacherLessonSortType extends _$TeacherLessonSortType {
  @override
  LessonSortType build() {
    final teacherId = ref.watch(currentUserIdProvider);
    _loadFromHive(teacherId);
    return LessonSortType.timeAsc;
  }

  @override
  LessonSortType get state => super.state;

  @override
  set state(LessonSortType value) => super.state = value;

  String _hiveKey(String teacherId) => 'teacher:$teacherId:lessonSortType';

  Future<void> _loadFromHive(String teacherId) async {
    try {
      final box = await Hive.openBox(_hiveBoxName);
      final savedIndex = box.get(_hiveKey(teacherId), defaultValue: 0) as int;
      if (savedIndex >= 0 && savedIndex < LessonSortType.values.length) {
        state = LessonSortType.values[savedIndex];
      }
    } catch (_) {
      // Silently default to timeAsc
    }
  }

  /// Selects [value] and persists it for the current teacher.
  Future<void> setSortType(LessonSortType value) async {
    final teacherId = ref.read(currentUserIdProvider);
    state = value;
    try {
      final box = await Hive.openBox(_hiveBoxName);
      await box.put(_hiveKey(teacherId), value.index);
    } catch (_) {
      // Persist failure is non-critical
    }
  }
}
