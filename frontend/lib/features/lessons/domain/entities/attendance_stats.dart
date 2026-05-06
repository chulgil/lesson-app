// Attendance statistics entity for tracking student attendance patterns.

import 'package:json_annotation/json_annotation.dart';

part 'attendance_stats.g.dart';

/// Monthly attendance breakdown.
@JsonSerializable()
class MonthlyAttendance {
  final int year;

  final int month;

  final int totalLessons;

  final int completed;

  final int studentAbsent;

  final int teacherCancelled;

  final int noShow;

  final int mutualCancelled;

  final int cancelledByStudentLate;

  const MonthlyAttendance({
    required this.year,
    required this.month,
    this.totalLessons = 0,
    this.completed = 0,
    this.studentAbsent = 0,
    this.teacherCancelled = 0,
    this.noShow = 0,
    this.mutualCancelled = 0,
    this.cancelledByStudentLate = 0,
  });

  double get attendanceRate =>
      totalLessons > 0 ? completed / totalLessons * 100 : 0;

  String get monthLabel => '$month월';

  factory MonthlyAttendance.fromJson(Map<String, dynamic> json) =>
      _$MonthlyAttendanceFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyAttendanceToJson(this);
}

/// Student attendance statistics.
@JsonSerializable()
class AttendanceStats {
  final String studentId;

  final int totalLessons;

  final int completedLessons;

  final int absentCount;

  final int noShowCount;

  final int cancelledByStudentLateCount;

  final int cancelledByTeacherCount;

  final int mutualCancelledCount;

  final List<MonthlyAttendance> monthlyBreakdown;

  const AttendanceStats({
    required this.studentId,
    this.totalLessons = 0,
    this.completedLessons = 0,
    this.absentCount = 0,
    this.noShowCount = 0,
    this.cancelledByStudentLateCount = 0,
    this.cancelledByTeacherCount = 0,
    this.mutualCancelledCount = 0,
    this.monthlyBreakdown = const [],
  });

  double get attendanceRate =>
      totalLessons > 0 ? completedLessons / totalLessons * 100 : 0;

  int get totalDeducted =>
      completedLessons +
      absentCount +
      noShowCount +
      cancelledByStudentLateCount;

  int get totalNotDeducted => cancelledByTeacherCount + mutualCancelledCount;

  factory AttendanceStats.fromJson(Map<String, dynamic> json) =>
      _$AttendanceStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceStatsToJson(this);
}
