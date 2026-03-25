import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/lessons/domain/entities/lesson.dart';
import 'lesson_repository_provider.dart';

/// Selected date for calendar
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Lessons for selected date
final selectedDateLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByDate(date);
});

/// Lessons for calendar view (month range)
final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final monthLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final month = ref.watch(calendarMonthProvider);
  final repository = ref.watch(lessonRepositoryProvider);

  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);

  return repository.getLessonsByDateRange(start, end);
});

/// Lessons grouped by date for calendar
final lessonsMapProvider =
    Provider<AsyncValue<Map<DateTime, List<Lesson>>>>((ref) {
  final lessonsAsync = ref.watch(monthLessonsProvider);

  return lessonsAsync.when(
    data: (lessons) {
      final map = <DateTime, List<Lesson>>{};
      for (final lesson in lessons) {
        final dateKey =
            DateTime(lesson.date.year, lesson.date.month, lesson.date.day);
        map.putIfAbsent(dateKey, () => []).add(lesson);
      }
      return AsyncValue.data(map);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Selected week start for calendar
final selectedWeekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  final dayOfWeek = now.weekday;
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: dayOfWeek - 1));
});

/// Selected day index for calendar (0 = Monday)
final selectedDayIndexProvider = StateProvider<int>((ref) {
  return DateTime.now().weekday - 1;
});

/// Lessons for selected week
final weekLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final weekStart = ref.watch(selectedWeekStartProvider);
  final weekEnd = weekStart.add(const Duration(days: 6));
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByDateRange(weekStart, weekEnd);
});

/// Lessons grouped by day index for week view
final weekLessonsMapProvider =
    Provider<AsyncValue<Map<int, List<Lesson>>>>((ref) {
  final lessonsAsync = ref.watch(weekLessonsProvider);
  final weekStart = ref.watch(selectedWeekStartProvider);

  return lessonsAsync.when(
    data: (lessons) {
      final map = <int, List<Lesson>>{};
      for (final lesson in lessons) {
        final lessonDate =
            DateTime(lesson.date.year, lesson.date.month, lesson.date.day);
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
});
