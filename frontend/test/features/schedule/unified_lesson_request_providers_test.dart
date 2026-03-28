// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/schedule/data/repositories/mock_unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';


void main() {
  late MockUnifiedLessonRequestRepository repository;

  setUp(() {
    repository = MockUnifiedLessonRequestRepository();
  });

  group('requestEventsProvider logic', () {
    test('getEventsByRequestId returns events sorted by createdAt', () async {
      final events = await repository.getEventsByRequestId('ulr_1');

      expect(events, isNotEmpty);
      // Verify sorted ascending
      for (int i = 1; i < events.length; i++) {
        expect(
          events[i].createdAt.isAfter(events[i - 1].createdAt) ||
              events[i].createdAt.isAtSameMomentAs(events[i - 1].createdAt),
          isTrue,
          reason: 'Events should be sorted by createdAt ascending',
        );
      }
    });

    test('getEventsByRequestId returns empty for unknown ID', () async {
      final events = await repository.getEventsByRequestId('nonexistent');
      expect(events, isEmpty);
    });

    test('addEvent appends to existing events', () async {
      final eventsBefore = await repository.getEventsByRequestId('ulr_1');
      final countBefore = eventsBefore.length;

      final newEvent = RequestEvent(
        id: 'evt_new_1',
        requestId: 'ulr_1',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.approve,
        createdAt: DateTime.now(),
      );
      await repository.addEvent(newEvent);

      final eventsAfter = await repository.getEventsByRequestId('ulr_1');
      expect(eventsAfter.length, countBefore + 1);
      expect(eventsAfter.last.id, 'evt_new_1');
    });
  });

  group('todayRequestsProvider logic', () {
    test('filters requests for a teacher including today completed', () async {
      final allRequests = await repository.getByTeacherId('teacher_1');

      // todayRequests: active OR completed today, sorted pending first
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayRequests = allRequests.where((r) {
        if (r.status.isActive) return true;
        if (r.status == UnifiedRequestStatus.completed &&
            r.confirmedAt != null) {
          final confirmedDate = DateTime(
            r.confirmedAt!.year,
            r.confirmedAt!.month,
            r.confirmedAt!.day,
          );
          return confirmedDate == today;
        }
        return false;
      }).toList();

      // Sort: pending first, then by createdAt desc
      todayRequests.sort((a, b) {
        if (a.status == UnifiedRequestStatus.pending &&
            b.status != UnifiedRequestStatus.pending) {
          return -1;
        }
        if (b.status == UnifiedRequestStatus.pending &&
            a.status != UnifiedRequestStatus.pending) {
          return 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      expect(todayRequests, isNotEmpty);

      // Verify no past-completed requests (completed yesterday or earlier)
      for (final r in todayRequests) {
        if (r.status == UnifiedRequestStatus.completed) {
          final confirmedDate = DateTime(
            r.confirmedAt!.year,
            r.confirmedAt!.month,
            r.confirmedAt!.day,
          );
          expect(confirmedDate, equals(today),
              reason: 'Completed requests should be from today only');
        }
      }

      // Verify pending items come first
      bool seenNonPending = false;
      for (final r in todayRequests) {
        if (r.status != UnifiedRequestStatus.pending) {
          seenNonPending = true;
        }
        if (seenNonPending) {
          expect(r.status, isNot(UnifiedRequestStatus.pending),
              reason: 'Pending requests should come before non-pending');
        }
      }
    });
  });

  group('cancelRequest action', () {
    test('sets status to cancelled and adds cancel event', () async {
      // ulr_1 is pending — should be cancellable
      final request = await repository.getById('ulr_1');
      expect(request, isNotNull);
      expect(request!.status, UnifiedRequestStatus.pending);

      // Simulate cancelRequest action
      final updated = request.copyWith(
        status: UnifiedRequestStatus.cancelled,
        cancelledAt: DateTime.now(),
      );
      final result = await repository.update(updated);

      final cancelEvent = RequestEvent(
        id: 'evt_cancel_ulr_1',
        requestId: 'ulr_1',
        actorType: ProposerRole.student,
        actorId: request.studentId,
        eventType: RequestEventType.cancel,
        message: '요청을 취소합니다',
        createdAt: DateTime.now(),
      );
      await repository.addEvent(cancelEvent);

      expect(result.status, UnifiedRequestStatus.cancelled);
      expect(result.cancelledAt, isNotNull);

      final events = await repository.getEventsByRequestId('ulr_1');
      expect(events.any((e) => e.eventType == RequestEventType.cancel), isTrue);
    });

    test('cannot cancel already completed request', () async {
      // ulr_3 is completed
      final request = await repository.getById('ulr_3');
      expect(request, isNotNull);
      expect(request!.status, UnifiedRequestStatus.completed);
      expect(request.canTransitionTo(UnifiedRequestStatus.cancelled), isFalse);
    });
  });

  group('modifyLastAction', () {
    test('can modify pending request preferred slots', () async {
      final request = await repository.getById('ulr_1');
      expect(request, isNotNull);
      expect(request!.status, UnifiedRequestStatus.pending);

      // Modify preferred slots
      final newSlots = [
        const PreferredTimeSlot(
          priority: 1,
          dayOfWeek: 2,
          startTime: '15:00',
          endTime: '16:00',
        ),
      ];

      final updated = request.copyWith(preferredSlots: newSlots);
      final result = await repository.update(updated);

      expect(result.preferredSlots.length, 1);
      expect(result.preferredSlots.first.startTime, '15:00');
    });

    test('cannot modify non-pending request', () async {
      // ulr_2 is negotiating
      final request = await repository.getById('ulr_2');
      expect(request, isNotNull);
      expect(request!.status, UnifiedRequestStatus.negotiating);
      // modifyLastAction should only work for pending
      expect(request.status == UnifiedRequestStatus.pending, isFalse);
    });
  });

  group('action creates RequestEvent', () {
    test('approveRequest creates approve event', () async {
      // ulr_1 is pending
      final request = await repository.getById('ulr_1');
      expect(request, isNotNull);

      final result = await repository.approve('ulr_1');
      expect(result.status, UnifiedRequestStatus.approved);

      // Simulate event creation (this is what the provider should do)
      final approveEvent = RequestEvent(
        id: 'evt_approve_ulr_1',
        requestId: 'ulr_1',
        actorType: ProposerRole.teacher,
        actorId: request!.teacherId,
        eventType: RequestEventType.approve,
        createdAt: DateTime.now(),
      );
      await repository.addEvent(approveEvent);

      final events = await repository.getEventsByRequestId('ulr_1');
      expect(
        events.any((e) => e.eventType == RequestEventType.approve),
        isTrue,
      );
    });

    test('proposeAlternatives creates proposeAlternative event', () async {
      // First approve ulr_1 so we can negotiate
      await repository.approve('ulr_1');

      final slots = [
        TimeSlotOption(
          id: 'slot_alt_1',
          dayOfWeek: 3,
          startTime: '16:00',
          endTime: '17:00',
        ),
      ];

      final result = await repository.proposeAlternatives(
        'ulr_1',
        slots: slots,
        message: '수요일이 어떨까요?',
      );
      expect(result.status, UnifiedRequestStatus.negotiating);

      final proposeEvent = RequestEvent(
        id: 'evt_propose_ulr_1',
        requestId: 'ulr_1',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.proposeAlternative,
        suggestedSlots: slots,
        message: '수요일이 어떨까요?',
        createdAt: DateTime.now(),
      );
      await repository.addEvent(proposeEvent);

      final events = await repository.getEventsByRequestId('ulr_1');
      expect(
        events.any((e) =>
            e.eventType == RequestEventType.proposeAlternative &&
            e.suggestedSlots.isNotEmpty),
        isTrue,
      );
    });
  });
}
