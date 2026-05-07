import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/mock/mock_lesson_data_ids.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_schedule_confirmation_card_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/extensions/unified_lesson_request_visuals.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  test('central mock ids expose the default student lesson context', () {
    expect(MockLessonDataIds.teacherPrimary, 'teacher_1');
    expect(MockLessonDataIds.studentPrimary, 'student_1');
    expect(MockLessonDataIds.studentPrimaryViolinSubscription, 'sub_pkg_01');
  });

  test(
    'pending schedule confirmation cards point to existing subscriptions',
    () async {
      final cardRepository = MockScheduleConfirmationCardRepository();
      final subscriptionRepository = MockSubscriptionRepository();

      for (final studentId in ['student_1', 'student_4', 'student_11']) {
        final cards = await cardRepository.getPendingCardsForStudent(studentId);
        final subscriptions = await subscriptionRepository.getByStudentId(
          studentId,
        );
        final subscriptionIds = subscriptions.map((item) => item.id).toSet();

        for (final card in cards) {
          expect(
            subscriptionIds,
            contains(card.subscriptionId),
            reason:
                '${card.id} points to missing subscription ${card.subscriptionId}',
          );
        }
      }
    },
  );

  test(
    'mock schedule change events reference the acting student subscription',
    () async {
      final container = ProviderContainer();
      final subscriptionRepository = MockSubscriptionRepository();
      addTearDown(container.dispose);

      final events = await container.read(
        pendingScheduleChangeRequestsProvider('teacher_1').future,
      );

      for (final event in events.where(
        (event) => event.actorType == ProposerRole.student,
      )) {
        final subscriptionId = event.subscriptionId;
        expect(
          subscriptionId,
          isNotNull,
          reason: '${event.id} has no subscription',
        );

        final subscriptions = await subscriptionRepository.getByStudentId(
          event.actorId,
        );
        final subscriptionIds = subscriptions.map((item) => item.id).toSet();

        expect(
          subscriptionIds,
          contains(subscriptionId),
          reason: '${event.id} points to another student subscription',
        );
      }
    },
  );

  test(
    'pending schedule change mock events are available in session chat history',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final pendingEvents = await container.read(
        pendingScheduleChangeRequestsProvider('teacher_1').future,
      );
      final studentRequest = pendingEvents.firstWhere(
        (event) => event.id == 'sce_mock_1',
      );

      final sessionEvents = await container.read(
        subscriptionSessionEventsProvider(
          subscriptionId: studentRequest.subscriptionId!,
          sessionNumber: studentRequest.sessionNumber!,
        ).future,
      );

      expect(sessionEvents.map((event) => event.id), contains('sce_mock_1'));
      expect(
        sessionEvents.firstWhere((event) => event.id == 'sce_mock_1').actorType,
        ProposerRole.student,
      );
    },
  );

  test(
    'all pending schedule change mock events are available in matching session history',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final pendingEvents = await container.read(
        pendingScheduleChangeRequestsProvider('teacher_1').future,
      );

      for (final event in pendingEvents) {
        final subscriptionId = event.subscriptionId;
        final sessionNumber = event.sessionNumber;
        expect(subscriptionId, isNotNull, reason: '${event.id} missing sub');
        expect(sessionNumber, isNotNull, reason: '${event.id} missing session');

        final sessionEvents = await container.read(
          subscriptionSessionEventsProvider(
            subscriptionId: subscriptionId!,
            sessionNumber: sessionNumber!,
          ).future,
        );

        expect(
          sessionEvents.map((item) => item.id),
          contains(event.id),
          reason:
              '${event.id} is not visible in $subscriptionId session $sessionNumber',
        );
      }
    },
  );

  test(
    'student schedule change mock events include requested time details',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events = await container.read(
        pendingScheduleChangeRequestsProvider('teacher_1').future,
      );

      final singleChange = events.firstWhere(
        (event) => event.id == 'sce_mock_1',
      );
      expect(singleChange.actorType, ProposerRole.student);
      expect(singleChange.suggestedSlots, isNotEmpty);
      expect(singleChange.suggestedSlots.first.displayLabel, contains('화'));
      expect(singleChange.suggestedSlots.first.displayLabel, contains('18:00'));

      final bulkChange = events.firstWhere((event) => event.id == 'sce_mock_3');
      expect(bulkChange.actorType, ProposerRole.student);
      expect(bulkChange.scheduleChangeType?.name, 'bulkChange');
      expect(bulkChange.proposedDayOfWeek, isNotNull);
      expect(bulkChange.proposedTime, isNotNull);
    },
  );

  test(
    'schedule change mock events use three ranked time slots when ranked',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events = await container.read(
        pendingScheduleChangeRequestsProvider('teacher_1').future,
      );
      final rankedEvents = events.where(
        (event) =>
            (event.eventType == RequestEventType.scheduleChanged &&
                event.scheduleChangeType != ScheduleChangeType.bulkChange) ||
            event.eventType == RequestEventType.scheduleChangeProposed ||
            event.eventType == RequestEventType.scheduleChangeAccepted,
      );

      for (final event in rankedEvents) {
        expect(
          event.suggestedSlots,
          hasLength(3),
          reason: '${event.id} should display 1, 2, 3 ranked options',
        );
      }
    },
  );

  test(
    'mock schedule change session numbers fit within their subscriptions',
    () async {
      final container = ProviderContainer();
      final subscriptionRepository = MockSubscriptionRepository();
      addTearDown(container.dispose);

      final events = await container.read(
        pendingScheduleChangeRequestsProvider('teacher_1').future,
      );

      for (final event in events) {
        final subscriptionId = event.subscriptionId;
        final sessionNumber = event.sessionNumber;
        expect(subscriptionId, isNotNull, reason: '${event.id} missing sub');
        expect(sessionNumber, isNotNull, reason: '${event.id} missing session');

        final subscription = await subscriptionRepository.getById(
          subscriptionId!,
        );
        expect(
          subscription,
          isNotNull,
          reason: '${event.id} points to missing subscription $subscriptionId',
        );
        final totalLessons =
            subscription!.totalLessons ?? subscription.lessonsPerMonth;

        expect(
          totalLessons,
          isNotNull,
          reason: '${event.id} subscription has no total lesson boundary',
        );
        expect(
          sessionNumber!,
          lessThanOrEqualTo(totalLessons!),
          reason:
              '${event.id} uses $sessionNumber회차 but '
              '${subscription.id} only has $totalLessons lessons',
        );
      }
    },
  );

  test(
    'teacher proposal is pending and accepted event stays in session history',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events = await container.read(
        pendingScheduleChangeRequestsProvider('teacher_1').future,
      );

      final teacherProposal = events.firstWhere(
        (event) => event.id == 'sce_mock_4',
      );
      expect(teacherProposal.actorType, ProposerRole.teacher);
      expect(teacherProposal.suggestedSlots, isNotEmpty);
      expect(
        teacherProposal.suggestedSlots.first.displayLabel,
        contains('16:00'),
      );

      final sessionEvents = await container.read(
        subscriptionSessionEventsProvider(
          subscriptionId: 'sub_mon_03',
          sessionNumber: 2,
        ).future,
      );
      final accepted = sessionEvents.firstWhere(
        (event) => event.id == 'sce_mock_5',
      );
      expect(accepted.eventType, RequestEventType.scheduleChangeAccepted);
      expect(accepted.suggestedSlots, isNotEmpty);
      expect(accepted.selectedSlotIndex, 0);
      expect(
        accepted.suggestedSlots[accepted.selectedSlotIndex!].displayLabel,
        contains('14:00'),
      );
    },
  );

  test(
    'added session event is visible from schedule change list providers',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(resetMockSubscriptionSessionEventsForTesting);

      final event = RequestEvent(
        id: 'sce_added_provider_sync',
        requestId: MockLessonDataIds.studentPrimaryViolinSubscription,
        actorType: ProposerRole.student,
        actorId: MockLessonDataIds.studentPrimary,
        eventType: RequestEventType.scheduleChanged,
        message: '시험 기간이라 6회차 시간 변경을 요청합니다',
        suggestedSlots: [
          TimeSlotOption(
            id: 'sce_added_provider_sync_slot_1',
            dayOfWeek: 2,
            startTime: '20:00',
            endTime: '21:00',
          ),
        ],
        createdAt: DateTime.now().add(const Duration(minutes: 1)),
        subscriptionId: MockLessonDataIds.studentPrimaryViolinSubscription,
        sessionNumber: 6,
      );

      await container
          .read(subscriptionSessionEventActionsProvider)
          .addSessionEvent(
            subscriptionId: MockLessonDataIds.studentPrimaryViolinSubscription,
            sessionNumber: 6,
            event: event,
            affectedTeacherId: MockLessonDataIds.teacherPrimary,
            affectedStudentId: MockLessonDataIds.studentPrimary,
          );

      final teacherEvents = await container.read(
        pendingScheduleChangeRequestsProvider(
          MockLessonDataIds.teacherPrimary,
        ).future,
      );
      final studentEvents = await container.read(
        pendingScheduleChangeRequestsProvider(
          MockLessonDataIds.studentPrimary,
        ).future,
      );
      final sessionEvents = await container.read(
        subscriptionSessionEventsProvider(
          subscriptionId: MockLessonDataIds.studentPrimaryViolinSubscription,
          sessionNumber: 6,
        ).future,
      );

      expect(
        teacherEvents.map((item) => item.id),
        contains('sce_added_provider_sync'),
      );
      expect(
        studentEvents.map((item) => item.id),
        contains('sce_added_provider_sync'),
      );
      expect(
        sessionEvents.map((item) => item.id),
        contains('sce_added_provider_sync'),
      );
    },
  );
}
