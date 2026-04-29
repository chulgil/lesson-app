import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/l10n/app_strings.dart';
import '../entities/subscription.dart';
import '../entities/subscription_proposal.dart';
import '../../presentation/providers/subscription_proposal_providers.dart';
import '../../presentation/providers/subscription_template_providers.dart';

part 'subscription_renewal_service.g.dart';

@riverpod
SubscriptionRenewalService subscriptionRenewalService(Ref ref) {
  return SubscriptionRenewalService(ref);
}

/// Service that creates renewal proposals when subscriptions are running low.
///
/// Like a gym's front desk automatically preparing a membership renewal form
/// when your current membership is about to expire — pre-filled with your
/// existing plan details so you just need to confirm.
class SubscriptionRenewalService {
  final Ref _ref;

  SubscriptionRenewalService(this._ref);

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
      final existingProposal = await _ref.read(
        activeProposalBetweenProvider(teacherId, subscription.studentId).future,
      );

      if (existingProposal != null) {
        debugPrint(
          '[RenewalService] Active proposal already exists for student ${subscription.studentId}',
        );
        return null;
      }

      // 2. Get auto-proposal templates for renewal
      final templates = await _ref.read(
        autoProposalTemplatesProvider(teacherId).future,
      );

      if (templates.isEmpty) {
        debugPrint('[RenewalService] No auto-proposal templates available');
        return null;
      }

      // 3. Find matching template (same as previous subscription if possible)
      final proposalTemplates = templates;

      // 4. Create renewal proposal
      final notifier = _ref.read(subscriptionProposalNotifierProvider.notifier);

      final proposal = await notifier.createMultiChoiceProposal(
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

      debugPrint(
        '[RenewalService] Renewal proposal created: ${proposal.id} '
        'for student ${subscription.studentId}',
      );

      return proposal;
    } catch (e) {
      debugPrint('[RenewalService] Error creating renewal proposal: $e');
      return null;
    }
  }

  String _buildRenewalMessage(Subscription sub) {
    final remaining = sub.remainingLessons ?? 0;
    final buffer = StringBuffer();

    if (remaining <= 0) {
      buffer.write(AppStrings.renewalMessageDepleted);
    } else if (remaining == 1) {
      buffer.write(AppStrings.renewalMessageLastOne);
    } else {
      buffer.write(AppStrings.renewalMessageRemaining(remaining));
    }

    buffer.write(AppStrings.renewalMessageContinue);
    return buffer.toString();
  }
}
