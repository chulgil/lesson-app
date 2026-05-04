import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_routes.dart';
import '../../../schedule/domain/entities/schedule_confirmation_card.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../../schedule/presentation/providers/schedule_confirmation_card_providers.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/student_lesson_progress_item.dart';

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

      final items = <StudentLessonProgressItem>[
        ...requests.map(_requestItem),
        ...proposals.map(_proposalItem),
        if (renewalProposal != null &&
            !proposals.any((proposal) => proposal.id == renewalProposal.id))
          _renewalItem(renewalProposal),
        ...scheduleCards.map(_scheduleCardItem),
        ..._recentSubscriptionReadyItems(subscriptions, scheduleCards),
      ];

      return StudentLessonProgressItem.sorted(items);
    });

StudentLessonProgressItem _requestItem(UnifiedLessonRequest request) {
  final priority =
      request.studentActionColorKey == 'action'
          ? StudentLessonProgressPriority.actionRequired
          : StudentLessonProgressPriority.waiting;

  return StudentLessonProgressItem(
    id: 'request_${request.id}',
    kind: _requestKind(request.status),
    priority: priority,
    title: _requestTitle(request.status),
    subtitle: _requestSubtitle(request.status),
    statusLabel: request.studentActionLabel,
    createdAt: request.createdAt,
    route: AppRoutes.requestDetail.replaceFirst(':id', request.id),
  );
}

StudentLessonProgressKind _requestKind(UnifiedRequestStatus status) {
  return switch (status) {
    UnifiedRequestStatus.proposalSent ||
    UnifiedRequestStatus.proposalAccepted ||
    UnifiedRequestStatus.paymentNotified => StudentLessonProgressKind.payment,
    UnifiedRequestStatus.subscriptionIssued =>
      StudentLessonProgressKind.subscriptionReady,
    _ => StudentLessonProgressKind.request,
  };
}

String _requestTitle(UnifiedRequestStatus status) {
  return switch (status) {
    UnifiedRequestStatus.pending => '레슨 신청을 보냈어요',
    UnifiedRequestStatus.approved => '선생님이 레슨 시간을 확인했어요',
    UnifiedRequestStatus.negotiating => '레슨 시간을 조율하고 있어요',
    UnifiedRequestStatus.timeConfirmed => '수강권 안내를 기다리고 있어요',
    UnifiedRequestStatus.proposalSent => '수강권 조건을 확인해주세요',
    UnifiedRequestStatus.proposalAccepted => '입금 후 완료 알림을 보내주세요',
    UnifiedRequestStatus.paymentNotified => '선생님이 입금을 확인하고 있어요',
    UnifiedRequestStatus.subscriptionIssued => '수강권이 준비됐어요',
    UnifiedRequestStatus.inProgress => '레슨이 진행 중이에요',
    UnifiedRequestStatus.completed => '레슨 진행이 완료됐어요',
    UnifiedRequestStatus.rejected => '레슨 신청이 거절됐어요',
    UnifiedRequestStatus.cancelled => '레슨 신청이 취소됐어요',
    UnifiedRequestStatus.expired => '레슨 신청이 만료됐어요',
  };
}

String _requestSubtitle(UnifiedRequestStatus status) {
  return switch (status) {
    UnifiedRequestStatus.pending => '선생님 답변을 기다리고 있어요',
    UnifiedRequestStatus.approved => '확정된 시간 안내를 확인해주세요',
    UnifiedRequestStatus.negotiating => '제안된 시간 중 가능한 시간을 선택해주세요',
    UnifiedRequestStatus.timeConfirmed => '선생님이 수강권 조건을 준비하고 있어요',
    UnifiedRequestStatus.proposalSent => '선생님이 보낸 수강권 안내를 확인해주세요',
    UnifiedRequestStatus.proposalAccepted => '입금이 끝나면 완료 알림을 보내주세요',
    UnifiedRequestStatus.paymentNotified => '확인이 끝나면 수강권이 준비됩니다',
    UnifiedRequestStatus.subscriptionIssued => '다음 레슨 일정에 맞춰 시작합니다',
    UnifiedRequestStatus.inProgress => '레슨 일정에 맞춰 참석해주세요',
    UnifiedRequestStatus.completed => '필요하면 다시 레슨을 신청할 수 있어요',
    UnifiedRequestStatus.rejected => '다른 시간이나 선생님으로 다시 신청할 수 있어요',
    UnifiedRequestStatus.cancelled => '필요하면 새 레슨을 다시 신청할 수 있어요',
    UnifiedRequestStatus.expired => '새 일정으로 다시 신청해주세요',
  };
}

