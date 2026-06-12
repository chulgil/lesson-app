import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/auth/presentation/providers/user_role_provider.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';
import 'package:lessonaza/features/gamification/domain/entities/student_quest.dart';
import 'package:lessonaza/features/gamification/presentation/providers/student_quest_provider.dart';
import 'package:lessonaza/features/lessons/presentation/providers/booking_providers.dart';
import 'package:lessonaza/features/student_home/domain/entities/student_lesson_progress_item.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_lesson_progress_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_dashboard_tab.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/dashboard/next_lesson_card.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/student_lesson_progress_section.dart';

/// dashboard 본문 레이아웃 검증용 — onboarding trigger 가 가로채지 않도록
/// active quest 1개를 주입한다 (trigger takeover 경로는
/// student_gamification_onboarding_trigger_test 가 담당).
StudentQuest _activeQuest(String studentId) {
  final today = DateTime(2026, 6, 12);
  return StudentQuest(
    id: 'q1',
    studentId: studentId,
    origin: QuestOrigin.systemRoutine,
    title: '스케일 5분',
    type: ChallengeType.practiceMinutes,
    targetValue: 5,
    currentValue: 0,
    startDate: today,
    endDate: today.add(const Duration(days: 7)),
  );
}

void main() {
  testWidgets(
    'student dashboard lays out action widgets without metadata crash',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('student_1'),
            studentLessonProgressProvider(
              'student_1',
            ).overrideWith((ref) async => const []),
            activeQuestsProvider(
              'student_1',
            ).overrideWith((ref) async => [_activeQuest('student_1')]),
          ],
          child: const MaterialApp(home: Scaffold(body: StudentDashboardTab())),
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
      startTime: const ClockTime(hour: 17, minute: 30),
      endTime: const ClockTime(hour: 18, minute: 30),
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

  testWidgets('student dashboard uses lesson progress timeline section', (
    tester,
  ) async {
    const studentId = 'student_1';
    final item = StudentLessonProgressItem(
      id: 'progress_1',
      kind: StudentLessonProgressKind.scheduleConfirmation,
      priority: StudentLessonProgressPriority.actionRequired,
      title: '수강권이 준비됐어요',
      subtitle: '첫 레슨 시간을 확인해주세요',
      statusLabel: '확인 필요',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(studentId),
          studentLessonProgressProvider(
            studentId,
          ).overrideWith((ref) async => [item]),
          activeQuestsProvider(
            studentId,
          ).overrideWith((ref) async => [_activeQuest(studentId)]),
        ],
        child: const MaterialApp(home: Scaffold(body: StudentDashboardTab())),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(StudentLessonProgressSection), findsOneWidget);
    expect(find.text('레슨 진행 · 1'), findsOneWidget);
  });
}
