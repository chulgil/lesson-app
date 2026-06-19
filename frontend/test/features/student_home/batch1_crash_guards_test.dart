import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/analytics/domain/entities/teacher_stats.dart';
import 'package:lessonaza/features/analytics/presentation/widgets/monthly_trend_chart.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_booking_provider.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/dashboard/next_lesson_card.dart';

void main() {
  testWidgets('#73 MonthlyTrendChart: 단일 데이터 포인트에서 NaN 크래시 없이 렌더', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 400,
            child: MonthlyTrendChart(
              trendData: [
                MonthlyTrend(
                  month: DateTime(2026, 6),
                  lessonCount: 5,
                  revenue: 300000,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // 단일 포인트 → (i/(length-1)) 가 0/0=NaN 이던 버그. 이제 분모 가드.
    expect(tester.takeException(), isNull);
  });

  testWidgets('#66 NextLessonCard: 내일 자정 레슨은 "내일"로 표시 (시각 무관)', (tester) async {
    final t = DateTime.now();
    final tomorrowMidnight = DateTime(
      t.year,
      t.month,
      t.day,
    ).add(const Duration(days: 1));
    final booking = LessonBooking(
      id: 'b1',
      teacherId: 'teacher-1',
      teacherName: '김선생',
      studentId: 's1',
      studentName: '학생',
      instrument: '바이올린',
      lessonType: LessonType.regular,
      status: BookingStatus.confirmed,
      lessonDate: tomorrowMidnight,
      startTime: const ClockTime(hour: 9, minute: 0),
      endTime: const ClockTime(hour: 10, minute: 0),
      fee: 50000,
      createdAt: DateTime.utc(2026, 6, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentHomeNextLessonProvider(
            's1',
          ).overrideWith((ref) async => booking),
        ],
        child: const MaterialApp(
          home: Scaffold(body: NextLessonCard(studentId: 's1')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // difference(now) 버그면 24h 미만이라 "오늘"로 오표시. 캘린더 일자 기준이면 "내일".
    expect(find.text('내일'), findsOneWidget);
    expect(find.text('오늘'), findsNothing);
  });
}
