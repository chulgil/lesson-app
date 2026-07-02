import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_bottom_input_bar.dart';

/// N8 (0702 감사, #1076) — 구독 협상 응답 바에 거절 액션이 없어
/// request_detail 의 3종 응답(수락/거절/역제안)과 비대칭이었다.
/// canRespond 상태에서 거절 버튼 노출 + 콜백(event, message) 발화를 검증한다.
Subscription _subscription() => Subscription(
  id: 'sub_1',
  studentId: 'student_1',
  membershipId: 'membership_1',
  type: SubscriptionType.monthly,
  lessonsPerMonth: 4,
  usedLessons: 1,
  amount: 280000,
  status: SubscriptionStatus.active,
  createdAt: DateTime(2026, 6, 1),
);

RequestEvent _teacherProposal() => RequestEvent(
  id: 'evt_proposal',
  requestId: 'sub_1',
  actorType: ProposerRole.teacher,
  actorId: 'teacher_1',
  eventType: RequestEventType.scheduleChangeProposed,
  suggestedSlots: [
    TimeSlotOption(
      id: 'slot_1',
      dayOfWeek: 0,
      startTime: '14:00',
      endTime: '15:00',
      date: DateTime(2026, 7, 6),
    ),
  ],
  sessionNumber: 2,
  createdAt: DateTime(2026, 7, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required void Function(RequestEvent, String) onReject,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SubscriptionBottomInputBar(
            subscription: _subscription(),
            viewerRole: 'student',
            events: [_teacherProposal()],
            selectedSession: 2,
            onRejectScheduleChoice: onReject,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('canRespond 상태에서 거절 버튼이 노출된다', (tester) async {
    await _pump(tester, onReject: (_, __) {});

    expect(find.text(AppStrings.scheduleChangeReject), findsOneWidget);
    expect(find.text(AppStrings.scheduleChangeCounter), findsOneWidget);
    expect(find.text(AppStrings.scheduleChangeAccept), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('거절 탭 → 콜백이 이벤트·메시지와 함께 발화된다', (tester) async {
    RequestEvent? rejected;
    String? message;
    await _pump(
      tester,
      onReject: (event, msg) {
        rejected = event;
        message = msg;
      },
    );

    await tester.enterText(find.byType(TextField), '이번 주는 어렵습니다');
    await tester.tap(find.text(AppStrings.scheduleChangeReject));
    await tester.pumpAndSettle();

    expect(rejected?.id, 'evt_proposal');
    expect(message, '이번 주는 어렵습니다');
  });
}
