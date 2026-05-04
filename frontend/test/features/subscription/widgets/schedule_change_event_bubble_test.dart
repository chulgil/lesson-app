import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/schedule_change_event_bubble.dart';

void main() {
  Iterable<BoxDecoration> boxDecorations(WidgetTester tester) {
    return tester
        .widgetList<Container>(find.byType(Container))
        .where((container) => container.decoration is BoxDecoration)
        .map((container) => container.decoration! as BoxDecoration);
  }

  Iterable<BoxDecoration> roundedDecorations(WidgetTester tester) {
    return boxDecorations(
      tester,
    ).where((decoration) => decoration.borderRadius != null);
  }

  Iterable<BoxDecoration> angularScheduleCardDecorations(WidgetTester tester) {
    return boxDecorations(tester).where(
      (decoration) =>
          decoration.border != null && decoration.borderRadius == null,
    );
  }

  Future<void> pumpBubble(
    WidgetTester tester,
    RequestEvent event, {
    String viewerRole = 'student',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleChangeEventBubble(
            viewerRole: viewerRole,
            studentName: '김민준',
            teacherName: '김선아',
            event: event,
            rescheduleCreditsUsed: 1,
            rescheduleCreditsRemaining: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  RequestEvent scheduleEvent(
    RequestEventType type, {
    ProposerRole actorType = ProposerRole.student,
    List<TimeSlotOption> slots = const [],
    int? selectedSlotIndex,
    String? message,
  }) {
    return RequestEvent(
      id: 'event_${type.name}',
      requestId: '',
      actorType: actorType,
      actorId: actorType == ProposerRole.teacher ? 'teacher_1' : 'student_1',
      eventType: type,
      message: message,
      suggestedSlots: slots,
      selectedSlotIndex: selectedSlotIndex,
      createdAt: DateTime(2026, 5, 4, 10),
      sessionNumber: 4,
    );
  }

  final slot = TimeSlotOption(
    id: 'slot_1',
    dayOfWeek: 1,
    startTime: '18:00',
    endTime: '19:00',
  );

  testWidgets('renders every schedule change history event inside a bubble', (
    tester,
  ) async {
    final cases = <RequestEvent>[
      scheduleEvent(RequestEventType.scheduleChanged, slots: [slot]),
      scheduleEvent(
        RequestEventType.scheduleChangeProposed,
        actorType: ProposerRole.teacher,
        slots: [slot],
      ),
      scheduleEvent(
        RequestEventType.scheduleChangeCountered,
        actorType: ProposerRole.teacher,
        slots: [slot],
      ),
      scheduleEvent(
        RequestEventType.scheduleChangeAccepted,
        slots: [slot],
        selectedSlotIndex: 0,
      ),
      scheduleEvent(RequestEventType.scheduleChangeRejected, message: '어려워요'),
      scheduleEvent(
        RequestEventType.withdrawApproval,
        slots: [slot],
        selectedSlotIndex: 0,
      ),
      scheduleEvent(RequestEventType.lessonCancelled, message: '컨디션 난조'),
      scheduleEvent(RequestEventType.message, message: '확인했습니다'),
    ];

    for (final event in cases) {
      await pumpBubble(tester, event);

      expect(
        roundedDecorations(tester),
        isNotEmpty,
        reason: '${event.eventType.name} must render as a speech bubble',
      );
    }
  });

  testWidgets('shows actor role even for the current student message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleChangeEventBubble(
            viewerRole: 'student',
            studentName: '김민준',
            teacherName: '김선아',
            event: RequestEvent(
              id: 'event_1',
              requestId: '',
              actorType: ProposerRole.student,
              actorId: 'student_1',
              eventType: RequestEventType.scheduleChanged,
              message: '학교 일정 때문에 시간 변경을 요청했어요',
              suggestedSlots: [
                TimeSlotOption(
                  id: 'slot_1',
                  dayOfWeek: 1,
                  startTime: '18:00',
                  endTime: '19:00',
                ),
              ],
              createdAt: DateTime(2026, 5, 4, 10),
              sessionNumber: 6,
            ),
          ),
        ),
      ),
    );

    expect(find.text('김민준 학생'), findsOneWidget);
    expect(find.text('6회차 시간 변경을 요청합니다'), findsOneWidget);
    expect(find.textContaining('18:00'), findsOneWidget);
    expect(roundedDecorations(tester), isNotEmpty);
    expect(angularScheduleCardDecorations(tester), isNotEmpty);
  });

  testWidgets(
    'accepted schedule event uses the same speech bubble without success-card styling',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleChangeEventBubble(
              viewerRole: 'teacher',
              studentName: '김민준',
              teacherName: '김선아',
              event: RequestEvent(
                id: 'event_accept',
                requestId: '',
                actorType: ProposerRole.teacher,
                actorId: 'teacher_1',
                eventType: RequestEventType.scheduleChangeAccepted,
                suggestedSlots: [
                  TimeSlotOption(
                    id: 'slot_1',
                    dayOfWeek: 1,
                    startTime: '18:00',
                    endTime: '19:00',
                  ),
                ],
                selectedSlotIndex: 0,
                createdAt: DateTime(2026, 5, 4, 11),
                sessionNumber: 6,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('18:00'), findsWidgets);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(roundedDecorations(tester), isNotEmpty);
      expect(angularScheduleCardDecorations(tester), isEmpty);
    },
  );

  testWidgets('shows cancelled lesson session number in the chat bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleChangeEventBubble(
            viewerRole: 'teacher',
            studentName: '박지호',
            teacherName: '김선아',
            rescheduleCreditsUsed: 1,
            rescheduleCreditsRemaining: 1,
            event: RequestEvent(
              id: 'event_cancel_1',
              requestId: '',
              actorType: ProposerRole.student,
              actorId: 'student_3',
              eventType: RequestEventType.lessonCancelled,
              message: '컨디션이 좋지 않아 취소 요청드립니다',
              createdAt: DateTime(2026, 5, 4, 10),
              sessionNumber: 3,
            ),
          ),
        ),
      ),
    );

    expect(find.text('박지호 학생'), findsOneWidget);
    expect(find.text('3회차 레슨 취소를 요청했어요'), findsOneWidget);
    expect(find.text('변경/취소권 1회가 사용될 예정입니다. 잔여 1회'), findsOneWidget);
    expect(
      find.text('확정되면 이번 일정만 건너뛰고, 다음 진행 레슨이 3회차로 이어집니다.'),
      findsOneWidget,
    );
    expect(find.text('사유: 컨디션이 좋지 않아 취소 요청드립니다'), findsOneWidget);
  });
}