StudentLessonProgressItem _proposalItem(SubscriptionProposal proposal) {
  final isPaymentNotified = proposal.status == ProposalStatus.paymentNotified;

  return StudentLessonProgressItem(
    id: 'proposal_${proposal.id}',
    kind: StudentLessonProgressKind.proposal,
    priority:
        isPaymentNotified
            ? StudentLessonProgressPriority.waiting
            : StudentLessonProgressPriority.actionRequired,
    title: isPaymentNotified ? '선생님이 입금을 확인하고 있어요' : '수강권 조건을 확인해주세요',
    subtitle:
        proposal.message?.trim().isNotEmpty == true
            ? proposal.message!.trim()
            : (proposal.discountReason ?? '선생님이 보낸 수강권 안내를 확인해주세요'),
    statusLabel: isPaymentNotified ? '확인 대기' : '확인 필요',
    createdAt: proposal.createdAt,
    route: AppRoutes.proposalDetail.replaceFirst(':id', proposal.id),
  );
}

StudentLessonProgressItem _renewalItem(SubscriptionProposal proposal) {
  return StudentLessonProgressItem(
    id: 'renewal_${proposal.id}',
    kind: StudentLessonProgressKind.renewal,
    priority: StudentLessonProgressPriority.actionRequired,
    title: '수강권 갱신이 필요해요',
    subtitle:
        proposal.message?.trim().isNotEmpty == true
            ? proposal.message!.trim()
            : '선생님이 수강권 갱신을 제안했습니다',
    statusLabel: '갱신',
    createdAt: proposal.createdAt,
    route: AppRoutes.renewalDetail.replaceFirst(':id', proposal.id),
  );
}

StudentLessonProgressItem _scheduleCardItem(ScheduleConfirmationCard card) {
  return StudentLessonProgressItem(
    id: 'schedule_${card.id}',
    kind: StudentLessonProgressKind.scheduleConfirmation,
    priority: StudentLessonProgressPriority.actionRequired,
    title: '수강권이 준비됐어요',
    subtitle: '첫 레슨 시간을 확인해주세요',
    statusLabel: '확인 필요',
    createdAt: card.createdAt,
    route:
        card.lessonRequestId != null
            ? AppRoutes.requestDetail.replaceFirst(':id', card.lessonRequestId!)
            : AppRoutes.subscriptionDetail.replaceFirst(
              ':id',
              card.subscriptionId,
            ),
  );
}

Iterable<StudentLessonProgressItem> _recentSubscriptionReadyItems(
  List<Subscription> subscriptions,
  List<ScheduleConfirmationCard> scheduleCards,
) {
  final scheduleSubscriptionIds =
      scheduleCards.map((card) => card.subscriptionId).toSet();
  final now = DateTime.now();

  return subscriptions
      .where((subscription) => subscription.status == SubscriptionStatus.active)
      .where(
        (subscription) => !scheduleSubscriptionIds.contains(subscription.id),
      )
      .where(
        (subscription) => now.difference(subscription.createdAt).inDays <= 7,
      )
      .map(
        (subscription) => StudentLessonProgressItem(
          id: 'subscription_${subscription.id}',
          kind: StudentLessonProgressKind.subscriptionReady,
          priority: StudentLessonProgressPriority.completed,
          title: '수강권이 준비됐어요',
          subtitle: '다음 레슨 일정에 맞춰 시작합니다',
          statusLabel: '완료',
          createdAt: subscription.createdAt,
          route: AppRoutes.subscriptionDetail.replaceFirst(
            ':id',
            subscription.id,
          ),
        ),
      );
}
