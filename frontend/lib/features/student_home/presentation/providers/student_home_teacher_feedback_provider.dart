import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lessons/lessons_facade.dart';

final studentHomeLatestTeacherFeedbackProvider = FutureProvider.autoDispose
    .family<Lesson?, String>((ref, studentId) async {
      final lessons = await ref.watch(
        lessonsByStudentProvider(studentId).future,
      );
      final feedbackLessons =
          lessons
              .where(
                (lesson) =>
                    lesson.status == LessonStatus.completed &&
                    lesson.hasFeedback,
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      return feedbackLessons.isEmpty ? null : feedbackLessons.first;
    });
