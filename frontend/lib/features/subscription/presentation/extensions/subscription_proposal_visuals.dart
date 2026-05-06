import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/subscription_proposal.dart';

extension ProposalPaymentStatusVisualX on ProposalPaymentStatus {
  String get label {
    switch (this) {
      case ProposalPaymentStatus.pending:
        return AppStrings.proposalPaymentStatusPending;
      case ProposalPaymentStatus.completed:
        return AppStrings.proposalPaymentStatusCompleted;
    }
  }

  String get description {
    switch (this) {
      case ProposalPaymentStatus.pending:
        return AppStrings.proposalPaymentDescPending;
      case ProposalPaymentStatus.completed:
        return AppStrings.proposalPaymentDescCompleted;
    }
  }
}

extension ProposalStatusVisualX on ProposalStatus {
  String get label {
    switch (this) {
      case ProposalStatus.pending:
        return AppStrings.proposalStatusPending;
      case ProposalStatus.paymentNotified:
        return AppStrings.proposalStatusPaymentNotified;
      case ProposalStatus.confirmed:
        return AppStrings.proposalStatusConfirmed;
      case ProposalStatus.rejected:
        return AppStrings.proposalStatusRejected;
      case ProposalStatus.expired:
        return AppStrings.expired;
      case ProposalStatus.cancelled:
        return AppStrings.proposalStatusCancelled;
    }
  }
}

extension ProposalTypeVisualX on ProposalType {
  String get label {
    switch (this) {
      case ProposalType.proposal:
        return AppStrings.proposalTypeProposal;
      case ProposalType.directIssue:
        return AppStrings.proposalTypeDirectIssue;
    }
  }
}

extension SubscriptionProposalVisualX on SubscriptionProposal {
  String get statusLabel => status.label;

  String get timeSinceCreated {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) {
      return AppStrings.timeAgoDays(diff.inDays);
    } else if (diff.inHours > 0) {
      return AppStrings.timeAgoHours(diff.inHours);
    } else if (diff.inMinutes > 0) {
      return AppStrings.timeAgoMinutes(diff.inMinutes);
    }
    return AppStrings.timeAgoJustNow;
  }

  String get formattedExpiration {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) {
      return AppStrings.expired;
    } else if (diff.inDays > 0) {
      return AppStrings.expiresInDays(diff.inDays);
    } else if (diff.inHours > 0) {
      return AppStrings.expiresInHours(diff.inHours);
    } else if (diff.inMinutes > 0) {
      return AppStrings.expiresInMinutes(diff.inMinutes);
    }
    return AppStrings.expiresVerySoon;
  }
}
