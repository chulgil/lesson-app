import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart' show currentUserIdProvider;

part 'student_lessons_tab_state_provider.g.dart';

/// Hive box for persisting per-student schedule preferences (mirrors the
/// teacher-side `schedule_tab_state_provider.dart`).
const _hiveBoxName = 'settings';

/// Lesson sort type for schedule views
enum LessonSortType {
  timeAsc('시간순'),
  nameAsc('이름순');

  final String displayName;
  const LessonSortType(this.displayName);
}

/// State provider for student selected date
@Riverpod(keepAlive: true)
class StudentSelectedDate extends _$StudentSelectedDate {
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

/// State provider for student lesson sort type. Persists the last selection
/// per student so it survives app restarts.
@Riverpod(keepAlive: true)
class StudentLessonSortType extends _$StudentLessonSortType {
  @override
  LessonSortType build() {
    final studentId = ref.watch(currentUserIdProvider);
    _loadFromHive(studentId);
    return LessonSortType.timeAsc;
  }

  @override
  LessonSortType get state => super.state;

  @override
  set state(LessonSortType value) => super.state = value;

  String _hiveKey(String studentId) => 'student:$studentId:lessonSortType';

  Future<void> _loadFromHive(String studentId) async {
    try {
      final box = await Hive.openBox(_hiveBoxName);
      final savedIndex = box.get(_hiveKey(studentId), defaultValue: 0) as int;
      if (savedIndex >= 0 && savedIndex < LessonSortType.values.length) {
        state = LessonSortType.values[savedIndex];
      }
    } catch (_) {
      // Silently default to timeAsc
    }
  }

  /// Selects [value] and persists it for the current student.
  Future<void> setSortType(LessonSortType value) async {
    final studentId = ref.read(currentUserIdProvider);
    state = value;
    try {
      final box = await Hive.openBox(_hiveBoxName);
      await box.put(_hiveKey(studentId), value.index);
    } catch (_) {
      // Persist failure is non-critical
    }
  }
}
