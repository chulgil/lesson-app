import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_subscription_proposal_repository.dart';
import '../../data/repositories/remote_subscription_proposal_repository.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/repositories/subscription_proposal_repository.dart';
import '../../domain/services/proposal_reminder_service.dart';
import '../../../notifications/notifications_facade.dart';

part 'subscription_proposal_providers.g.dart';

// ============================================================
// Repository Provider
// ============================================================

/// Proposal repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
SubscriptionProposalRepository subscriptionProposalRepository(
  SubscriptionProposalRepositoryRef ref,
) => createRepository<SubscriptionProposalRepository>(
  ref: ref,
  mock: () => MockSubscriptionProposalRepository(),
  remote: (api) => RemoteSubscriptionProposalRepository(api),
);

@Riverpod(keepAlive: true)
ProposalReminderService proposalReminderService(
  ProposalReminderServiceRef ref,
) {
  final schedulerService = ref.read(notificationSchedulerServiceProvider);
  return ProposalReminderService(
    scheduleNotification: schedulerService.scheduleNotification,
    cancelNotificationsByProposalId:
        schedulerService.cancelNotificationsByProposalId,
    loadProposal: (proposalId) =>
        ref.read(subscriptionProposalProvider(proposalId).future),
    copy: const ProposalReminderCopy(
      reminder24hTitle: AppStrings.proposalReminder24hTitle,
      reminder24hBody: AppStrings.proposalReminder24hBody,
      reminder48hTitle: AppStrings.proposalReminder48hTitle,
      reminder48hBody: AppStrings.proposalReminder48hBody,
      reminder72hTitleDiscount: AppStrings.proposalReminder72hTitleDiscount,
      reminder72hTitleNoDiscount: AppStrings.proposalReminder72hTitleNoDiscount,
      reminder72hBodyDiscount: AppStrings.proposalReminder72hBodyDiscount,
      reminder72hBodyNoDiscount: AppStrings.proposalReminder72hBodyNoDiscount,
      actionLabel: AppStrings.proposalReminderAction,
    ),
  );
}

// ============================================================
// Teacher Proposals
// ============================================================

@riverpod
Future<List<SubscriptionProposal>> teacherProposals(
  TeacherProposalsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(subscriptionProposalRepositoryProvider);
  return repository.getByTeacher(teacherId);
}

@riverpod
Future<List<SubscriptionProposal>> activeTeacherProposals(
  ActiveTeacherProposalsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(subscriptionProposalRepositoryProvider);
  return repository.getActiveByTeacher(teacherId);
}

@riverpod
Future<List<SubscriptionProposal>> awaitingConfirmationProposals(
  AwaitingConfirmationProposalsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(subscriptionProposalRepositoryProvider);
  return repository.getAwaitingConfirmation(teacherId);
}

// ============================================================
// Student Proposals
// ============================================================

@riverpod
Future<List<SubscriptionProposal>> studentProposals(
  StudentProposalsRef ref,
  String studentId,
) async {
  final repository = ref.watch(subscriptionProposalRepositoryProvider);
  return repository.getByStudent(studentId);
}

@riverpod
Future<List<SubscriptionProposal>> activeStudentProposals(
  ActiveStudentProposalsRef ref,
  String studentId,
) async {
  final repository = ref.watch(subscriptionProposalRepositoryProvider);
  return repository.getActiveByStudent(studentId);
}

@riverpod
Future<List<SubscriptionProposal>> pendingStudentProposals(
  PendingStudentProposalsRef ref,
  String studentId,
) async {
  final repository = ref.watch(subscriptionProposalRepositoryProvider);
  return repository.getPendingByStudent(studentId);
}

// ============================================================
// Renewal Proposals
// ============================================================

@riverpod
Future<SubscriptionProposal?> pendingRenewalProposal(
  Ref ref,
  String studentId,
) async {
  final repository = ref.watch(subscriptionProposalRepositoryProvider);
  final proposals = await repository.getPendingByStudent(studentId);
  try {
    return proposals.firstWhere((p) => p.isRenewal);
  } catch (_) {
    return null;
  }
}

