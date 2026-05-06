import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/lessons/domain/entities/lesson.dart';
import 'lesson_repository_provider.dart';

part 'lesson_calendar_provider.g.dart';

/// Selected date for calendar
@Riverpod(keepAlive: true)
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }
}

/// Lessons for selected date
@Riverpod(keepAlive: true)
Future<List<Lesson>> selectedDateLessons(SelectedDateLessonsRef ref) async {
  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByDate(date);
}

/// Lessons for calendar view (month range)
@Riverpod(keepAlive: true)
class CalendarMonth extends _$CalendarMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }
}

@Riverpod(keepAlive: true)
Future<List<Lesson>> monthLessons(MonthLessonsRef ref) async {
  final month = ref.watch(calendarMonthProvider);
  final repository = ref.watch(lessonRepositoryProvider);

  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);

  return repository.getLessonsByDateRange(start, end);
}

/// Lessons grouped by date for calendar
@Riverpod(keepAlive: true)
AsyncValue<Map<DateTime, List<Lesson>>> lessonsMap(LessonsMapRef ref) {
  final lessonsAsync = ref.watch(monthLessonsProvider);

  return lessonsAsync.when(
    data: (lessons) {
      final map = <DateTime, List<Lesson>>{};
      for (final lesson in lessons) {
        final dateKey = DateTime(
          lesson.date.year,
          lesson.date.month,
          lesson.date.day,
        );
        map.putIfAbsent(dateKey, () => []).add(lesson);
      }
      return AsyncValue.data(map);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
}

/// Selected week start for calendar
@Riverpod(keepAlive: true)
class SelectedWeekStart extends _$SelectedWeekStart {
  @override
  DateTime build() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: dayOfWeek - 1));
  }

  void setWeekStart(DateTime weekStart) {
    state = weekStart;
  }
}

/// Selected day index for calendar (0 = Monday)
@Riverpod(keepAlive: true)
class SelectedDayIndex extends _$SelectedDayIndex {
  @override
  int build() {
    return DateTime.now().weekday - 1;
  }

  void setDayIndex(int dayIndex) {
    state = dayIndex;
  }
}

/// Lessons for selected week
@Riverpod(keepAlive: true)
Future<List<Lesson>> weekLessons(WeekLessonsRef ref) async {
  final weekStart = ref.watch(selectedWeekStartProvider);
  final weekEnd = weekStart.add(const Duration(days: 6));
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByDateRange(weekStart, weekEnd);
}

/// Lessons grouped by day index for week view
@Riverpod(keepAlive: true)
AsyncValue<Map<int, List<Lesson>>> weekLessonsMap(WeekLessonsMapRef ref) {
  final lessonsAsync = ref.watch(weekLessonsProvider);
  final weekStart = ref.watch(selectedWeekStartProvider);

  return lessonsAsync.when(
    data: (lessons) {
      final map = <int, List<Lesson>>{};
      for (final lesson in lessons) {
        final lessonDate = DateTime(
          lesson.date.year,
          lesson.date.month,
          lesson.date.day,
        );
        final dayIndex = lessonDate.difference(weekStart).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          map.putIfAbsent(dayIndex, () => []).add(lesson);
        }
      }
      return AsyncValue.data(map);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
}
