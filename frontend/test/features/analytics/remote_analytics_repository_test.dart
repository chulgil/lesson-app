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
    'unsupported remote analytics sections return empty aggregates',
    () async {
      final requests = <RequestOptions>[];
      final repository = repositoryWithMonthlyStats(requests: requests);

      final student = await repository.getStudentProgress(
        'student-1',
        period: AnalyticsPeriod.threeMonths,
      );
      final retention = await repository.getRetentionAnalytics();
      final summary = await repository.getStudentSummaryList(DateTime(2026, 5));

      expect(student.studentId, 'student-1');
      expect(student.studentName, '학생');
      expect(student.weeklyPractice, isEmpty);
      expect(retention.atRiskStudents, isEmpty);
      expect(retention.renewalTrend, isEmpty);
      expect(summary, isEmpty);
      expect(requests, isEmpty);
    },
  );
}
