import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/analytics/data/repositories/remote_analytics_repository.dart';
import 'package:lessonaza/features/analytics/domain/entities/analytics_models.dart';

void main() {
  RemoteAnalyticsRepository repositoryWithMonthlyStats({
    required List<RequestOptions> requests,
  }) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'month': '2026-05-01T00:00:00.000',
                'total_lessons': 42,
                'completed_lessons': 38,
                'cancelled_lessons': 3,
                'no_show_lessons': 1,
                'total_revenue': 2850000,
                'revenue_change_percent': 5.2,
                'total_students': 12,
                'new_students': 2,
                'churned_students': 0,
                'attendance_rate': 90.5,
                'lesson_trend': [
                  {
                    'month': '2026-04-01T00:00:00.000',
                    'lesson_count': 36,
                    'revenue': 2700000,
                  },
                  {
                    'month': '2026-05-01T00:00:00.000',
                    'lesson_count': 42,
                    'revenue': 2850000,
                  },
                ],
                'practice_ranking': const [],
              },
              statusCode: 200,
            ),
          );
        },
      ),
    );

    return RemoteAnalyticsRepository(ApiClient(dio));
  }

  test('getRevenueAnalytics maps monthly stats instead of throwing', () async {
    final requests = <RequestOptions>[];
    final repository = repositoryWithMonthlyStats(requests: requests);

    final revenue = await repository.getRevenueAnalytics(periodMonths: 6);

    expect(requests.single.path, '/analytics/monthly-stats');
    expect(requests.single.queryParameters['month'], isNotEmpty);
    expect(revenue.currentMonthRevenue, 2850000);
    expect(revenue.revenueChangePercent, 5.2);
    expect(revenue.trend, hasLength(2));
    expect(revenue.trend.last.confirmedRevenue, 2850000);
  });

  test(
    'getStudentSummaryList returns an empty aggregate without HTTP',
    () async {
      // §589 — getStudentSummaryList 는 BE 미지원이므로 빈 집계 스텁만 반환한다.
      // getRetentionAnalytics / getStudentProgress 는 BE 지원 — 별도 테스트.
      final requests = <RequestOptions>[];
      final repository = repositoryWithMonthlyStats(requests: requests);

      final summary = await repository.getStudentSummaryList(DateTime(2026, 5));

      expect(summary, isEmpty);
      expect(requests, isEmpty);
    },
  );

  test(
    'getRetentionAnalytics calls /analytics/retention and maps at-risk students',
    () async {
      // #1216 — BE 지원 (analytics.py get_retention_analytics).
      final requests = <RequestOptions>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'renewal_rate': 0.76,
                  'avg_subscription_months': 14.2,
                  'at_risk_students': [
                    {
                      'student_id': 's005',
                      'student_name': '정하준',
                      'days_until_expiry': 7,
                      'practice_drop_percent': -40.0,
                      'last_lesson_date': '2026-04-28',
                      'risk_level': 'high',
                    },
                    {
                      'student_id': 's006',
                      'student_name': '무수강권학생',
                      'days_until_expiry': null,
                      'practice_drop_percent': 0.0,
                      'last_lesson_date': null,
                      'risk_level': 'low',
                    },
                  ],
                  'renewal_trend': [
                    {
                      'month': '2026-04-01T00:00:00',
                      'expired': 3,
                      'renewed': 2,
                    },
                  ],
                  'tenure_distribution': [
                    {'label': '0-3개월', 'count': 2},
                  ],
                },
              ),
            );
          },
        ),
      );
      final repository = RemoteAnalyticsRepository(ApiClient(dio));

      final retention = await repository.getRetentionAnalytics();

      expect(requests.single.path, '/analytics/retention');
      expect(retention.renewalRate, 0.76);
      expect(retention.avgSubscriptionMonths, 14.2);
      expect(retention.atRiskStudents, hasLength(2));

      final first = retention.atRiskStudents.first;
      expect(first.studentId, 's005');
      expect(first.studentName, '정하준');
      expect(first.daysUntilExpiry, 7);
      expect(first.practiceDropPercent, -40.0);
      expect(first.lastLessonDate, DateTime(2026, 4, 28));
      expect(first.riskLevel, RiskLevel.high);

      // 유효 수강권/레슨 이력이 없으면 null 로 매핑된다 (센티널 값 금지).
      final second = retention.atRiskStudents.last;
      expect(second.daysUntilExpiry, isNull);
      expect(second.lastLessonDate, isNull);
      expect(second.riskLevel, RiskLevel.low);

      expect(retention.renewalTrend.single.expired, 3);
      expect(retention.renewalTrend.single.renewed, 2);
      expect(retention.tenureDistribution.single.bucketLabel, '0-3개월');
      expect(retention.tenureDistribution.single.count, 2);
    },
  );

  test(
    'getStudentProgress calls /analytics/students/{id}/progress and maps response',
    () async {
      // §589 — BE 지원 (analytics.py:38 get_student_progress).
      // FE 가 실 API 응답을 StudentProgressData 에 매핑하는지 검증.
      final requests = <RequestOptions>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'student_name': '김학생',
                  'attendance_rate': 87.5,
                  'attended_lessons': 7,
                  'total_lessons': 8,
                  'practice_achievement_rate': 75.0,
                  'total_practice_minutes': 420,
                },
              ),
            );
          },
        ),
      );
      final repository = RemoteAnalyticsRepository(ApiClient(dio));

      final student = await repository.getStudentProgress(
        'student-1',
        period: AnalyticsPeriod.threeMonths,
      );

      expect(requests, hasLength(1));
      expect(requests.single.path, '/analytics/students/student-1/progress');
      expect(requests.single.queryParameters['period_days'], 90);
      expect(student.studentId, 'student-1');
      expect(student.studentName, '김학생');
      expect(student.attendanceRate, 87.5);
      expect(student.attendedLessons, 7);
      expect(student.totalLessons, 8);
      expect(student.practiceAchievementRate, 75.0);
      expect(student.totalPracticeMinutes, 420);
    },
  );
}
