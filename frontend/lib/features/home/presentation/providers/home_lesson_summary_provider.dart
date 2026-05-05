import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../students/students_facade.dart';
import '../../../subscription/subscription_facade.dart';

final homeStudentsProvider = FutureProvider<List<Student>>((ref) {
  return ref.watch(studentsProvider.future);
});

final _homeLessonsProvider = FutureProvider<List<Lesson>>((ref) {
  return ref.watch(lessonsProvider.future);
});

final homeHasLessonsProvider = Provider<bool>((ref) {
  return ref.watch(_homeLessonsProvider).valueOrNull?.isNotEmpty ?? false;
});

final homeHasCompletedLessonProvider = Provider<bool>((ref) {
  return ref
          .watch(_homeLessonsProvider)
          .valueOrNull
          ?.any((lesson) => lesson.status == LessonStatus.completed) ??
      false;
});

final homeFirstLessonIdProvider = Provider<String?>((ref) {
  final lessons = ref.watch(_homeLessonsProvider).valueOrNull;
  return lessons?.isNotEmpty == true ? lessons!.first.id : null;
});

class HomeLessonClassContext {
  final String label;

  const HomeLessonClassContext({required this.label});
}

final homeActiveStudentMembershipsProvider =
    FutureProvider.family<List<ClassMembership>, String>((ref, studentId) {
      return ref.watch(activeStudentMembershipsProvider(studentId).future);
    });

final homeActiveStudentSubscriptionsProvider =
    FutureProvider.family<List<Subscription>, String>((ref, studentId) {
      return ref.watch(activeStudentSubscriptionsProvider(studentId).future);
    });

final homeLessonClassContextProvider =
    FutureProvider.family<HomeLessonClassContext?, String>((
      ref,
      classId,
    ) async {
      final lessonClass = await ref.watch(lessonClassProvider(classId).future);
      if (lessonClass == null) return null;

      return HomeLessonClassContext(
        label:
            lessonClass.type == LessonClassType.academy
                ? lessonClass.name
                : AppStrings.individualLesson,
      );
    });
