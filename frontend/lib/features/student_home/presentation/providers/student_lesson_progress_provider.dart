import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../schedule/presentation/providers/schedule_confirmation_card_providers.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/student_lesson_progress_item.dart';
import '../mappers/student_lesson_progress_mapper.dart';

final studentLessonProgressProvider =
    FutureProvider.family<List<StudentLessonProgressItem>, String>((
      ref,
      studentId,
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
    });
