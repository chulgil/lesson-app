import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/student_lesson_progress_item.dart';
import '../mappers/student_lesson_progress_mapper.dart';

part 'student_lesson_progress_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<StudentLessonProgressItem>> studentLessonProgress(
  StudentLessonProgressRef ref,
  String studentId,
) async {
  final requests = await ref.watch(
    studentTodayRequestsProvider(studentId).future,
  );
  final proposals = await ref.watch(
    pendingStudentProposalsProvider(studentId).future,
  );
  final renewalProposal = await ref.watch(
    pendingRenewalProposalProvider(studentId).future,
  );
  final subscriptions = await ref.watch(
    studentSubscriptionsProvider(studentId).future,
  );
  final scheduleCards = await ref.watch(
    pendingScheduleConfirmationCardsProvider(studentId).future,
  );
  final scheduleChangeEvents = await ref.watch(
    pendingScheduleChangeRequestsProvider(studentId).future,
  );
  final lessonRequestIdBySubscription = await _resolveLessonRequestIds(
    ref,
    scheduleChangeEvents,
  );

  return buildStudentLessonProgressItems(
    studentId: studentId,
    requests: requests,
    proposals: proposals,
    renewalProposal: renewalProposal,
    subscriptions: subscriptions,
    scheduleCards: scheduleCards,
    scheduleChangeEvents: scheduleChangeEvents,
    lessonRequestIdBySubscription: lessonRequestIdBySubscription,
  );
}

/// Resolves the originating request thread id for each schedule-change
/// event's subscription (Option A reverse lookup via
/// ScheduleConfirmationCard). Subscriptions without a linked card (renewal
/// / teacher-direct proposals) are simply absent from the returned map —
/// callers fall back to subscription-based routing for those.
Future<Map<String, String>> _resolveLessonRequestIds(
  Ref ref,
  List<RequestEvent> scheduleChangeEvents,
) async {
  final subscriptionIds =
      scheduleChangeEvents
          .map((event) => event.subscriptionId)
          .whereType<String>()
          .toSet();

  final result = <String, String>{};
  for (final subscriptionId in subscriptionIds) {
    final lessonRequestId = await ref.watch(
      lessonRequestIdBySubscriptionProvider(subscriptionId).future,
    );
    if (lessonRequestId != null) {
      result[subscriptionId] = lessonRequestId;
    }
  }
  return result;
}
