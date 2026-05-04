import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subscription_proposal.dart';
import '../../domain/services/auto_proposal_service.dart';
import '../../domain/services/subscription_expiry_monitor.dart';
import '../../domain/services/subscription_renewal_service.dart';
import 'proposal_settings_providers.dart';
import 'subscription_proposal_providers.dart';
import 'subscription_providers.dart';
import 'subscription_template_providers.dart';

final autoProposalServiceProvider = Provider<AutoProposalService>((ref) {
  return AutoProposalService(
    loadSettings:
        (teacherId) =>
            ref.read(teacherProposalSettingsProvider(teacherId).future),
    loadActiveProposal:
        (teacherId, studentId) => ref.read(
          activeProposalBetweenProvider(teacherId, studentId).future,
        ),
    loadAutoProposalTemplates:
        (teacherId) =>
            ref.read(autoProposalTemplatesProvider(teacherId).future),
    createAutoProposal: ({
      required teacherId,
      required studentId,
      required templateIds,
      recommendedTemplateId,
      required message,
      discountAmount,
      discountReason,
      required isAutoProposal,
    }) {
      return ref
          .read(subscriptionProposalNotifierProvider.notifier)
          .createMultiChoiceProposal(
            teacherId: teacherId,
            studentId: studentId,
            templateIds: templateIds,
            recommendedTemplateId: recommendedTemplateId,
            message: message,
            discountAmount: discountAmount,
            discountReason: discountReason,
            isAutoProposal: isAutoProposal,
          );
    },
  );
});

final subscriptionRenewalServiceProvider = Provider<SubscriptionRenewalService>(
  (ref) {
    return SubscriptionRenewalService(
      loadActiveProposal:
          (teacherId, studentId) => ref.read(
            activeProposalBetweenProvider(teacherId, studentId).future,
          ),
      loadRenewalTemplates:
          (teacherId) =>
              ref.read(autoProposalTemplatesProvider(teacherId).future),
      createRenewalProposal: ({
        required teacherId,
        required studentId,
        required templateIds,
        recommendedTemplateId,
        required message,
        required isAutoProposal,
        required isRenewal,
        required previousSubscriptionId,
        required renewalInitiator,
      }) {
        return ref
            .read(subscriptionProposalNotifierProvider.notifier)
            .createMultiChoiceProposal(
              teacherId: teacherId,
              studentId: studentId,
              templateIds: templateIds,
              recommendedTemplateId: recommendedTemplateId,
              message: message,
              isAutoProposal: isAutoProposal,
              isRenewal: isRenewal,
              previousSubscriptionId: previousSubscriptionId,
              renewalInitiator: renewalInitiator,
            );
      },
    );
  },
);

final subscriptionExpiryMonitorProvider = Provider<SubscriptionExpiryMonitor>((
  ref,
) {
  return SubscriptionExpiryMonitor(
    loadExpiringSoonSubscriptions:
        () => ref.read(expiringSoonSubscriptionsProvider.future),
    loadExpiredSubscriptions:
        () => ref.read(expiredSubscriptionsProvider.future),
    triggerSubscriptionRenewal: (subscription) {
      // TODO: resolve teacherId from membership/class relationship.
      ref
          .read(subscriptionRenewalServiceProvider)
          .triggerOnSubscriptionLow(
            subscription: subscription,
            teacherId: '',
            initiator: RenewalInitiator.system,
          );
    },
  );
});
