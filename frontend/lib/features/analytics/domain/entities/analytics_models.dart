// Analytics domain models — student progress, revenue, retention.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §3

/// Weekly practice summary data point for line chart.
class WeeklyPracticePoint {
  final DateTime weekStart;
  final int totalMinutes;
  final double achievementRate; // 0.0 ~ 1.0
  final int activeDays; // 1~7

  const WeeklyPracticePoint({
    required this.weekStart,
    required this.totalMinutes,
    required this.achievementRate,
    required this.activeDays,
  });
}

/// Attendance status for a single lesson day.
enum AttendanceStatus { present, absent, cancelled, noLesson }

/// Calendar data point for attendance heatmap.
class AttendanceDay {
  final DateTime date;
  final AttendanceStatus status;

  const AttendanceDay({required this.date, required this.status});
}

/// Repertoire piece progress status.
enum RepertoireStatus { planned, inProgress, completed }

/// Repertoire progress item for timeline/list.
class RepertoirePiece {
  final String pieceId;
  final String title;
  final String? bookTitle;
  final RepertoireStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? masteryPercent; // 0~100, null if not started

  const RepertoirePiece({
    required this.pieceId,
    required this.title,
    this.bookTitle,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.masteryPercent,
  });
}

/// Recording timeline entry.
class RecordingEntry {
  final String recordingId;
  final String? pieceTitle;
  final DateTime recordedAt;
  final int durationSeconds;
  final String? teacherNote;

  const RecordingEntry({
    required this.recordingId,
    this.pieceTitle,
    required this.recordedAt,
    required this.durationSeconds,
    this.teacherNote,
  });
}

/// Lesson feedback highlight.
class FeedbackHighlight {
  final String lessonId;
  final DateTime lessonDate;
  final String summaryText;

  const FeedbackHighlight({
    required this.lessonId,
    required this.lessonDate,
    required this.summaryText,
  });
}

/// Student progress aggregate (teacher view, scoped to a period).
class StudentProgressData {
  final String studentId;
  final String studentName;
  final String? instrumentType;
  final double attendanceRate; // 0.0 ~ 1.0
  final int attendedLessons;
  final int totalLessons;
  final double practiceAchievementRate; // 0.0 ~ 1.0
  final int totalPracticeMinutes;
  final List<WeeklyPracticePoint> weeklyPractice;
  final List<AttendanceDay> attendanceCalendar;
  final List<RepertoirePiece> repertoire;
  final List<RecordingEntry> recordings;
  final List<FeedbackHighlight> feedbackHighlights;

  const StudentProgressData({
    required this.studentId,
    required this.studentName,
    this.instrumentType,
    required this.attendanceRate,
    required this.attendedLessons,
    required this.totalLessons,
    required this.practiceAchievementRate,
    required this.totalPracticeMinutes,
    required this.weeklyPractice,
    required this.attendanceCalendar,
    required this.repertoire,
    required this.recordings,
    required this.feedbackHighlights,
  });
}

/// Monthly revenue trend data point.
class MonthlyRevenueTrend {
  final DateTime month;
  final int confirmedRevenue;
  final int pendingRevenue;

  const MonthlyRevenueTrend({
    required this.month,
    required this.confirmedRevenue,
    required this.pendingRevenue,
  });
}

/// Student revenue portion for pie chart.
class StudentRevenuePortion {
  final String studentId;
  final String studentName;
  final int amount;
  final double percent; // 0.0 ~ 1.0

  const StudentRevenuePortion({
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.percent,
  });
}

/// Revenue analytics aggregate for teacher.
class RevenueAnalyticsData {
  final int currentMonthRevenue;
  final double revenueChangePercent;
  final int pendingAmount;
  final int pendingCount;
  final int expectedMonthlyRevenue;
  final int expiringSubscriptionCount;
  final List<MonthlyRevenueTrend> trend;
  final List<StudentRevenuePortion> breakdown;

  const RevenueAnalyticsData({
    required this.currentMonthRevenue,
    required this.revenueChangePercent,
    required this.pendingAmount,
    required this.pendingCount,
    required this.expectedMonthlyRevenue,
    required this.expiringSubscriptionCount,
    required this.trend,
    required this.breakdown,
  });
}

/// Student risk level for retention analysis.
enum RiskLevel { high, medium, low }

/// At-risk student for retention screen.
class AtRiskStudent {
  final String studentId;
  final String studentName;

  /// Null when the student has no live subscription (no expiry date exists).
  final int? daysUntilExpiry;

  /// Negative means practice volume declined.
  final double practiceDropPercent;

  /// Null when the student has no lesson history yet.
  final DateTime? lastLessonDate;
  final RiskLevel riskLevel;

  const AtRiskStudent({
    required this.studentId,
    required this.studentName,
    required this.daysUntilExpiry,
    required this.practiceDropPercent,
    required this.lastLessonDate,
    required this.riskLevel,
  });
}

/// Monthly renewal trend data point.
class MonthlyRenewalTrend {
  final DateTime month;
  final int expired;
  final int renewed;

  const MonthlyRenewalTrend({
    required this.month,
    required this.expired,
    required this.renewed,
  });
}

/// Tenure distribution bucket.
class TenureDistribution {
  final String bucketLabel;
  final int count;

  const TenureDistribution({required this.bucketLabel, required this.count});
}

/// Retention analytics aggregate for teacher.
class RetentionAnalyticsData {
  final double renewalRate; // 0.0 ~ 1.0
  final double avgSubscriptionMonths;
  final List<AtRiskStudent> atRiskStudents;
  final List<MonthlyRenewalTrend> renewalTrend;
  final List<TenureDistribution> tenureDistribution;

  const RetentionAnalyticsData({
    required this.renewalRate,
    required this.avgSubscriptionMonths,
    required this.atRiskStudents,
    required this.renewalTrend,
    required this.tenureDistribution,
  });
}

/// Analytics query period.
enum AnalyticsPeriod { oneMonth, threeMonths, sixMonths, oneYear }

/// Student summary item for the monthly summary tab list.
class StudentSummaryItem {
  final String studentId;
  final String studentName;
  final String? instrumentType;
  final double practiceRate; // 0.0 ~ 1.0
  final double attendanceRate; // 0.0 ~ 1.0
  final int practiceMinutesPerWeek;

  const StudentSummaryItem({
    required this.studentId,
    required this.studentName,
    this.instrumentType,
    required this.practiceRate,
    required this.attendanceRate,
    required this.practiceMinutesPerWeek,
  });
}
