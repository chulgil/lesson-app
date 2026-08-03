import '../../../../core/network/api_client.dart';
import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/teacher_stats.dart';
import '../../domain/repositories/analytics_repository.dart';

/// Remote implementation of [AnalyticsRepository] using FastAPI backend.
class RemoteAnalyticsRepository implements AnalyticsRepository {
  final ApiClient _apiClient;

  RemoteAnalyticsRepository(this._apiClient);

  @override
  Future<TeacherMonthlyStats> getTeacherMonthlyStats(DateTime month) async {
    final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final response = await _apiClient.get(
      '/analytics/monthly-stats',
      queryParameters: {'month': monthStr},
    );
    return TeacherMonthlyStats.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<StudentProgressData> getStudentProgress(
    String studentId, {
    required AnalyticsPeriod period,
  }) async {
    final periodDays = switch (period) {
      AnalyticsPeriod.oneMonth => 30,
      AnalyticsPeriod.threeMonths => 90,
      AnalyticsPeriod.sixMonths => 180,
      AnalyticsPeriod.oneYear => 365,
    };

    final response = await _apiClient.get(
      '/analytics/students/$studentId/progress',
      queryParameters: {'period_days': periodDays},
    );
    final data = response.data as Map<String, dynamic>;
    return StudentProgressData(
      studentId: studentId,
      studentName: data['student_name'] as String? ?? '',
      attendanceRate: ((data['attendance_rate'] as num?) ?? 0).toDouble(),
      attendedLessons: (data['attended_lessons'] as int?) ?? 0,
      totalLessons: (data['total_lessons'] as int?) ?? 0,
      practiceAchievementRate:
          ((data['practice_achievement_rate'] as num?) ?? 0).toDouble(),
      totalPracticeMinutes: (data['total_practice_minutes'] as int?) ?? 0,
      weeklyPractice: const [],
      attendanceCalendar: const [],
      repertoire: const [],
      recordings: const [],
      feedbackHighlights: const [],
    );
  }

  @override
  Future<RevenueAnalyticsData> getRevenueAnalytics({
    required int periodMonths,
  }) async {
    final stats = await getTeacherMonthlyStats(DateTime.now());
    return RevenueAnalyticsData(
      currentMonthRevenue: stats.totalRevenue,
      revenueChangePercent: stats.revenueChangePercent,
      pendingAmount: 0,
      pendingCount: 0,
      expectedMonthlyRevenue: stats.totalRevenue,
      expiringSubscriptionCount: 0,
      trend:
          stats.lessonTrend
              .take(periodMonths)
              .map(
                (trend) => MonthlyRevenueTrend(
                  month: trend.month,
                  confirmedRevenue: trend.revenue,
                  pendingRevenue: 0,
                ),
              )
              .toList(),
      breakdown: const [],
    );
  }

  @override
  Future<RetentionAnalyticsData> getRetentionAnalytics() async {
    final response = await _apiClient.get('/analytics/retention');
    final data = response.data as Map<String, dynamic>;
    return RetentionAnalyticsData(
      renewalRate: ((data['renewal_rate'] as num?) ?? 0).toDouble(),
      avgSubscriptionMonths:
          ((data['avg_subscription_months'] as num?) ?? 0).toDouble(),
      atRiskStudents: _mapList(data['at_risk_students'], _atRiskStudent),
      renewalTrend: _mapList(data['renewal_trend'], _renewalTrend),
      tenureDistribution: _mapList(data['tenure_distribution'], _tenureBucket),
    );
  }

  @override
  Future<List<StudentSummaryItem>> getStudentSummaryList(DateTime month) async {
    return const [];
  }
}

List<T> _mapList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) map,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(map)
      .toList(growable: false);
}

AtRiskStudent _atRiskStudent(Map<String, dynamic> json) {
  final lastLesson = json['last_lesson_date'] as String?;
  return AtRiskStudent(
    studentId: json['student_id'] as String? ?? '',
    studentName: json['student_name'] as String? ?? '',
    daysUntilExpiry: (json['days_until_expiry'] as num?)?.toInt(),
    practiceDropPercent:
        ((json['practice_drop_percent'] as num?) ?? 0).toDouble(),
    lastLessonDate: lastLesson == null ? null : DateTime.tryParse(lastLesson),
    riskLevel: _riskLevel(json['risk_level'] as String?),
  );
}

RiskLevel _riskLevel(String? raw) => switch (raw) {
  'high' => RiskLevel.high,
  'medium' => RiskLevel.medium,
  _ => RiskLevel.low,
};

MonthlyRenewalTrend _renewalTrend(Map<String, dynamic> json) =>
    MonthlyRenewalTrend(
      month: DateTime.tryParse(json['month'] as String? ?? '') ?? DateTime(0),
      expired: (json['expired'] as num?)?.toInt() ?? 0,
      renewed: (json['renewed'] as num?)?.toInt() ?? 0,
    );

TenureDistribution _tenureBucket(Map<String, dynamic> json) =>
    TenureDistribution(
      bucketLabel: json['label'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
