import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../lessons/lessons_facade.dart';

part 'student_home_teacher_feedback_provider.g.dart';

@riverpod
Future<Lesson?> studentHomeLatestTeacherFeedback(
  StudentHomeLatestTeacherFeedbackRef ref,
  String studentId,
) async {
  final lessons = await ref.watch(lessonsByStudentProvider(studentId).future);
  final feedbackLessons =
      lessons
          .where(
            (lesson) =>
                lesson.status == LessonStatus.completed && lesson.hasFeedback,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  return feedbackLessons.isEmpty ? null : feedbackLessons.first;
}
