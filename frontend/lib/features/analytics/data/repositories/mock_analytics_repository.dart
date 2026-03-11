// Mock analytics repository with test data.

import '../../domain/entities/teacher_stats.dart';

class MockAnalyticsRepository {
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
      practiceRanking: [
        const StudentPracticeRank(
          studentId: 'student_1',
          studentName: '김민수',
          instrument: '바이올린',
          practiceRate: 0.85,
          practiceMinutes: 420,
        ),
        const StudentPracticeRank(
          studentId: 'student_2',
          studentName: '이서연',
          instrument: '바이올린',
          practiceRate: 0.72,
          practiceMinutes: 350,
        ),
        const StudentPracticeRank(
          studentId: 'student_3',
          studentName: '박지호',
          instrument: '첼로',
          practiceRate: 0.65,
          practiceMinutes: 310,
        ),
        const StudentPracticeRank(
          studentId: 'student_4',
          studentName: '최예은',
          instrument: '피아노',
          practiceRate: 0.58,
          practiceMinutes: 280,
        ),
        const StudentPracticeRank(
          studentId: 'student_5',
          studentName: '정하준',
          instrument: '바이올린',
          practiceRate: 0.45,
          practiceMinutes: 200,
        ),
      ],
    );
  }
}
