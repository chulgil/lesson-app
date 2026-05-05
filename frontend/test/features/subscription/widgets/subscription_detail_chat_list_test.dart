import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/mock/mock_lesson_data_ids.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/schedule_change_event_bubble.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_bottom_input_bar.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_detail_chat_list.dart';

void main() {
  testWidgets('shows the selected future session in chat history list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: SubscriptionDetailChatList(
                subscription: Subscription(
                  id: 'sub_1',
                  studentId: 'student_1',
                  membershipId: 'membership_1',
                  type: SubscriptionType.monthly,
                  lessonsPerMonth: 4,
                  usedLessons: 2,
                  amount: 280000,
                  status: SubscriptionStatus.active,
                  createdAt: DateTime(2026, 4, 1),
                ),
                selectedSession: 4,
                viewerRole: 'student',
                studentName: '김민준',
                teacherName: '김선아',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('4회차'), findsWidgets);
  });

  testWidgets(
    'passes cancellation credit context into real session chat bubbles',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                child: SubscriptionDetailChatList(
                  subscription: Subscription(
                    id: MockLessonDataIds.studentCelloSubscription,
                    studentId: MockLessonDataIds.studentCello,
                    membershipId: 'membership_1',
                    type: SubscriptionType.package,
                    totalLessons: 12,
                    usedLessons: 2,
                    totalRescheduleAllowance: 2,
                    usedRescheduleCount: 0,
                    amount: 720000,
                    status: SubscriptionStatus.active,
                    createdAt: DateTime(2026, 4, 1),
                  ),
                  selectedSession: 3,
                  viewerRole: 'teacher',
                  studentName: '박지호',
                  teacherName: '김선아',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3회차 레슨 취소를 요청했어요'), findsOneWidget);
      expect(find.text('변경/취소권 1회가 사용될 예정입니다. 잔여 1회'), findsOneWidget);
      expect(
        find.text('확정되면 이번 일정만 건너뛰고, 다음 진행 레슨이 3회차로 이어집니다.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('aligns chat bubbles relative to the current viewer role', (
    tester,
  ) async {
    final event = RequestEvent(
      id: 'event_1',
      requestId: '',
      actorType: ProposerRole.student,
      actorId: 'student_1',
      eventType: RequestEventType.scheduleChanged,
      message: '학교 일정 때문에 변경 요청드립니다',
      suggestedSlots: [
        TimeSlotOption(
          id: 'slot_1',
          dayOfWeek: 1,
          startTime: '18:00',
          endTime: '19:00',
        ),
        TimeSlotOption(
          id: 'slot_2',
          dayOfWeek: 3,
          startTime: '17:00',
          endTime: '18:00',
        ),
        TimeSlotOption(
          id: 'slot_3',
          dayOfWeek: 5,
          startTime: '10:00',
          endTime: '11:00',
        ),
      ],
      createdAt: DateTime(2026, 5, 4, 18),
      sessionNumber: 4,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: ScheduleChangeEventBubble(
              event: event,
              viewerRole: 'student',
              studentName: '김민준',
              teacherName: '김선아',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final myMessageX = tester.getTopLeft(find.text('김민준 학생')).dx;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: ScheduleChangeEventBubble(
              event: event,
              viewerRole: 'teacher',
              studentName: '김민준',
              teacherName: '김선아',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final opponentMessageX = tester.getTopLeft(find.text('김민준 학생')).dx;

    expect(myMessageX, greaterThan(opponentMessageX));
    expect(find.text('1순위'), findsOneWidget);
    expect(find.text('2순위'), findsOneWidget);
    expect(find.text('3순위'), findsOneWidget);
  });

  testWidgets(
    'teacher accepts a student schedule change slot from the shared action bar',
    (tester) async {
      RequestEvent? acceptedEvent;
      int? acceptedSlotIndex;
      String? acceptedMessage;
      RequestEvent? comparedEvent;
      final requestEvent = RequestEvent(
        id: 'event_1',
        requestId: '',
        actorType: ProposerRole.student,
        actorId: 'student_1',
        eventType: RequestEventType.scheduleChanged,
        suggestedSlots: [
          TimeSlotOption(
            id: 'slot_1',
            dayOfWeek: 1,
            startTime: '18:00',
            endTime: '19:00',
          ),
          TimeSlotOption(
            id: 'slot_2',
            dayOfWeek: 3,
            startTime: '17:00',
            endTime: '18:00',
          ),
          TimeSlotOption(
            id: 'slot_3',
            dayOfWeek: 5,
            startTime: '10:00',
            endTime: '11:00',
          ),
        ],
        createdAt: DateTime(2026, 5, 4, 18),
        sessionNumber: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionBottomInputBar(
              subscription: _activeSubscription(),
              viewerRole: 'teacher',
              messageController: TextEditingController(),
              events: [requestEvent],
              opponentName: '김민준',
              onAcceptScheduleChoice: (event, slotIndex, message) {
                acceptedEvent = event;
                acceptedSlotIndex = slotIndex;
                acceptedMessage = message;
              },
              onCompareSchedule: (event) {
                comparedEvent = event;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('가능한 일정'), findsOneWidget);
      expect(find.text('가능한 일정 중 하나를 선택해 확정하세요'), findsOneWidget);
      expect(find.text('다른 일정 제안'), findsOneWidget);
      expect(find.text('선택한 일정으로 확정'), findsOneWidget);
      expect(find.text('확정 메시지를 남겨주세요 (선택)'), findsOneWidget);

      await tester.tap(find.text('다른 일정 제안'));
      expect(comparedEvent?.id, 'event_1');

      await tester.tap(find.text('2순위'));
      await tester.enterText(find.byType(TextField), '이 시간으로 확정할게요');
      await tester.tap(find.text('선택한 일정으로 확정'));

      expect(acceptedEvent?.id, 'event_1');
      expect(acceptedSlotIndex, 1);
      expect(acceptedMessage, '이 시간으로 확정할게요');
    },
  );

  testWidgets(
    'student accepts a teacher schedule change slot with the same action flow',
    (tester) async {
      RequestEvent? acceptedEvent;
      int? acceptedSlotIndex;
      final proposalEvent = RequestEvent(
        id: 'event_2',
        requestId: '',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.scheduleChangeProposed,
        suggestedSlots: [
          TimeSlotOption(
            id: 'slot_1',
            dayOfWeek: 1,
            startTime: '18:00',
            endTime: '19:00',
          ),
          TimeSlotOption(
            id: 'slot_2',
            dayOfWeek: 3,
            startTime: '17:00',
            endTime: '18:00',
          ),
          TimeSlotOption(
            id: 'slot_3',
            dayOfWeek: 5,
            startTime: '10:00',
            endTime: '11:00',
          ),
        ],
        createdAt: DateTime(2026, 5, 4, 18),
        sessionNumber: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionBottomInputBar(
              subscription: _activeSubscription(),
              viewerRole: 'student',
              messageController: TextEditingController(),
              events: [proposalEvent],
              opponentName: '김선아',
              onAcceptScheduleChoice: (event, slotIndex, _) {
                acceptedEvent = event;
                acceptedSlotIndex = slotIndex;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('가능한 일정 중 하나를 선택해 확정하세요'), findsOneWidget);

      await tester.tap(find.text('3순위'));
      await tester.pump();
      await tester.tap(find.text('선택한 일정으로 확정'));

      expect(acceptedEvent?.id, 'event_2');
      expect(acceptedSlotIndex, 2);
    },
  );

  testWidgets(
    'shows waiting and decision change after sending a schedule change proposal',
    (tester) async {
      RequestEvent? withdrawnEvent;
      final proposalEvent = RequestEvent(
        id: 'event_sent_proposal',
        requestId: '',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.scheduleChangeProposed,
        suggestedSlots: [
          TimeSlotOption(
            id: 'slot_1',
            dayOfWeek: 1,
            startTime: '18:00',
            endTime: '19:00',
          ),
          TimeSlotOption(
            id: 'slot_2',
            dayOfWeek: 3,
            startTime: '17:00',
            endTime: '18:00',
          ),
        ],
        createdAt: DateTime(2026, 5, 4, 18),
        sessionNumber: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionBottomInputBar(
              subscription: _activeSubscription(),
              viewerRole: 'teacher',
              messageController: TextEditingController(),
              events: [proposalEvent],
              opponentName: '김민준',
              onWithdrawScheduleDecision: (event) {
                withdrawnEvent = event;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('김민준님의 응답을 기다리고 있습니다'), findsOneWidget);
      expect(find.text('결정 변경'), findsOneWidget);
      expect(find.text('일정 변경'), findsNothing);
      expect(find.text('메시지 전송'), findsNothing);

      await tester.tap(find.text('결정 변경'));

      expect(withdrawnEvent?.id, 'event_sent_proposal');
    },
  );

  testWidgets(
    'shows waiting and decision change after accepting a schedule slot',
    (tester) async {
      RequestEvent? withdrawnEvent;
      final acceptedEvent = RequestEvent(
        id: 'event_3',
        requestId: '',
        actorType: ProposerRole.student,
        actorId: 'student_1',
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
        createdAt: DateTime(2026, 5, 4, 18),
        sessionNumber: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionBottomInputBar(
              subscription: _activeSubscription(),
              viewerRole: 'student',
              messageController: TextEditingController(),
              events: [acceptedEvent],
              opponentName: '김선아',
              onWithdrawScheduleDecision: (event) {
                withdrawnEvent = event;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('김선아님의 응답을 기다리고 있습니다'), findsOneWidget);
      expect(find.text('결정 변경'), findsOneWidget);

      await tester.tap(find.text('결정 변경'));

      expect(withdrawnEvent?.id, 'event_3');
    },
  );

  testWidgets(
    'withdraw schedule event shows changed decision with strikethrough slot',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleChangeEventBubble(
              event: RequestEvent(
                id: 'event_4',
                requestId: '',
                actorType: ProposerRole.student,
                actorId: 'student_1',
                eventType: RequestEventType.withdrawApproval,
                suggestedSlots: [
                  TimeSlotOption(
                    id: 'slot_1',
                    dayOfWeek: 1,
                    startTime: '18:00',
                    endTime: '19:00',
                  ),
                ],
                selectedSlotIndex: 0,
                createdAt: DateTime(2026, 5, 4, 18),
                sessionNumber: 4,
              ),
              viewerRole: 'teacher',
              studentName: '김민준',
              teacherName: '김선아',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('화 18:00 ~ 19:00'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    },
  );
}

Subscription _activeSubscription() {
  return Subscription(
    id: 'sub_1',
    studentId: 'student_1',
    membershipId: 'membership_1',
    type: SubscriptionType.monthly,
    lessonsPerMonth: 4,
    usedLessons: 2,
    amount: 280000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 4, 1),
  );
}
