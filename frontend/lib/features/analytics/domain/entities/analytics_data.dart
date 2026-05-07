// Analytics data models for teacher dashboard and student progress views.

/// Monthly summary for teacher dashboard.
class TeacherMonthlySummary {
  final int totalLessons;
  final int completedLessons;
  final int cancelledLessons;
  final double completionRate; // 0.0~1.0
  final int totalRevenue; // KRW
  final int confirmedRevenue; // Paid
  final int pendingRevenue; // Unpaid
  final int activeStudents;
  final int expiredStudents;
  final int trialStudents;
  final int totalTravelMinutes;
  final String month; // "2026-05"

  const TeacherMonthlySummary({
    required this.totalLessons,
    required this.completedLessons,
    required this.cancelledLessons,
    required this.completionRate,
    required this.totalRevenue,
    required this.confirmedRevenue,
    required this.pendingRevenue,
    required this.activeStudents,
    required this.expiredStudents,
    required this.trialStudents,
    required this.totalTravelMinutes,
    required this.month,
  });
}

/// Weekly practice summary data point.
class WeeklyPracticeSummary {
  final DateTime weekStart;
  final int practiceMinutes;
  final int targetMinutes;
  final int daysCompleted;

  const WeeklyPracticeSummary({
    required this.weekStart,
    required this.practiceMinutes,
    required this.targetMinutes,
    required this.daysCompleted,
  });
}

/// Attendance status for a single calendar day.
class AttendanceDay {
  final DateTime date;
  final bool attended;
  final bool cancelled;

  const AttendanceDay({
    required this.date,
    required this.attended,
    required this.cancelled,
  });
}

/// Repertoire piece progress item.
class RepertoireProgressItem {
  final String title;
  final double completionRate; // 0.0~1.0
  final int totalSections;
  final int completedSections;

  const RepertoireProgressItem({
    required this.title,
    required this.completionRate,
    required this.totalSections,
    required this.completedSections,
  });
}

/// Student progress data for teacher analytics view.
class StudentProgress {
  final String studentId;
  final String studentName;
  final String instrument;
  final List<WeeklyPracticeSummary> weeklyPractice;
  final List<AttendanceDay> attendance;
  final List<RepertoireProgressItem> repertoire;
  final int totalPracticeMinutes;
  final int practiceStreak; // Consecutive days
  final double attendanceRate; // 0.0~1.0

  const StudentProgress({
    required this.studentId,
    required this.studentName,
    required this.instrument,
    required this.weeklyPractice,
    required this.attendance,
    required this.repertoire,
    required this.totalPracticeMinutes,
    required this.practiceStreak,
    required this.attendanceRate,
  });
}

/// Monthly revenue data point for trend charts.
class MonthlyRevenue {
  final String month; // "2026-05"
  final int amount;

  const MonthlyRevenue({
    required this.month,
    required this.amount,
  });
}

/// Student revenue breakdown entry.
class StudentRevenue {
  final String studentId;
  final String studentName;
  final int amount;
  final double percentage; // 0.0~1.0

  const StudentRevenue({
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.percentage,
  });
}

/// Revenue analytics aggregate for teacher.
class RevenueAnalytics {
  final List<MonthlyRevenue> monthlyTrend;
  final List<StudentRevenue> studentBreakdown;
  final int totalUnpaid;
  final int projectedMonthly;

  const RevenueAnalytics({
    required this.monthlyTrend,
    required this.studentBreakdown,
    required this.totalUnpaid,
    required this.projectedMonthly,
  });
}

/// Student's own analytics summary (student home view).
class StudentAnalyticsSummary {
  final int weeklyGoalMinutes;
  final int weeklyAchievedMinutes;
  final int currentStreak;
  final int longestStreak;
  final int completedLessons;
  final int totalRepertoire;
  final int completedRepertoire;

  const StudentAnalyticsSummary({
    required this.weeklyGoalMinutes,
    required this.weeklyAchievedMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedLessons,
    required this.totalRepertoire,
    required this.completedRepertoire,
  });
}
