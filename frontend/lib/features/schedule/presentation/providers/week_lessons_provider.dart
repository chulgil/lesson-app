import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/providers/lesson_repository_provider.dart';

/// Provider that loads all lessons for a given week (Mon-Sun).
/// [weekStartDate] should be the Monday of the target week.
final weekLessonsProvider =
    FutureProvider.family<List<Lesson>, DateTime>((ref, weekStartDate) async {
  final repository = ref.watch(lessonRepositoryProvider);
  final weekEnd = weekStartDate.add(const Duration(days: 6));
  return repository.getLessonsByDateRange(weekStartDate, weekEnd);
});

/// Helper to get the Monday of the week containing [date].
DateTime getWeekStart(DateTime date) {
  final weekday = date.weekday; // 1=Mon, 7=Sun
  return DateTime(date.year, date.month, date.day - (weekday - 1));
}
