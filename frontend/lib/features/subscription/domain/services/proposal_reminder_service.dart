import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

import '../../../notifications/domain/entities/notification.dart';
import '../entities/subscription_proposal.dart';

typedef ScheduleProposalReminderNotification =
    Future<void> Function(AppNotification notification);
typedef CancelProposalReminderNotifications =
    Future<void> Function(String proposalId);
typedef LoadProposalForReminder =
    Future<SubscriptionProposal?> Function(String proposalId);

class ProposalReminderCopy {
  final String reminder24hTitle;
  final String reminder24hBody;
  final String reminder48hTitle;
  final String reminder48hBody;
  final String reminder72hTitleDiscount;
  final String reminder72hTitleNoDiscount;
  final String reminder72hBodyDiscount;
  final String reminder72hBodyNoDiscount;
  final String actionLabel;

  const ProposalReminderCopy({
    required this.reminder24hTitle,
    required this.reminder24hBody,
    required this.reminder48hTitle,
    required this.reminder48hBody,
    required this.reminder72hTitleDiscount,
    required this.reminder72hTitleNoDiscount,
    required this.reminder72hBodyDiscount,
    required this.reminder72hBodyNoDiscount,
    required this.actionLabel,
  });

  String titleFor(NotificationType type, {required bool hasDiscount}) {
    return switch (type) {
      NotificationType.proposalReminder24h => reminder24hTitle,
      NotificationType.proposalReminder48h => reminder48hTitle,
      NotificationType.proposalReminder72h =>
        hasDiscount ? reminder72hTitleDiscount : reminder72hTitleNoDiscount,
      _ => throw ArgumentError.value(type, 'type', 'Unsupported reminder type'),
    };
  }

  String bodyFor(NotificationType type, {required bool hasDiscount}) {
    return switch (type) {
      NotificationType.proposalReminder24h => reminder24hBody,
      NotificationType.proposalReminder48h => reminder48hBody,
      NotificationType.proposalReminder72h =>
        hasDiscount ? reminder72hBodyDiscount : reminder72hBodyNoDiscount,
      _ => throw ArgumentError.value(type, 'type', 'Unsupported reminder type'),
    };
  }
}

/// Service for scheduling and managing proposal reminder notifications.
///
/// Implements the auto-reminder feature from subscription_proposal_spec.md:
/// - 24h reminder: Gentle reminder about pending proposal
/// - 48h reminder: Follow-up reminder
/// - 72h reminder: Golden time ending warning (if applicable)
class ProposalReminderService {
  final ScheduleProposalReminderNotification _scheduleNotification;
  final CancelProposalReminderNotifications _cancelNotificationsByProposalId;
  final LoadProposalForReminder _loadProposal;
  final ProposalReminderCopy _copy;
  static const _uuid = Uuid();

  const ProposalReminderService({
    required ScheduleProposalReminderNotification scheduleNotification,
    required CancelProposalReminderNotifications
    cancelNotificationsByProposalId,
    required LoadProposalForReminder loadProposal,
    required ProposalReminderCopy copy,
  }) : _scheduleNotification = scheduleNotification,
       _cancelNotificationsByProposalId = cancelNotificationsByProposalId,
       _loadProposal = loadProposal,
       _copy = copy;

  /// Schedule all reminders for a new proposal.
  ///
  /// Called when a proposal is created. Schedules:
  /// - 24h reminder
  /// - 48h reminder
  /// - 72h reminder (with golden time warning if applicable)
  Future<void> scheduleRemindersForProposal(
    SubscriptionProposal proposal,
  ) async {
    developer.log(
      '[ProposalReminderService] Scheduling reminders for proposal: ${proposal.id}',
      name: 'ProposalReminderService',
    );

    final now = DateTime.now();
    // 24h reminder
    final reminder24h = _createReminderNotification(
      proposal: proposal,
      type: NotificationType.proposalReminder24h,
      scheduledAt: now.add(const Duration(hours: 24)),
    );
    await _scheduleNotification(reminder24h);

    // 48h reminder
    final reminder48h = _createReminderNotification(
      proposal: proposal,
      type: NotificationType.proposalReminder48h,
      scheduledAt: now.add(const Duration(hours: 48)),
    );
    await _scheduleNotification(reminder48h);

    // 72h reminder (golden time warning)
    final reminder72h = _createReminderNotification(
      proposal: proposal,
      type: NotificationType.proposalReminder72h,
      scheduledAt: now.add(const Duration(hours: 72)),
    );
    await _scheduleNotification(reminder72h);

    developer.log(
      '[ProposalReminderService] Scheduled 3 reminders for proposal: ${proposal.id}',
      name: 'ProposalReminderService',
    );
  }

  /// Cancel all pending reminders for a proposal.
  ///
  /// Called when:
  /// - Student accepts the proposal
  /// - Proposal is cancelled
  /// - Proposal expires
  Future<void> cancelRemindersForProposal(String proposalId) async {
    developer.log(
      '[ProposalReminderService] Cancelling reminders for proposal: $proposalId',
      name: 'ProposalReminderService',
    );

    // Cancel all reminder types for this proposal
    await _cancelNotificationsByProposalId(proposalId);

    developer.log(
      '[ProposalReminderService] Cancelled all reminders for proposal: $proposalId',
      name: 'ProposalReminderService',
    );
  }

  /// Check if proposal is still pending before sending reminder.
  ///
  /// Returns true if reminder should be sent, false if proposal is no longer pending.
  Future<bool> shouldSendReminder(String proposalId) async {
    try {
      final proposal = await _loadProposal(proposalId);

      if (proposal == null) {
        developer.log(
          '[ProposalReminderService] Proposal not found: $proposalId',
          name: 'ProposalReminderService',
        );
        return false;
      }

      // Only send reminder if proposal is still pending
      final shouldSend = proposal.status == ProposalStatus.pending;

      developer.log(
        '[ProposalReminderService] Should send reminder for $proposalId: $shouldSend (status: ${proposal.status})',
        name: 'ProposalReminderService',
      );
      return shouldSend;
    } catch (e) {
      developer.log(
        '[ProposalReminderService] Error checking proposal status',
        name: 'ProposalReminderService',
        error: e,
      );
      return false;
    }
  }

  /// Create a reminder notification for a proposal.
  AppNotification _createReminderNotification({
    required SubscriptionProposal proposal,
    required NotificationType type,
    required DateTime scheduledAt,
  }) {
    final hasDiscount = (proposal.discountAmount ?? 0) > 0;

    return AppNotification(
      id: _uuid.v4(),
      userId: proposal.studentId,
      type: type,
      priority: type.defaultPriority,
      title: _copy.titleFor(type, hasDiscount: hasDiscount),
      body: _copy.bodyFor(type, hasDiscount: hasDiscount),
      data: {
        'proposalId': proposal.id,
        'teacherId': proposal.teacherId,
        'hasDiscount': hasDiscount,
      },
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
      actionUrl: '/proposals/${proposal.id}',
      actionLabel: _copy.actionLabel,
    );
  }
}
