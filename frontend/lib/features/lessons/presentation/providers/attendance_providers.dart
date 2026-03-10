// Providers for attendance statistics.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/attendance_stats.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_crud_provider.dart';

part 'attendance_providers.g.dart';

/// Calculate attendance stats for a student from their lessons.
@riverpod
Future<AttendanceStats> studentAttendanceStats(
  StudentAttendanceStatsRef ref,
  String studentId,
) async {
  final lessons = await ref.watch(lessonsByStudentProvider(studentId).future);

  // Only count past lessons (not future scheduled ones)
  final pastLessons = lessons.where((l) =>
      l.date.isBefore(DateTime.now()) ||
      l.status != LessonStatus.scheduled).toList();

  int completed = 0;
  int absent = 0;
  int noShow = 0;
  int cancelledByStudentLate = 0;
  int cancelledByTeacher = 0;
  int mutualCancelled = 0;

  // Monthly tracking
  final monthlyMap = <String, _MonthlyCounter>{};

  for (final lesson in pastLessons) {
    final key = '${lesson.date.year}-${lesson.date.month}';
    monthlyMap.putIfAbsent(
      key,
      () => _MonthlyCounter(lesson.date.year, lesson.date.month),
    );
    final monthly = monthlyMap[key]!;
    monthly.total++;

    switch (lesson.status) {
      case LessonStatus.completed:
        completed++;
        monthly.completed++;
      case LessonStatus.studentAbsent:
        absent++;
        monthly.studentAbsent++;
      case LessonStatus.noShow:
        noShow++;
        monthly.noShow++;
      case LessonStatus.cancelledByStudentLate:
        cancelledByStudentLate++;
        monthly.cancelledByStudentLate++;
      case LessonStatus.cancelledByTeacher:
        cancelledByTeacher++;
        monthly.teacherCancelled++;
      case LessonStatus.cancelledMutual:
        mutualCancelled++;
        monthly.mutualCancelled++;
      default:
        break;
    }
  }

  final monthlyBreakdown = monthlyMap.values
      .map((m) => MonthlyAttendance(
            year: m.year,
            month: m.month,
            totalLessons: m.total,
            completed: m.completed,
            studentAbsent: m.studentAbsent,
            teacherCancelled: m.teacherCancelled,
            noShow: m.noShow,
            mutualCancelled: m.mutualCancelled,
            cancelledByStudentLate: m.cancelledByStudentLate,
          ))
      .toList()
    ..sort((a, b) {
      final yearCmp = b.year.compareTo(a.year);
      return yearCmp != 0 ? yearCmp : b.month.compareTo(a.month);
    });

  return AttendanceStats(
    studentId: studentId,
    totalLessons: pastLessons.length,
    completedLessons: completed,
    absentCount: absent,
    noShowCount: noShow,
    cancelledByStudentLateCount: cancelledByStudentLate,
    cancelledByTeacherCount: cancelledByTeacher,
    mutualCancelledCount: mutualCancelled,
    monthlyBreakdown: monthlyBreakdown,
  );
}

class _MonthlyCounter {
  final int year;
  final int month;
  int total = 0;
  int completed = 0;
  int studentAbsent = 0;
  int noShow = 0;
  int cancelledByStudentLate = 0;
  int teacherCancelled = 0;
  int mutualCancelled = 0;

  _MonthlyCounter(this.year, this.month);
}
