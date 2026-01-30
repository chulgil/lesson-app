import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/domain/services/notification_scheduler_service.dart';
import '../entities/subscription_proposal.dart';
import '../../presentation/providers/subscription_proposal_providers.dart';

part 'proposal_reminder_service.g.dart';

/// Service for scheduling and managing proposal reminder notifications.
///
/// Implements the auto-reminder feature from subscription_proposal_spec.md:
/// - 24h reminder: Gentle reminder about pending proposal
/// - 48h reminder: Follow-up reminder
/// - 72h reminder: Golden time ending warning (if applicable)
@riverpod
ProposalReminderService proposalReminderService(ProposalReminderServiceRef ref) {
  return ProposalReminderService(ref);
}

class ProposalReminderService {
  final ProposalReminderServiceRef _ref;
  static const _uuid = Uuid();

  ProposalReminderService(this._ref);

  /// Schedule all reminders for a new proposal.
  ///
  /// Called when a proposal is created. Schedules:
  /// - 24h reminder
  /// - 48h reminder
  /// - 72h reminder (with golden time warning if applicable)
  Future<void> scheduleRemindersForProposal(SubscriptionProposal proposal) async {
    debugPrint('[ProposalReminderService] Scheduling reminders for proposal: ${proposal.id}');

    final now = DateTime.now();
    final schedulerService = _ref.read(notificationSchedulerServiceProvider);

    // Check if there's a discount (golden time)
    final hasDiscount = (proposal.discountAmount ?? 0) > 0;

    // 24h reminder
    final reminder24h = _createReminderNotification(
      proposal: proposal,
      type: NotificationType.proposalReminder24h,
      scheduledAt: now.add(const Duration(hours: 24)),
      title: '수강권 제안이 기다리고 있어요',
      body: '선생님의 수강권 제안을 확인해보세요.',
    );
    await schedulerService.scheduleNotification(reminder24h);

    // 48h reminder
    final reminder48h = _createReminderNotification(
      proposal: proposal,
      type: NotificationType.proposalReminder48h,
      scheduledAt: now.add(const Duration(hours: 48)),
      title: '수강권 제안 확인이 필요해요',
      body: '선생님의 수강권 제안을 아직 확인하지 않으셨어요.',
    );
    await schedulerService.scheduleNotification(reminder48h);

    // 72h reminder (golden time warning)
    final reminder72h = _createReminderNotification(
      proposal: proposal,
      type: NotificationType.proposalReminder72h,
      scheduledAt: now.add(const Duration(hours: 72)),
      title: hasDiscount ? '⏰ 특별 할인이 곧 종료됩니다!' : '수강권 제안 마지막 알림',
      body: hasDiscount
          ? '할인 혜택이 곧 종료됩니다. 지금 확인하세요!'
          : '선생님의 수강권 제안을 확인해주세요.',
    );
    await schedulerService.scheduleNotification(reminder72h);

    debugPrint('[ProposalReminderService] Scheduled 3 reminders for proposal: ${proposal.id}');
  }

  /// Cancel all pending reminders for a proposal.
  ///
  /// Called when:
  /// - Student accepts the proposal
  /// - Proposal is cancelled
  /// - Proposal expires
  Future<void> cancelRemindersForProposal(String proposalId) async {
    debugPrint('[ProposalReminderService] Cancelling reminders for proposal: $proposalId');

    final schedulerService = _ref.read(notificationSchedulerServiceProvider);

    // Cancel all reminder types for this proposal
    await schedulerService.cancelNotificationsByProposalId(proposalId);

    debugPrint('[ProposalReminderService] Cancelled all reminders for proposal: $proposalId');
  }

  /// Check if proposal is still pending before sending reminder.
  ///
  /// Returns true if reminder should be sent, false if proposal is no longer pending.
  Future<bool> shouldSendReminder(String proposalId) async {
    try {
      final proposal = await _ref.read(
        subscriptionProposalProvider(proposalId).future,
      );

      if (proposal == null) {
        debugPrint('[ProposalReminderService] Proposal not found: $proposalId');
        return false;
      }

      // Only send reminder if proposal is still pending
      final shouldSend = proposal.status == ProposalStatus.pending;

      debugPrint('[ProposalReminderService] Should send reminder for $proposalId: $shouldSend (status: ${proposal.status})');
      return shouldSend;
    } catch (e) {
      debugPrint('[ProposalReminderService] Error checking proposal status: $e');
      return false;
    }
  }

  /// Create a reminder notification for a proposal.
  AppNotification _createReminderNotification({
    required SubscriptionProposal proposal,
    required NotificationType type,
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) {
    return AppNotification(
      id: _uuid.v4(),
      userId: proposal.studentId,
      type: type,
      priority: type.defaultPriority,
      title: title,
      body: body,
      data: {
        'proposalId': proposal.id,
        'teacherId': proposal.teacherId,
        'hasDiscount': (proposal.discountAmount ?? 0) > 0,
      },
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
      actionUrl: '/proposals/${proposal.id}',
      actionLabel: '제안 확인하기',
    );
  }
}
