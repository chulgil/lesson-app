import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/current_request_box.dart';

void main() {
  group('CurrentRequestBox decision waiting state', () {
    testWidgets(
      'teacher sees waiting and decision change after accepting a lesson request',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            CurrentRequestBox(
              request: _request(status: UnifiedRequestStatus.timeConfirmed),
              events: [
                _event(
                  actorType: ProposerRole.teacher,
                  eventType: RequestEventType.approve,
                ),
              ],
              viewerRole: 'teacher',
              opponentName: '이서현',
            ),
          ),
        );

        expect(find.text('이서현님의 응답을 기다리고 있습니다'), findsOneWidget);
        expect(find.text('결정 변경'), findsOneWidget);
        expect(find.text('수강권 제안'), findsNothing);
      },
    );

    testWidgets(
      'student sees waiting and decision change after accepting a teacher alternative',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            CurrentRequestBox(
              request: _request(status: UnifiedRequestStatus.timeConfirmed),
              events: [
                _event(
                  actorType: ProposerRole.student,
                  eventType: RequestEventType.acceptAlternative,
                ),
              ],
              viewerRole: 'student',
              opponentName: '김선아',
            ),
          ),
        );

        expect(find.text('김선아님의 응답을 기다리고 있습니다'), findsOneWidget);
        expect(find.text('결정 변경'), findsOneWidget);
        expect(find.text('수강권 발급 완료'), findsNothing);
      },
    );

    testWidgets(
      'student moves to payment flow after teacher has confirmed the schedule',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            CurrentRequestBox(
              request: _request(status: UnifiedRequestStatus.timeConfirmed),
              events: [
                _event(
                  actorType: ProposerRole.teacher,
                  eventType: RequestEventType.approve,
                ),
              ],
              viewerRole: 'student',
              opponentName: '김선아',
            ),
          ),
        );

        expect(find.textContaining('수강권'), findsWidgets);
        expect(find.text('김선아님의 응답을 기다리고 있습니다'), findsNothing);
        expect(find.text('결정 변경'), findsNothing);
      },
    );
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

UnifiedLessonRequest _request({required UnifiedRequestStatus status}) {
  return UnifiedLessonRequest(
    id: 'request_1',
    studentId: 'student_1',
    teacherId: 'teacher_1',
    type: LessonRequestType.regular,
    instrument: '피아노',
    goal: UnifiedLessonGoal.hobby,
    experience: UnifiedExperienceLevel.beginner,
    status: status,
    createdAt: DateTime(2026, 5, 4),
    preferredSlots: const [
      PreferredTimeSlot(
        priority: 1,
        dayOfWeek: 1,
        startTime: '16:00',
        endTime: '17:00',
      ),
    ],
  );
}

RequestEvent _event({
  required ProposerRole actorType,
  required RequestEventType eventType,
}) {
  return RequestEvent(
    id: 'event_1',
    requestId: 'request_1',
    actorType: actorType,
    actorId: actorType == ProposerRole.teacher ? 'teacher_1' : 'student_1',
    eventType: eventType,
    selectedSlotIndex: 0,
    createdAt: DateTime(2026, 5, 4, 10),
  );
}
