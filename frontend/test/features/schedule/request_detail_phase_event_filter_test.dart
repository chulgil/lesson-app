import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/utils/request_detail_phase_filter.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/request_history_chat.dart';

void main() {
  test('timeConfirmed chat keeps the confirmed schedule decision visible', () {
    final request = UnifiedLessonRequest(
      id: 'request_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      instrument: '피아노',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      type: LessonRequestType.regular,
      status: UnifiedRequestStatus.timeConfirmed,
      createdAt: DateTime(2026, 5, 4),
    );

    final approveEvent = RequestEvent(
      id: 'event_approve',
      requestId: request.id,
      actorType: ProposerRole.teacher,
      actorId: request.teacherId,
      eventType: RequestEventType.approve,
      selectedSlotIndex: 1,
      message: '이 일정으로 확정할게요',
      createdAt: DateTime(2026, 5, 4, 18),
    );
    final paymentEvent = RequestEvent(
      id: 'event_payment',
      requestId: request.id,
      actorType: ProposerRole.teacher,
      actorId: request.teacherId,
      eventType: RequestEventType.paymentRequested,
      createdAt: DateTime(2026, 5, 4, 19),
    );

    final visible = requestDetailVisibleEventsForCurrentPhase(request, [
      approveEvent,
      paymentEvent,
    ]);

    expect(visible.map((event) => event.id), [
      'event_approve',
      'event_payment',
    ]);
  });

  testWidgets('timeConfirmed chat renders the confirmed schedule bubble', (
    tester,
  ) async {
    final request = UnifiedLessonRequest(
      id: 'request_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      instrument: '피아노',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      type: LessonRequestType.regular,
      status: UnifiedRequestStatus.timeConfirmed,
      preferredSlots: [
        const PreferredTimeSlot(
          priority: 1,
          dayOfWeek: 1,
          startTime: '18:00',
          endTime: '19:00',
        ),
        const PreferredTimeSlot(
          priority: 2,
          dayOfWeek: 3,
          startTime: '17:00',
          endTime: '18:00',
        ),
      ],
      createdAt: DateTime(2026, 5, 4),
    );
    final approveEvent = RequestEvent(
      id: 'event_approve',
      requestId: request.id,
      actorType: ProposerRole.teacher,
      actorId: request.teacherId,
      eventType: RequestEventType.approve,
      selectedSlotIndex: 1,
      message: '이 일정으로 확정할게요',
      createdAt: DateTime(2026, 5, 4, 18),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RequestHistoryChat(
            events: requestDetailVisibleEventsForCurrentPhase(request, [
              approveEvent,
            ]),
            viewerId: request.teacherId,
            viewerRole: 'teacher',
            studentName: '김민준',
            request: request,
            showGuide: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.chatApprove), findsNothing);
    expect(find.text(AppStrings.lessonScheduleConfirmed), findsOneWidget);
    expect(find.text('목 17:00 ~ 18:00'), findsOneWidget);
    expect(find.text('이 일정으로 확정할게요'), findsOneWidget);
    final roundedBubbleDecorations = tester
        .widgetList<Container>(find.byType(Container))
        .where((container) => container.decoration is BoxDecoration)
        .map((container) => container.decoration! as BoxDecoration)
        .where((decoration) => decoration.borderRadius != null);
    expect(roundedBubbleDecorations, isNotEmpty);
  });
}
