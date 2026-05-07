import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  return buildStudentLessonProgressItems(
    studentId: studentId,
    requests: requests,
    proposals: proposals,
    renewalProposal: renewalProposal,
    subscriptions: subscriptions,
    scheduleCards: scheduleCards,
    scheduleChangeEvents: scheduleChangeEvents,
  );
}
