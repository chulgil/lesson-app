import 'dart:developer' as developer;

import '../entities/subscription.dart';
import '../entities/subscription_proposal.dart';
import '../entities/subscription_template.dart';

typedef LoadActiveRenewalProposal =
    Future<SubscriptionProposal?> Function(String teacherId, String studentId);
typedef LoadRenewalTemplates =
    Future<List<SubscriptionTemplate>> Function(String teacherId);
typedef CreateRenewalProposal =
    Future<SubscriptionProposal> Function({
      required String teacherId,
      required String studentId,
      required List<String> templateIds,
      String? recommendedTemplateId,
      required String message,
      required bool isAutoProposal,
      required bool isRenewal,
      required String previousSubscriptionId,
      required RenewalInitiator renewalInitiator,
    });
typedef BuildRenewalMessage = String Function(Subscription subscription);

/// Service that creates renewal proposals when subscriptions are running low.
///
/// Like a gym's front desk automatically preparing a membership renewal form
/// when your current membership is about to expire — pre-filled with your
/// existing plan details so you just need to confirm.
class SubscriptionRenewalService {
  final LoadActiveRenewalProposal _loadActiveProposal;
  final LoadRenewalTemplates _loadRenewalTemplates;
  final CreateRenewalProposal _createRenewalProposal;
  final BuildRenewalMessage _buildRenewalMessage;

  const SubscriptionRenewalService({
    required LoadActiveRenewalProposal loadActiveProposal,
    required LoadRenewalTemplates loadRenewalTemplates,
    required CreateRenewalProposal createRenewalProposal,
    required BuildRenewalMessage buildRenewalMessage,
  }) : _loadActiveProposal = loadActiveProposal,
       _loadRenewalTemplates = loadRenewalTemplates,
       _createRenewalProposal = createRenewalProposal,
       _buildRenewalMessage = buildRenewalMessage;

  /// Trigger renewal proposal for a subscription that is running low.
  ///
  /// Called by SubscriptionExpiryMonitor when:
  /// - Remaining lessons <= 2
  /// - Days until expiration <= 7
  /// - Subscription fully depleted (remaining = 0)
  Future<SubscriptionProposal?> triggerOnSubscriptionLow({
    required Subscription subscription,
    required String teacherId,
    RenewalInitiator initiator = RenewalInitiator.system,
  }) async {
    try {
      // 1. Check if there's already an active proposal for this student
      final existingProposal = await _loadActiveProposal(
        teacherId,
        subscription.studentId,
      );

      if (existingProposal != null) {
        developer.log(
          '[RenewalService] Active proposal already exists for student ${subscription.studentId}',
        );
        return null;
      }

      // 2. Get auto-proposal templates for renewal
      final templates = await _loadRenewalTemplates(teacherId);

      if (templates.isEmpty) {
        developer.log('[RenewalService] No auto-proposal templates available');
        return null;
      }

      // 3. Find matching template (same as previous subscription if possible)
      final proposalTemplates = templates;

      // 4. Create renewal proposal
      final proposal = await _createRenewalProposal(
        teacherId: teacherId,
        studentId: subscription.studentId,
        templateIds: proposalTemplates.map((t) => t.id).toList(),
        recommendedTemplateId:
            proposalTemplates.length > 1 ? proposalTemplates.first.id : null,
        message: _buildRenewalMessage(subscription),
        isAutoProposal: initiator == RenewalInitiator.system,
        isRenewal: true,
        previousSubscriptionId: subscription.id,
        renewalInitiator: initiator,
      );

      developer.log(
        '[RenewalService] Renewal proposal created: ${proposal.id} '
        'for student ${subscription.studentId}',
      );

      return proposal;
    } catch (e) {
      developer.log('[RenewalService] Error creating renewal proposal: $e');
      return null;
    }
  }
}