// ============================================================
// Single Proposal
// ============================================================

@riverpod
Future<SubscriptionProposal?> subscriptionProposal(
  SubscriptionProposalRef ref,
  String proposalId,
) async {
  final repository = ref.watch(subscriptionProposalRepositoryProvider);
  return repository.getById(proposalId);
}

@riverpod
Future<SubscriptionProposal?> activeProposalBetween(
  ActiveProposalBetweenRef ref,
  String teacherId,
  String studentId,
) async {
  final repository = ref.watch(subscriptionProposalRepositoryProvider);
  return repository.getActiveProposal(teacherId, studentId);
}

// ============================================================
// Proposal Notifier (for CRUD operations)
// ============================================================

@riverpod
class SubscriptionProposalNotifier extends _$SubscriptionProposalNotifier {
  @override
  AsyncValue<SubscriptionProposal?> build() => const AsyncValue.data(null);

  /// Create a new proposal (single template - backward compatible)
  Future<SubscriptionProposal> createProposal({
    required String teacherId,
    required String studentId,
    required String templateId,
    String? message,
    String? academyId,
    int? discountAmount,
    String? discountReason,
    String? lessonRequestId,
  }) async {
    return createMultiChoiceProposal(
      teacherId: teacherId,
      studentId: studentId,
      templateIds: [templateId],
      message: message,
      academyId: academyId,
      discountAmount: discountAmount,
      discountReason: discountReason,
      lessonRequestId: lessonRequestId,
    );
  }

