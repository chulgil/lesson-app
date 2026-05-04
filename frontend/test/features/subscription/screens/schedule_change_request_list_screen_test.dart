import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/schedule_change_request_list_screen.dart';

void main() {
  test('classifies schedule change events from the teacher perspective', () {
    expect(
      scheduleChangeRequestStatus(
        _event(
          RequestEventType.scheduleChanged,
          actorType: ProposerRole.student,
        ),
        viewerRole: 'teacher',
      ),
      ScheduleChangeRequestStatus.needsResponse,
    );
    expect(
      scheduleChangeRequestStatus(
        _event(
          RequestEventType.lessonCancelled,
          actorType: ProposerRole.student,
        ),
        viewerRole: 'teacher',
      ),
      ScheduleChangeRequestStatus.needsResponse,
    );
    expect(
      scheduleChangeRequestStatus(
        _event(
          RequestEventType.scheduleChangeProposed,
          actorType: ProposerRole.teacher,
        ),
        viewerRole: 'teacher',
      ),
      ScheduleChangeRequestStatus.waitingResponse,
    );
    expect(
      scheduleChangeRequestStatus(
        _event(
          RequestEventType.scheduleChangeAccepted,
          actorType: ProposerRole.student,
        ),
        viewerRole: 'teacher',
      ),
      ScheduleChangeRequestStatus.completed,
    );
  });

  test(
    'resolves target student name from subscription instead of actor id',
    () {
      final event = _event(
        RequestEventType.scheduleChangeProposed,
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        subscriptionId: 'sub_1',
      );

      expect(
        scheduleChangeRequestStudentName(
          event,
          subscriptionsById: {
            'sub_1': Subscription(
              id: 'sub_1',
              studentId: 'student_2',
              membershipId: 'membership_1',
              type: SubscriptionType.package,
              totalLessons: 8,
              usedLessons: 3,
              amount: 320000,
              status: SubscriptionStatus.active,
              createdAt: DateTime(2026, 5, 1),
            ),
          },
          studentNames: const {'student_2': '이서현'},
        ),
        '이서현',
      );
    },
  );

  testWidgets('renders the redesigned list with target student names', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingScheduleChangeRequestsProvider('teacher_1').overrideWith(
            (ref) async => [
              _event(
                RequestEventType.scheduleChanged,
                actorType: ProposerRole.student,
                actorId: 'student_1',
                subscriptionId: 'sub_1',
              ),
              _event(
                RequestEventType.scheduleChangeProposed,
                actorType: ProposerRole.teacher,
                actorId: 'teacher_1',
                subscriptionId: 'sub_2',
              ),
            ],
          ),
          teacherStudentSubscriptionsProvider('teacher_1').overrideWith(
            (ref) async => [
              _subscription('sub_1', 'student_1'),
              _subscription('sub_2', 'student_2'),
            ],
          ),
          studentNameMapProvider.overrideWithValue({
            'student_1': '김민준',
            'student_2': '이서현',
          }),
        ],
        child: const MaterialApp(
          home: ScheduleChangeRequestListScreen(teacherId: 'teacher_1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('스케줄 변경요청'), findsOneWidget);
    expect(find.textContaining('확인 필요'), findsWidgets);
    expect(find.textContaining('응답 대기'), findsWidgets);
    expect(find.textContaining('김민준'), findsOneWidget);
    expect(find.textContaining('이서현'), findsOneWidget);
    expect(find.text('1주'), findsOneWidget);
    expect(find.text('1달'), findsOneWidget);
    expect(find.text('3달'), findsOneWidget);
  });
}

Subscription _subscription(String id, String studentId) {
  return Subscription(
    id: id,
    studentId: studentId,
    membershipId: 'membership_$id',
    type: SubscriptionType.package,
    totalLessons: 8,
    usedLessons: 3,
    amount: 320000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 5, 1),
  );
}

RequestEvent _event(
  RequestEventType eventType, {
  required ProposerRole actorType,
  String? actorId,
  String? subscriptionId,
}) {
  return RequestEvent(
    id: 'event_${eventType.name}',
    requestId: '',
    actorType: actorType,
    actorId:
        actorId ??
        (actorType == ProposerRole.teacher ? 'teacher_1' : 'student_1'),
    eventType: eventType,
    createdAt: DateTime(2026, 5, 4, 10),
    subscriptionId: subscriptionId ?? 'sub_1',
    sessionNumber: 4,
  );
}
