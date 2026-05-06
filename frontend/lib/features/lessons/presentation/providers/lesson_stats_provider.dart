import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/lessons/domain/entities/lesson.dart';
import 'lesson_crud_provider.dart';

part 'lesson_stats_provider.g.dart';

/// Dashboard stats for lessons
@Riverpod(keepAlive: true)
AsyncValue<Map<String, int>> lessonStats(LessonStatsRef ref) {
  final lessonsAsync = ref.watch(lessonsNotifierProvider);

  return lessonsAsync.when(
    data: (lessons) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final thisWeekLessons =
          lessons.where((l) {
            final lessonDate = DateTime(l.date.year, l.date.month, l.date.day);
            return lessonDate.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                lessonDate.isBefore(weekEnd.add(const Duration(days: 1)));
          }).toList();

      return AsyncValue.data({
        'total': lessons.length,
        'scheduled':
            lessons.where((l) => l.status == LessonStatus.scheduled).length,
        'completed':
            lessons.where((l) => l.status == LessonStatus.completed).length,
        'thisWeek': thisWeekLessons.length,
        'today': lessons.where((l) => l.isToday).length,
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
}
