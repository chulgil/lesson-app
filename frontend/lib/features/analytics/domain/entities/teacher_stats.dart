// Teacher analytics data models.

import 'package:json_annotation/json_annotation.dart';

part 'teacher_stats.g.dart';

/// Monthly trend data point for charts.
@JsonSerializable()
class MonthlyTrend {
  final DateTime month;
  final int lessonCount;
  final int revenue;

  const MonthlyTrend({
    required this.month,
    required this.lessonCount,
    required this.revenue,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTrendFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyTrendToJson(this);
}

/// Practice ranking entry for a student.
@JsonSerializable()
class StudentPracticeRank {
  final String studentId;
  final String studentName;
  final String instrument;
  final double practiceRate;
  final int practiceMinutes;

  const StudentPracticeRank({
    required this.studentId,
    required this.studentName,
    required this.instrument,
    required this.practiceRate,
    required this.practiceMinutes,
  });

  factory StudentPracticeRank.fromJson(Map<String, dynamic> json) =>
      _$StudentPracticeRankFromJson(json);

  Map<String, dynamic> toJson() => _$StudentPracticeRankToJson(this);
}

/// Teacher monthly statistics aggregate.
@JsonSerializable()
class TeacherMonthlyStats {
  final DateTime month;
  final int totalLessons;
  final int completedLessons;
  final int cancelledLessons;
  final int noShowLessons;
  final int totalRevenue;
  final double revenueChangePercent;
  final int totalStudents;
  final int newStudents;
  final int churnedStudents;
  final double attendanceRate;
  final List<MonthlyTrend> lessonTrend;
  final List<StudentPracticeRank> practiceRanking;

  const TeacherMonthlyStats({
    required this.month,
    required this.totalLessons,
    required this.completedLessons,
    required this.cancelledLessons,
    required this.noShowLessons,
    required this.totalRevenue,
    required this.revenueChangePercent,
    required this.totalStudents,
    required this.newStudents,
    required this.churnedStudents,
    required this.attendanceRate,
    required this.lessonTrend,
    required this.practiceRanking,
  });

  factory TeacherMonthlyStats.fromJson(Map<String, dynamic> json) =>
      _$TeacherMonthlyStatsFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherMonthlyStatsToJson(this);
}
