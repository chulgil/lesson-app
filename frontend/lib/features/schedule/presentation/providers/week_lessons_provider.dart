import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../lessons/lessons_facade.dart';
import '../../../students/students_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/services/preview_lesson_generator.dart';
import '../providers/unified_lesson_request_providers.dart';

part 'week_lessons_provider.g.dart';

/// Provider that loads all lessons for a given week (Mon-Sun).
/// [weekStartDate] should be the Monday of the target week.
@Riverpod(keepAlive: true)
Future<List<Lesson>> weekLessons(
  WeekLessonsRef ref,
  DateTime weekStartDate,
) async {
  final repository = ref.watch(lessonRepositoryProvider);
  final weekEnd = weekStartDate.add(const Duration(days: 6));
  return repository.getLessonsByDateRange(weekStartDate, weekEnd);
}

/// Provider that loads lessons + preview lessons for a given week.
///
/// Preview lessons are generated from ClassMembership.lessonSlots for weeks
/// beyond subscription coverage. Rendered with dashed borders in the grid.
@Riverpod(keepAlive: true)
Future<List<Lesson>> weekLessonsWithPreview(
  WeekLessonsWithPreviewRef ref,
  ({DateTime weekStart, String teacherId}) params,
) async {
  // Get real lessons
  final repository = ref.watch(lessonRepositoryProvider);
  final weekEnd = params.weekStart.add(const Duration(days: 6));
  final realLessons = await repository.getLessonsByDateRange(
    params.weekStart,
    weekEnd,
  );

  // Get teacher's classes → memberships → subscriptions for preview generation
  final classes = await ref.watch(
    teacherLessonClassesProvider(params.teacherId).future,
  );

  if (classes.isEmpty) return realLessons;

  final allMemberships = <dynamic>[];
  final allSubscriptions = <dynamic>[];
  final studentNames = ref.watch(studentNameMapProvider);

  for (final cls in classes) {
    final memberships = await ref.watch(
      classMembershipsProvider(cls.id).future,
    );
    allMemberships.addAll(memberships);

    for (final m in memberships) {
      final subs = await ref.watch(
        studentSubscriptionsProvider(m.studentId).future,
      );
      allSubscriptions.addAll(subs);
    }
  }

  // Generate preview lessons
  final previewLessons = PreviewLessonGenerator.generateForWeek(
    weekStart: params.weekStart,
    memberships: allMemberships.cast(),
    subscriptions: allSubscriptions.cast(),
    existingLessons: realLessons,
    studentNames: studentNames,
  );

  return [...realLessons, ...previewLessons];
}

/// Helper to get the Monday of the week containing [date].
DateTime getWeekStart(DateTime date) {
  final weekday = date.weekday; // 1=Mon, 7=Sun
  return DateTime(date.year, date.month, date.day - (weekday - 1));
}
