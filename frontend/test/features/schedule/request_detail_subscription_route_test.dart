import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/screens/request_detail_screen.dart';

void main() {
  test('request detail resolves latest subscription route from events', () {
    final route = requestDetailSubscriptionRoute([
      RequestEvent(
        id: 'evt-old',
        requestId: 'req-1',
        actorType: ProposerRole.teacher,
        actorId: 'teacher-1',
        eventType: RequestEventType.subscriptionIssued,
        subscriptionId: 'sub-old',
        createdAt: DateTime(2026, 5, 1),
      ),
      RequestEvent(
        id: 'evt-new',
        requestId: 'req-1',
        actorType: ProposerRole.teacher,
        actorId: 'teacher-1',
        eventType: RequestEventType.subscriptionRenewed,
        subscriptionId: 'sub-new',
        createdAt: DateTime(2026, 5, 20),
      ),
    ]);

    expect(route, '/subscriptions/sub-new');
  });

  test('request detail returns null when no subscription event exists', () {
    final route = requestDetailSubscriptionRoute([
      RequestEvent(
        id: 'evt-request',
        requestId: 'req-1',
        actorType: ProposerRole.student,
        actorId: 'student-1',
        eventType: RequestEventType.initialRequest,
        createdAt: DateTime(2026, 5, 1),
      ),
    ]);

    expect(route, isNull);
  });
}
