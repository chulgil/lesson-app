// Mock analytics service generating realistic test data for the analytics dashboard.

import '../../domain/entities/analytics_data.dart';

/// Mock implementation of analytics data generation.
/// Returns deterministic realistic data for UI development and testing.
class MockAnalyticsService {
  static const _studentIds = [
    'student_001',
    'student_002',
    'student_003',
    'student_004',
    'student_005',
    'student_006',
  ];

  static const _studentNames = ['김민수', '이서연', '박지호', '최예린', '정하준', '강유진'];

  static const _instruments = [
    '바이올린',
    '바이올린',
    '첼로',
    '피아노',
    '바이올린',
    '비올라',
  ];

  /// Returns monthly summary for teacher dashboard.
  ///
  /// Generates ~18 lessons with 87% completion rate and realistic revenue.
  Future<TeacherMonthlySummary> getTeacherMonthlySummary({
    required int year,
    required int month,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    const totalLessons = 18;
    const completedLessons = 16;
    const cancelledLessons = 2;

    return TeacherMonthlySummary(
      totalLessons: totalLessons,
      completedLessons: completedLessons,
      cancelledLessons: cancelledLessons,
      completionRate: completedLessons / totalLessons,
      totalRevenue: 420000,
      confirmedRevenue: 360000,
      pendingRevenue: 60000,
      activeStudents: 5,
      expiredStudents: 1,
      trialStudents: 1,
      totalTravelMinutes: 320,
      month: '$year-${month.toString().padLeft(2, '0')}',
    );
  }

  /// Returns detailed practice and attendance data for a specific student.
  ///
  /// [months] controls how many weeks of weekly practice data to generate (1 month ≈ 4 weeks).
  Future<StudentProgress> getStudentProgress({
    required String studentId,
    required int months,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final index = _studentIds.indexOf(studentId);
    final safeIndex = index < 0 ? 0 : index;
    final name = _studentNames[safeIndex];
    final instrument = _instruments[safeIndex];

    final now = DateTime.now();
    final weekCount = months * 4;

    // Practice minutes vary by student: 30–60 min/day, 3–6 days/week.
    final baseMinutes = 30 + (safeIndex * 5);
    final targetMinutes = 150; // 30 min × 5 days

    final weeklyPractice = List.generate(weekCount, (i) {
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day - (weekCount - i) * 7,
      );
      final minutes = (baseMinutes + (i % 3) * 15).clamp(20, 180);
      final days = (3 + (i % 3)).clamp(1, 7);
      return WeeklyPracticeSummary(
        weekStart: weekStart,
        practiceMinutes: minutes,
        targetMinutes: targetMinutes,
        daysCompleted: days,
      );
    });

    // Attendance: 90% rate with occasional cancellation.
    final lessonCount = months * 4;
    final attendance = List.generate(lessonCount, (i) {
      final date = DateTime(
        now.year,
        now.month,
        now.day - (lessonCount - i) * 7,
      );
      final attended = i % 10 != 3; // ~90% attendance
      final cancelled = !attended && i % 10 == 3 && i % 20 == 3;
      return AttendanceDay(
        date: date,
        attended: attended,
        cancelled: cancelled,
      );
    });

    // Repertoire: 2–3 pieces at varying stages.
    final repertoire = [
      RepertoireProgressItem(
        title: 'Gavotte',
        completionRate: 1.0,
        totalSections: 4,
        completedSections: 4,
      ),
      RepertoireProgressItem(
        title: 'Minuet',
        completionRate: 0.60 + (safeIndex * 0.04),
        totalSections: 5,
        completedSections: 3,
      ),
      if (safeIndex < 3)
        const RepertoireProgressItem(
          title: 'Bourrée',
          completionRate: 0.0,
          totalSections: 4,
          completedSections: 0,
        ),
    ];

    final totalPracticeMinutes = weeklyPractice.fold<int>(
      0,
      (sum, w) => sum + w.practiceMinutes,
    );

    return StudentProgress(
      studentId: studentId,
      studentName: name,
      instrument: instrument,
      weeklyPractice: weeklyPractice,
      attendance: attendance,
      repertoire: repertoire,
      totalPracticeMinutes: totalPracticeMinutes,
      practiceStreak: 5 + safeIndex * 2,
      attendanceRate: 0.85 + (safeIndex * 0.02).clamp(0.0, 0.15),
    );
  }

  /// Returns revenue analytics with 6-month trend and student breakdown.
  Future<RevenueAnalytics> getRevenueAnalytics({required int months}) async {
    await Future.delayed(const Duration(milliseconds: 220));

    final now = DateTime.now();
    final count = months.clamp(1, 12);

    // Monthly trend: 300k–500k range with slight growth.
    final monthlyTrend = List.generate(count, (i) {
      final m = DateTime(now.year, now.month - (count - 1) + i);
      final monthStr =
          '${m.year}-${m.month.toString().padLeft(2, '0')}';
      final base = 320000;
      final growth = i * 15000;
      return MonthlyRevenue(month: monthStr, amount: base + growth);
    });

    // Student breakdown: 5 students, roughly equal shares.
    const totalRevenue = 420000;
    final portions = [0.28, 0.22, 0.18, 0.17, 0.15];
    final studentBreakdown = List.generate(5, (i) {
      final amount = (totalRevenue * portions[i]).round();
      return StudentRevenue(
        studentId: _studentIds[i],
        studentName: _studentNames[i],
        amount: amount,
        percentage: portions[i],
      );
    });

    return RevenueAnalytics(
      monthlyTrend: monthlyTrend,
      studentBreakdown: studentBreakdown,
      totalUnpaid: 60000,
      projectedMonthly: 440000,
    );
  }

  /// Returns analytics summary for a student's own view.
  Future<StudentAnalyticsSummary> getStudentAnalyticsSummary({
    required String studentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 180));

    final index = _studentIds.indexOf(studentId);
    final safeIndex = index < 0 ? 0 : index;

    return StudentAnalyticsSummary(
      weeklyGoalMinutes: 150, // 30 min × 5 days
      weeklyAchievedMinutes: 80 + safeIndex * 10,
      currentStreak: 5 + safeIndex * 2,
      longestStreak: 14 + safeIndex,
      completedLessons: 8 + safeIndex,
      totalRepertoire: 3,
      completedRepertoire: safeIndex > 2 ? 2 : 1,
    );
  }

  /// Returns all student IDs available in mock data.
  List<String> get availableStudentIds => List.unmodifiable(_studentIds);
}
