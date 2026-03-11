// Teacher analytics data models.

/// Monthly trend data point for charts.
class MonthlyTrend {
  final DateTime month;
  final int lessonCount;
  final int revenue;

  const MonthlyTrend({
    required this.month,
    required this.lessonCount,
    required this.revenue,
  });
}

/// Practice ranking entry for a student.
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
}

/// Teacher monthly statistics aggregate.
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
}
