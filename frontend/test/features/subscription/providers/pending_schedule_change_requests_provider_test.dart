import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  tearDown(resetMockSubscriptionSessionEventsForTesting);

  test(
    'mock pending requests match backend schedule-change event contract',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events = await container.read(
        pendingScheduleChangeRequestsProvider('teacher_1').future,
      );

      expect(
        events.any(
          (event) => event.eventType == RequestEventType.lessonCancelled,
        ),
        isTrue,
      );
      expect(
        events.map((event) => event.eventType),
        isNot(contains(RequestEventType.scheduleChangeAccepted)),
      );
      expect(
        events.map((event) => event.eventType),
        isNot(contains(RequestEventType.scheduleChangeRejected)),
      );
      expect(
        events.map((event) => event.eventType),
        isNot(contains(RequestEventType.lessonCancelledByTeacher)),
      );
      expect(
        events.map((event) => event.eventType),
        isNot(contains(RequestEventType.teacherAnnouncement)),
      );
    },
  );

  test(
    'remote mode does not leak seeded mock schedule-change requests',
    () async {
      final container = ProviderContainer(
        overrides: [mockDataModeProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      final events = await container.read(
        pendingScheduleChangeRequestsProvider('student_new').future,
      );

      expect(events, isEmpty);
    },
  );

  test(
    'latest terminal decision clears pending request for the same session',
    () {
      final baseTime = DateTime(2026, 5, 7, 10);
      final source = _event(
        id: 'request',
        type: RequestEventType.lessonCancelled,
        createdAt: baseTime,
      );
      final terminal = _event(
        id: 'accepted',
        type: RequestEventType.scheduleChangeAccepted,
        createdAt: baseTime.add(const Duration(minutes: 10)),
      );

      expect(
        pendingScheduleChangeEventsFromHistory([source, terminal]),
        isEmpty,
      );

      final newSource = _event(
        id: 'new_request',
        type: RequestEventType.scheduleChanged,
        createdAt: baseTime.add(const Duration(minutes: 20)),
      );

      expect(
        pendingScheduleChangeEventsFromHistory([source, terminal, newSource]),
        [newSource],
      );
    },
  );
}

RequestEvent _event({
  required String id,
  required RequestEventType type,
  required DateTime createdAt,
}) {
  return RequestEvent(
    id: id,
    requestId: 'sub_1',
    actorType: ProposerRole.student,
    actorId: 'student_1',
    eventType: type,
    createdAt: createdAt,
    subscriptionId: 'sub_1',
    sessionNumber: 1,
  );
}