  /// Create a multi-choice proposal (v4)
  Future<SubscriptionProposal> createMultiChoiceProposal({
    required String teacherId,
    required String studentId,
    required List<String> templateIds,
    String? recommendedTemplateId,
    String? message,
    String? academyId,
    int? discountAmount,
    String? discountReason,
    bool isAutoProposal = false,
    // For notification
    String? teacherName,
    String? templateName,
    // For re-enrollment flow (lesson request → proposal link)
    String? lessonRequestId,
    // For renewal proposals
    bool isRenewal = false,
    String? previousSubscriptionId,
    RenewalInitiator? renewalInitiator,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionProposalRepositoryProvider);
      final now = DateTime.now();

      // Use first template as main templateId for backward compatibility
      final mainTemplateId = templateIds.first;

      // For single selection, don't use templateIds array
      final isMultiChoice = templateIds.length > 1;

      final proposal = SubscriptionProposal(
        id: '',
        teacherId: teacherId,
        studentId: studentId,
        templateId: mainTemplateId,
        message: message,
        status: ProposalStatus.pending,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        academyId: academyId,
        discountAmount: discountAmount,
        discountReason: discountReason,
        templateIds: isMultiChoice ? templateIds : const [],
        recommendedTemplateId: recommendedTemplateId,
        isAutoProposal: isAutoProposal,
        lessonRequestId: lessonRequestId,
        isRenewal: isRenewal,
        previousSubscriptionId: previousSubscriptionId,
        renewalInitiator: renewalInitiator,
      );

      final created = await repository.create(proposal);
      state = AsyncValue.data(created);

      // #1212 — 24/48/72h 자동 리마인더는 학생 대상인데 교사 기기에 로컬 예약되어
      // 교사에게 오발했다(그나마 인메모리라 앱 재시작이면 소멸). 리마인더 발송은
      // BE 스케줄러가 맡아야 하므로 FE 로컬 예약을 제거함.

      // #1191 — 학생 통지는 BE Notification row 가 SSOT (#1200: 제안 도착 emit).
      // flutter_local_notifications 는 액터(교사) 기기 전용이라 상대 통지로 쓸 수
      // 없어(기존엔 교사 기기에 오발) FE 로컬 알림 호출을 제거함.

      // Invalidate related providers
      ref.invalidate(teacherProposalsProvider(teacherId));
      ref.invalidate(activeTeacherProposalsProvider(teacherId));
      ref.invalidate(studentProposalsProvider(studentId));
      ref.invalidate(activeStudentProposalsProvider(studentId));
      ref.invalidate(pendingStudentProposalsProvider(studentId));

      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Student notifies payment completion
  Future<SubscriptionProposal> notifyPayment(
    String proposalId, {
    String? studentName,
    String? templateName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionProposalRepositoryProvider);
      final updated = await repository.notifyPayment(proposalId);
      state = AsyncValue.data(updated);

      // Cancel reminders - student has responded
      _cancelReminders(proposalId);

      // #1191 — 교사 통지는 BE Notification row 가 SSOT (입금통보 emit,
      // _notify_deposit_received). FE 로컬 알림은 액터(학생) 기기 전용이라 제거함.

      // Invalidate related providers
      _invalidateProviders(updated);

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Teacher confirms payment
  Future<SubscriptionProposal> confirmPayment(
    String proposalId,
    String subscriptionId, {
    String? teacherName,
    String? templateName,
    int? totalLessons,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionProposalRepositoryProvider);
      final updated = await repository.confirmPayment(
        proposalId,
        subscriptionId,
      );
      state = AsyncValue.data(updated);

      // #1191 — 학생 통지는 BE Notification row 가 SSOT (#1200: 제안 수락/발급
      // emit). FE 로컬 알림은 액터(교사) 기기 전용이라 오발 호출을 제거함.

      // Invalidate related providers
      _invalidateProviders(updated);
      ref.invalidate(awaitingConfirmationProposalsProvider(updated.teacherId));

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Student rejects proposal
  Future<SubscriptionProposal> reject(String proposalId, String? reason) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionProposalRepositoryProvider);
      final updated = await repository.reject(proposalId, reason);
      state = AsyncValue.data(updated);

      // Cancel reminders - proposal rejected
      _cancelReminders(proposalId);

      // Invalidate related providers
      _invalidateProviders(updated);

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Teacher cancels proposal
  Future<SubscriptionProposal> cancel(String proposalId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionProposalRepositoryProvider);
      final updated = await repository.cancel(proposalId);
      state = AsyncValue.data(updated);

      // Cancel reminders - proposal cancelled
      _cancelReminders(proposalId);

      // Invalidate related providers
      _invalidateProviders(updated);

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Student selects a template from multi-choice proposal (v4)
  Future<SubscriptionProposal> selectTemplate(
    String proposalId,
    String templateId,
  ) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionProposalRepositoryProvider);
      final updated = await repository.selectTemplate(proposalId, templateId);
      state = AsyncValue.data(updated);

      // Invalidate related providers
      _invalidateProviders(updated);

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void _invalidateProviders(SubscriptionProposal proposal) {
    ref.invalidate(teacherProposalsProvider(proposal.teacherId));
    ref.invalidate(activeTeacherProposalsProvider(proposal.teacherId));
    ref.invalidate(studentProposalsProvider(proposal.studentId));
    ref.invalidate(activeStudentProposalsProvider(proposal.studentId));
    ref.invalidate(pendingStudentProposalsProvider(proposal.studentId));
    ref.invalidate(pendingRenewalProposalProvider(proposal.studentId));
    ref.invalidate(subscriptionProposalProvider(proposal.id));
  }

  /// Cancel pending reminders for a proposal.
  /// Called when student accepts, rejects, or teacher cancels.
  void _cancelReminders(String proposalId) {
    try {
      final reminderService = ref.read(proposalReminderServiceProvider);
      reminderService.cancelRemindersForProposal(proposalId);
    } catch (e) {
      // Don't fail the main operation due to reminder cancellation error
      debugPrint('[ProposalNotifier] Failed to cancel reminders: $e');
    }
  }
}
