import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../students/students_facade.dart';
import '../../../subscription/subscription_facade.dart';

part 'home_lesson_summary_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<Student>> homeStudents(HomeStudentsRef ref) {
  return ref.watch(studentsProvider.future);
}

@Riverpod(keepAlive: true)
Future<List<Lesson>> _homeLessons(_HomeLessonsRef ref) {
  return ref.watch(lessonsProvider.future);
}

@Riverpod(keepAlive: true)
bool homeHasLessons(HomeHasLessonsRef ref) {
  return ref.watch(_homeLessonsProvider).valueOrNull?.isNotEmpty ?? false;
}

@Riverpod(keepAlive: true)
bool homeHasCompletedLesson(HomeHasCompletedLessonRef ref) {
  return ref
          .watch(_homeLessonsProvider)
          .valueOrNull
          ?.any((lesson) => lesson.status == LessonStatus.completed) ??
      false;
}

@Riverpod(keepAlive: true)
String? homeFirstLessonId(HomeFirstLessonIdRef ref) {
  final lessons = ref.watch(_homeLessonsProvider).valueOrNull;
  return lessons?.isNotEmpty == true ? lessons!.first.id : null;
}

class HomeLessonClassContext {
  final String label;

  const HomeLessonClassContext({required this.label});
}

@Riverpod(keepAlive: true)
Future<List<ClassMembership>> homeActiveStudentMemberships(
  HomeActiveStudentMembershipsRef ref,
  String studentId,
) {
  return ref.watch(activeStudentMembershipsProvider(studentId).future);
}

@Riverpod(keepAlive: true)
Future<List<Subscription>> homeActiveStudentSubscriptions(
  HomeActiveStudentSubscriptionsRef ref,
  String studentId,
) {
  return ref.watch(activeStudentSubscriptionsProvider(studentId).future);
}

@Riverpod(keepAlive: true)
Future<HomeLessonClassContext?> homeLessonClassContext(
  HomeLessonClassContextRef ref,
  String classId,
) async {
  final lessonClass = await ref.watch(lessonClassProvider(classId).future);
  if (lessonClass == null) return null;

  return HomeLessonClassContext(
    label:
        lessonClass.type == LessonClassType.academy
            ? lessonClass.name
            : AppStrings.individualLesson,
  );
}
