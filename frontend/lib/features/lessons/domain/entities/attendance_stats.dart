// Attendance statistics entity for tracking student attendance patterns.

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attendance_stats.g.dart';

/// Monthly attendance breakdown.
@HiveType(typeId: 96)
@JsonSerializable()
class MonthlyAttendance {
  @HiveField(0)
  final int year;

  @HiveField(1)
  final int month;

  @HiveField(2)
  final int totalLessons;

  @HiveField(3)
  final int completed;

  @HiveField(4)
  final int studentAbsent;

  @HiveField(5)
  final int teacherCancelled;

  @HiveField(6)
  final int noShow;

  @HiveField(7)
  final int mutualCancelled;

  @HiveField(8)
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
@HiveType(typeId: 97)
@JsonSerializable()
class AttendanceStats {
  @HiveField(0)
  final String studentId;

  @HiveField(1)
  final int totalLessons;

  @HiveField(2)
  final int completedLessons;

  @HiveField(3)
  final int absentCount;

  @HiveField(4)
  final int noShowCount;

  @HiveField(5)
  final int cancelledByStudentLateCount;

  @HiveField(6)
  final int cancelledByTeacherCount;

  @HiveField(7)
  final int mutualCancelledCount;

  @HiveField(8)
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

  int get totalDeducted => completedLessons + absentCount + noShowCount + cancelledByStudentLateCount;

  int get totalNotDeducted => cancelledByTeacherCount + mutualCancelledCount;

  factory AttendanceStats.fromJson(Map<String, dynamic> json) =>
      _$AttendanceStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceStatsToJson(this);
}
