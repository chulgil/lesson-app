import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/lesson.dart';
import 'lesson_crud_provider.dart';

/// Dashboard stats for lessons
final lessonStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final lessonsAsync = ref.watch(lessonsNotifierProvider);

  return lessonsAsync.when(
    data: (lessons) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final thisWeekLessons = lessons.where((l) {
        final lessonDate = DateTime(l.date.year, l.date.month, l.date.day);
        return lessonDate
                .isAfter(weekStart.subtract(const Duration(days: 1))) &&
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
});
