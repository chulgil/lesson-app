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

/// Teacher-wide attendance overview: per-student rates + recent absences.
@riverpod
Future<TeacherAttendanceOverview> teacherAttendanceOverview(
  TeacherAttendanceOverviewRef ref,
) async {
  final lessons = await ref.watch(lessonsProvider.future);
  final now = DateTime.now();

  // Only past lessons
  final pastLessons = lessons.where((l) =>
      l.date.isBefore(now) || l.status != LessonStatus.scheduled).toList();

  // Group by student
  final byStudent = <String, List<Lesson>>{};
  for (final lesson in pastLessons) {
    byStudent.putIfAbsent(lesson.studentId, () => []).add(lesson);
  }

  int totalCompleted = 0;
  int totalCountable = 0;
  final studentRates = <StudentAttendanceRate>[];
  final recentAbsences = <AbsenceRecord>[];

  for (final entry in byStudent.entries) {
    int completed = 0;
    int countable = 0;

    for (final lesson in entry.value) {
      if (lesson.status.isDeducted) {
        countable++;
        if (lesson.status == LessonStatus.completed) {
          completed++;
        }
      }
      // Collect absence/noShow records
      if (lesson.status == LessonStatus.studentAbsent ||
          lesson.status == LessonStatus.noShow ||
          lesson.status == LessonStatus.cancelledByStudentLate) {
        recentAbsences.add(AbsenceRecord(
          studentId: lesson.studentId,
          date: lesson.date,
          status: lesson.status,
        ));
      }
    }

    totalCompleted += completed;
    totalCountable += countable;

    if (countable > 0) {
      studentRates.add(StudentAttendanceRate(
        studentId: entry.key,
        completed: completed,
        total: countable,
      ));
    }
  }

  // Sort students by rate ascending (lowest first for attention)
  studentRates.sort((a, b) => a.rate.compareTo(b.rate));

  // Sort absences by date descending (most recent first)
  recentAbsences.sort((a, b) => b.date.compareTo(a.date));

  return TeacherAttendanceOverview(
    totalCompleted: totalCompleted,
    totalCountable: totalCountable,
    studentRates: studentRates,
    recentAbsences: recentAbsences.take(10).toList(),
  );
}

/// Teacher attendance overview data.
class TeacherAttendanceOverview {
  final int totalCompleted;
  final int totalCountable;
  final List<StudentAttendanceRate> studentRates;
  final List<AbsenceRecord> recentAbsences;

  const TeacherAttendanceOverview({
    required this.totalCompleted,
    required this.totalCountable,
    required this.studentRates,
    required this.recentAbsences,
  });

  double get overallRate =>
      totalCountable > 0 ? totalCompleted / totalCountable * 100 : 0;
}

/// Per-student attendance rate.
class StudentAttendanceRate {
  final String studentId;
  final int completed;
  final int total;

  const StudentAttendanceRate({
    required this.studentId,
    required this.completed,
    required this.total,
  });

  double get rate => total > 0 ? completed / total * 100 : 0;
}

/// Single absence/noShow record.
class AbsenceRecord {
  final String studentId;
  final DateTime date;
  final LessonStatus status;

  const AbsenceRecord({
    required this.studentId,
    required this.date,
    required this.status,
  });
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
