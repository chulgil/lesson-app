import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../providers/providers.dart';

/// Lessons with notes for a student (sorted newest first).
final studentLessonNotesProvider =
    FutureProvider.family<List<Lesson>, String>((ref, studentId) async {
  final lessons = await ref.watch(lessonsByStudentProvider(studentId).future);
  return lessons
      .where((l) =>
          l.feedback != null ||
          (l.keyPoints?.isNotEmpty ?? false) ||
          (l.practiceTips != null))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

/// Period filter for lesson notes.
enum NoteFilterPeriod {
  oneMonth('1개월'),
  threeMonths('3개월'),
  sixMonths('6개월'),
  all('전체');

  final String label;
  const NoteFilterPeriod(this.label);

  DateTime? get cutoffDate {
    final now = DateTime.now();
    switch (this) {
      case oneMonth:
        return now.subtract(const Duration(days: 30));
      case threeMonths:
        return now.subtract(const Duration(days: 90));
      case sixMonths:
        return now.subtract(const Duration(days: 180));
      case all:
        return null;
    }
  }
}
