// Mock analytics repository with test data.

import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/teacher_stats.dart';
import '../../domain/repositories/analytics_repository.dart';

class MockAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<TeacherMonthlyStats> getTeacherMonthlyStats(DateTime month) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();

    return TeacherMonthlyStats(
      month: month,
      totalLessons: 42,
      completedLessons: 38,
      cancelledLessons: 3,
      noShowLessons: 1,
      totalRevenue: 2850000,
      revenueChangePercent: 5.2,
      totalStudents: 12,
      newStudents: 2,
      churnedStudents: 0,
      attendanceRate: 90.5,
      lessonTrend: List.generate(6, (i) {
        final m = DateTime(now.year, now.month - 5 + i);
        return MonthlyTrend(
          month: m,
          lessonCount: [32, 35, 38, 40, 36, 42][i],
          revenue: [2200000, 2400000, 2650000, 2800000, 2700000, 2850000][i],
        );
      }),
      practiceRanking: const [
        StudentPracticeRank(
          studentId: 'student_1',
          studentName: '김민수',
          instrument: '바이올린',
          practiceRate: 0.85,
          practiceMinutes: 420,
        ),
        StudentPracticeRank(
          studentId: 'student_2',
          studentName: '이서연',
          instrument: '바이올린',
          practiceRate: 0.72,
          practiceMinutes: 350,
        ),
        StudentPracticeRank(
          studentId: 'student_3',
          studentName: '박지호',
          instrument: '첼로',
          practiceRate: 0.65,
          practiceMinutes: 310,
        ),
        StudentPracticeRank(
          studentId: 'student_4',
          studentName: '최예은',
          instrument: '피아노',
          practiceRate: 0.58,
          practiceMinutes: 280,
        ),
        StudentPracticeRank(
          studentId: 'student_5',
          studentName: '정하준',
          instrument: '바이올린',
          practiceRate: 0.45,
          practiceMinutes: 200,
        ),
      ],
    );
  }

  @override
  Future<StudentProgressData> getStudentProgress(
    String studentId, {
    required AnalyticsPeriod period,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return StudentProgressData(
      studentId: studentId,
      studentName: '김민수',
      instrumentType: '바이올린',
      attendanceRate: 0.92,
      attendedLessons: 22,
      totalLessons: 24,
      practiceAchievementRate: 0.78,
      totalPracticeMinutes: 2040,
      // Streak is sourced from practiceStreakProvider (SSOT), not this field.
      // See docs/specs/practice/streak_ssot.md.
      practiceStreakDays: 0,
      weeklyPractice: [
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 3, 4),
          totalMinutes: 165,
          achievementRate: 0.85,
          activeDays: 5,
        ),
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 3, 11),
          totalMinutes: 195,
          achievementRate: 1.0,
          activeDays: 6,
        ),
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 3, 18),
          totalMinutes: 120,
          achievementRate: 0.60,
          activeDays: 4,
        ),
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 3, 25),
          totalMinutes: 180,
          achievementRate: 0.92,
          activeDays: 5,
        ),
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 4, 1),
          totalMinutes: 150,
          achievementRate: 0.75,
          activeDays: 5,
        ),
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 4, 8),
          totalMinutes: 170,
          achievementRate: 0.88,
          activeDays: 5,
        ),
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 4, 15),
          totalMinutes: 115,
          achievementRate: 0.58,
          activeDays: 4,
        ),
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 4, 22),
          totalMinutes: 185,
          achievementRate: 0.95,
          activeDays: 6,
        ),
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 4, 29),
          totalMinutes: 160,
          achievementRate: 0.82,
          activeDays: 5,
        ),
        WeeklyPracticePoint(
          weekStart: DateTime(2026, 5, 6),
          totalMinutes: 80,
          achievementRate: 0.70,
          activeDays: 3,
        ),
      ],
      attendanceCalendar: [],
      repertoire: const [
        RepertoirePiece(
          pieceId: 'piece_001',
          title: 'Gavotte',
          bookTitle: 'Suzuki Vol.3',
          status: RepertoireStatus.completed,
          startedAt: null,
          completedAt: null,
          masteryPercent: 100,
        ),
        RepertoirePiece(
          pieceId: 'piece_002',
          title: 'Minuet',
          bookTitle: 'Suzuki Vol.3',
          status: RepertoireStatus.inProgress,
          startedAt: null,
          completedAt: null,
          masteryPercent: 65,
        ),
        RepertoirePiece(
          pieceId: 'piece_003',
          title: 'Bourrée',
          bookTitle: 'Suzuki Vol.3',
          status: RepertoireStatus.planned,
          masteryPercent: null,
        ),
      ],
      recordings: [
        RecordingEntry(
          recordingId: 'rec_003',
          pieceTitle: 'Minuet',
          recordedAt: DateTime(2026, 4, 15),
          durationSeconds: 96,
          teacherNote: '마무리 단계. 활쏘기 자세 완성.',
        ),
        RecordingEntry(
          recordingId: 'rec_002',
          pieceTitle: 'Minuet',
          recordedAt: DateTime(2026, 3, 1),
          durationSeconds: 84,
          teacherNote: '2절 진입. 개선 눈에 띄어요.',
        ),
        RecordingEntry(
          recordingId: 'rec_001',
          pieceTitle: 'Minuet',
          recordedAt: DateTime(2026, 2, 1),
          durationSeconds: 70,
          teacherNote: '초견. 리듬 좋음.',
        ),
      ],
      feedbackHighlights: [
        FeedbackHighlight(
          lessonId: 'l042',
          lessonDate: DateTime(2026, 3, 20),
          summaryText: '활쏘기 자세가 크게 개선됐어요',
        ),
        FeedbackHighlight(
          lessonId: 'l038',
          lessonDate: DateTime(2026, 2, 28),
          summaryText: '비브라토 기초 도입 — 매일 5분 연습',
        ),
        FeedbackHighlight(
          lessonId: 'l034',
          lessonDate: DateTime(2026, 1, 31),
          summaryText: '3포지션 안정화. 다음 목표: 비브라토',
        ),
      ],
    );
  }

  @override
  Future<RevenueAnalyticsData> getRevenueAnalytics({
    required int periodMonths,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    return RevenueAnalyticsData(
      currentMonthRevenue: 2850000,
      revenueChangePercent: 5.2,
      pendingAmount: 450000,
      pendingCount: 2,
      expectedMonthlyRevenue: 2700000,
      expiringSubscriptionCount: 3,
      trend: List.generate(6, (i) {
        final m = DateTime(now.year, now.month - 5 + i);
        return MonthlyRevenueTrend(
          month: m,
          confirmedRevenue:
              [2300000, 2600000, 2710000, 2650000, 2710000, 2850000][i],
          pendingRevenue: [0, 150000, 0, 100000, 0, 450000][i],
        );
      }),
      breakdown: const [
        StudentRevenuePortion(
          studentId: 'student_1',
          studentName: '김민수',
          amount: 712500,
          percent: 0.25,
        ),
        StudentRevenuePortion(
          studentId: 'student_2',
          studentName: '이서연',
          amount: 513000,
          percent: 0.18,
        ),
        StudentRevenuePortion(
          studentId: 'student_3',
          studentName: '박지호',
          amount: 399000,
          percent: 0.14,
        ),
        StudentRevenuePortion(
          studentId: 'student_4',
          studentName: '최예은',
          amount: 285000,
          percent: 0.10,
        ),
        StudentRevenuePortion(
          studentId: 'student_5',
          studentName: '기타',
          amount: 940500,
          percent: 0.33,
        ),
      ],
    );
  }

  @override
  Future<RetentionAnalyticsData> getRetentionAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    return RetentionAnalyticsData(
      renewalRate: 0.76,
      avgSubscriptionMonths: 14.2,
      atRiskStudents: [
        AtRiskStudent(
          studentId: 'student_005',
          studentName: '정하준',
          daysUntilExpiry: 7,
          practiceDropPercent: -40.0,
          lastLessonDate: DateTime(2026, 4, 28),
          riskLevel: RiskLevel.high,
        ),
        AtRiskStudent(
          studentId: 'student_004',
          studentName: '최예린',
          daysUntilExpiry: 12,
          practiceDropPercent: -25.0,
          lastLessonDate: DateTime(2026, 5, 1),
          riskLevel: RiskLevel.medium,
        ),
        AtRiskStudent(
          studentId: 'student_003',
          studentName: '박지호',
          daysUntilExpiry: 21,
          practiceDropPercent: 0.0,
          lastLessonDate: DateTime(2026, 5, 3),
          riskLevel: RiskLevel.low,
        ),
      ],
      renewalTrend: List.generate(6, (i) {
        final m = DateTime(now.year, now.month - 5 + i);
        return MonthlyRenewalTrend(
          month: m,
          expired: [2, 3, 2, 4, 3, 2][i],
          renewed: [2, 2, 2, 3, 3, 2][i],
        );
      }),
      tenureDistribution: const [
        TenureDistribution(bucketLabel: '0-3개월', count: 2),
        TenureDistribution(bucketLabel: '3-6개월', count: 4),
        TenureDistribution(bucketLabel: '6-12개월', count: 3),
        TenureDistribution(bucketLabel: '12개월+', count: 3),
      ],
    );
  }

  @override
  Future<List<StudentSummaryItem>> getStudentSummaryList(DateTime month) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return const [
      StudentSummaryItem(
        studentId: 'student_1',
        studentName: '김민수',
        instrumentType: '바이올린',
        practiceRate: 0.85,
        attendanceRate: 0.92,
        practiceMinutesPerWeek: 105,
      ),
      StudentSummaryItem(
        studentId: 'student_2',
        studentName: '이서연',
        instrumentType: '바이올린',
        practiceRate: 0.72,
        attendanceRate: 1.0,
        practiceMinutesPerWeek: 88,
      ),
      StudentSummaryItem(
        studentId: 'student_3',
        studentName: '박지호',
        instrumentType: '첼로',
        practiceRate: 0.65,
        attendanceRate: 0.88,
        practiceMinutesPerWeek: 78,
      ),
      StudentSummaryItem(
        studentId: 'student_4',
        studentName: '최예은',
        instrumentType: '피아노',
        practiceRate: 0.58,
        attendanceRate: 0.95,
        practiceMinutesPerWeek: 70,
      ),
      StudentSummaryItem(
        studentId: 'student_5',
        studentName: '정하준',
        instrumentType: '바이올린',
        practiceRate: 0.45,
        attendanceRate: 0.80,
        practiceMinutesPerWeek: 50,
      ),
    ];
  }
}
