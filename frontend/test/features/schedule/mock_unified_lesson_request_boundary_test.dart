import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

void main() {
  group('MockUnifiedLessonRequestRepository lifecycle boundaries', () {
    late MockUnifiedLessonRequestRepository repository;

    setUp(() {
      repository = MockUnifiedLessonRequestRepository();
    });

    test(
      'covers every request lifecycle status with at least one mock',
      () async {
        final requests = await repository.getByTeacherId('teacher_1');
        final statuses = requests.map((request) => request.status).toSet();

        for (final status in UnifiedRequestStatus.values) {
          expect(
            statuses,
            contains(status),
            reason: 'Missing mock for $status',
          );
        }
      },
    );

    test(
      'has no duplicate request IDs, event IDs, or duplicate slot labels',
      () async {
        final requests = await repository.getByTeacherId('teacher_1');
        final requestIds = <String>{};
        final eventIds = <String>{};

        for (final request in requests) {
          expect(
            requestIds.add(request.id),
            isTrue,
            reason: 'Duplicate request id ${request.id}',
          );

          final events = await repository.getEventsByRequestId(request.id);
          for (final event in events) {
            expect(
              event.requestId,
              request.id,
              reason: 'Event ${event.id} points to a different request',
            );
            expect(
              eventIds.add(event.id),
              isTrue,
              reason: 'Duplicate event id ${event.id}',
            );

            final slotLabels =
                event.suggestedSlots.map((slot) => slot.displayLabel).toList();
            expect(
              slotLabels.toSet().length,
              slotLabels.length,
              reason: 'Duplicate suggested slot labels in ${event.id}',
            );
          }
        }
      },
    );

    test('last event matches each request lifecycle status', () async {
      final requests = await repository.getByTeacherId('teacher_1');

      for (final request in requests) {
        final events = await repository.getEventsByRequestId(request.id);
        expect(events, isNotEmpty, reason: '${request.id} has no events');

        final lastEventType = events.last.eventType;
        expect(
          _allowedLastEventTypes(request.status),
          contains(lastEventType),
          reason:
              '${request.id} status ${request.status} has incompatible last event $lastEventType',
        );
      }
    });

    test('contains explicit request-decision boundary cases', () async {
      final approved = await repository.getById('ulr_18');
      final timeConfirmed = await repository.getById('ulr_19');
      final rejected = await repository.getById('ulr_20');
      final withdrawn = await repository.getById('ulr_21');

      expect(approved?.status, UnifiedRequestStatus.approved);
      expect(timeConfirmed?.status, UnifiedRequestStatus.timeConfirmed);
      expect(rejected?.status, UnifiedRequestStatus.rejected);
      expect(withdrawn?.status, UnifiedRequestStatus.pending);

      expect(
        (await repository.getEventsByRequestId('ulr_18')).last.eventType,
        RequestEventType.approve,
      );
      expect(
        (await repository.getEventsByRequestId('ulr_19')).last.eventType,
        RequestEventType.acceptAlternative,
      );
      expect(
        (await repository.getEventsByRequestId('ulr_20')).last.eventType,
        RequestEventType.reject,
      );
      expect(
        (await repository.getEventsByRequestId('ulr_21')).last.eventType,
        RequestEventType.withdrawApproval,
      );
    });

    test('models the payment to subscription issue chain in order', () async {
      final proposalSent = await repository.getEventsByRequestId('ulr_15');
      final proposalAccepted = await repository.getEventsByRequestId('ulr_16');
      final paymentNotified = await repository.getEventsByRequestId('ulr_17');
      final subscriptionIssued = await repository.getEventsByRequestId(
        'ulr_13',
      );
      final inProgress = await repository.getEventsByRequestId('ulr_12');

      expect(
        _eventTypes(proposalSent),
        contains(RequestEventType.proposalSent),
      );
      expect(
        _eventTypes(proposalAccepted),
        containsAllInOrder([
          RequestEventType.proposalSent,
          RequestEventType.proposalAccepted,
        ]),
      );
      expect(
        _eventTypes(paymentNotified),
        containsAllInOrder([
          RequestEventType.proposalSent,
          RequestEventType.proposalAccepted,
          RequestEventType.paymentNotified,
        ]),
      );
      expect(
        _eventTypes(subscriptionIssued),
        containsAllInOrder([
          RequestEventType.proposalSent,
          RequestEventType.proposalAccepted,
          RequestEventType.paymentNotified,
          RequestEventType.subscriptionIssued,
        ]),
      );
      expect(
        _eventTypes(inProgress),
        containsAllInOrder([
          RequestEventType.proposalSent,
          RequestEventType.proposalAccepted,
          RequestEventType.paymentNotified,
          RequestEventType.subscriptionIssued,
          RequestEventType.lessonCompleted,
        ]),
      );
    });
  });
}

List<RequestEventType> _eventTypes(List<RequestEvent> events) {
  return events.map((event) => event.eventType).toList();
}

Set<RequestEventType> _allowedLastEventTypes(UnifiedRequestStatus status) {
  return switch (status) {
    UnifiedRequestStatus.pending => {
      RequestEventType.initialRequest,
      RequestEventType.withdrawApproval,
    },
    UnifiedRequestStatus.approved => {RequestEventType.approve},
    UnifiedRequestStatus.negotiating => {
      RequestEventType.proposeAlternative,
      RequestEventType.counterPropose,
    },
    UnifiedRequestStatus.timeConfirmed => {
      RequestEventType.approve,
      RequestEventType.acceptAlternative,
    },
    UnifiedRequestStatus.proposalSent => {RequestEventType.proposalSent},
    UnifiedRequestStatus.proposalAccepted => {
      RequestEventType.proposalAccepted,
    },
    UnifiedRequestStatus.paymentNotified => {RequestEventType.paymentNotified},
    UnifiedRequestStatus.subscriptionIssued => {
      RequestEventType.subscriptionIssued,
    },
    UnifiedRequestStatus.inProgress => {
      RequestEventType.lessonCompleted,
      RequestEventType.lessonCancelled,
      RequestEventType.lessonNoteAdded,
      RequestEventType.scheduleChanged,
      RequestEventType.scheduleChangeProposed,
      RequestEventType.scheduleChangeAccepted,
      RequestEventType.scheduleChangeRejected,
      RequestEventType.scheduleChangeCountered,
    },
    UnifiedRequestStatus.completed => {RequestEventType.completed},
    UnifiedRequestStatus.rejected => {RequestEventType.reject},
    UnifiedRequestStatus.cancelled => {RequestEventType.cancel},
    UnifiedRequestStatus.expired => {RequestEventType.expire},
  };
}
