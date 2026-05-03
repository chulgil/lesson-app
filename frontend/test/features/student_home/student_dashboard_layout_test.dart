import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/features/lessons/presentation/providers/booking_providers.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_dashboard_tab.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/dashboard/next_lesson_card.dart';

void main() {
  testWidgets(
    'student dashboard lays out action widgets without metadata crash',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: StudentDashboardTab())),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Fine.'), findsOneWidget);
    },
  );

  testWidgets('next lesson card lays out with confirmed booking content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final booking = LessonBooking(
      id: 'booking-1',
      teacherId: 'teacher-1',
      teacherName: '아주 긴 이름의 선생님',
      studentId: 'student-1',
      studentName: '학생',
      instrument: '바이올린',
      lessonType: LessonType.regular,
      status: BookingStatus.confirmed,
      lessonDate: DateTime.now().add(const Duration(days: 3)),
      startTime: const TimeOfDay(hour: 17, minute: 30),
      endTime: const TimeOfDay(hour: 18, minute: 30),
      fee: 60000,
      createdAt: DateTime.utc(2026, 5, 4),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentBookingsProvider(
            'student-1',
          ).overrideWith((ref) async => [booking]),
        ],
        child: const MaterialApp(
          home: Scaffold(body: NextLessonCard(studentId: 'student-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('다음 레슨'), findsOneWidget);
  });
}
