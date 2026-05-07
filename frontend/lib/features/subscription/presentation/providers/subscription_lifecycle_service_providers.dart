import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/proposal_settings.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/services/auto_proposal_service.dart';
import '../../domain/services/subscription_expiry_monitor.dart';
import '../../domain/services/subscription_renewal_service.dart';
import 'proposal_settings_providers.dart';
import 'subscription_proposal_providers.dart';
import 'subscription_providers.dart';
import 'subscription_template_providers.dart';

part 'subscription_lifecycle_service_providers.g.dart';

@Riverpod(keepAlive: true)
AutoProposalService autoProposalService(AutoProposalServiceRef ref) {
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
    buildAutoProposalMessage: _buildAutoProposalMessage,
    buildGoldenTimeDiscountReason: ({
      required discountPercent,
      required goldenTimeHours,
    }) {
      return AppStrings.autoProposalGoldenTimeReason(
        discountPercent,
        goldenTimeHours,
      );
    },
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
}

String _buildAutoProposalMessage(ProposalSettings settings) {
  final buffer = StringBuffer();
  buffer.write(AppStrings.autoProposalGreeting);

  if (settings.hasGoldenTimeDiscount) {
    buffer.write(
      AppStrings.autoProposalGoldenTimeHours(settings.goldenTimeHours),
    );
    buffer.write(
      AppStrings.autoProposalGoldenTimePercent(
        settings.goldenTimeDiscountPercent,
      ),
    );
  }

  buffer.write(AppStrings.autoProposalSelectionPrompt);
  return buffer.toString();
}

@Riverpod(keepAlive: true)
SubscriptionRenewalService subscriptionRenewalService(
  SubscriptionRenewalServiceRef ref,
) {
  return SubscriptionRenewalService(
    loadActiveProposal:
        (teacherId, studentId) => ref.read(
          activeProposalBetweenProvider(teacherId, studentId).future,
        ),
    loadRenewalTemplates:
        (teacherId) =>
            ref.read(autoProposalTemplatesProvider(teacherId).future),
    buildRenewalMessage: _buildRenewalMessage,
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

@Riverpod(keepAlive: true)
SubscriptionExpiryMonitor subscriptionExpiryMonitor(
  SubscriptionExpiryMonitorRef ref,
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
    copy: SubscriptionExpiryCopy(
      expiringTitle: AppStrings.subscriptionExpiringTitle,
      expiringBody: AppStrings.subscriptionExpiringBody,
      viewActionLabel: AppStrings.subscriptionViewAction,
      lessonsExhaustedTitle: AppStrings.subscriptionLessonsExhaustedTitle,
      lastLessonTitle: AppStrings.subscriptionLastLessonTitle,
      renewalRequestBody: AppStrings.subscriptionRenewalRequestBody,
      renewalActionLabel: AppStrings.subscriptionRenewalAction,
      expiredTitle: AppStrings.subscriptionExpiredTitle,
    ),
  );
}
