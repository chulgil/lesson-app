import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/subscription.dart';

extension SubscriptionPaymentMethodVisualX on SubscriptionPaymentMethod {
  String get label {
    switch (this) {
      case SubscriptionPaymentMethod.cash:
        return AppStrings.paymentMethodCash;
      case SubscriptionPaymentMethod.bankTransfer:
        return AppStrings.paymentMethodBankTransfer;
      case SubscriptionPaymentMethod.card:
        return AppStrings.paymentMethodCard;
      case SubscriptionPaymentMethod.other:
        return AppStrings.paymentMethodOther;
    }
  }
}

extension SubscriptionVisualX on Subscription {
  String get paymentStatusLabel {
    if (paymentConfirmed) return AppStrings.paymentStatusPaid;
    if (needsPaymentConfirmation) {
      return AppStrings.paymentStatusNeedsConfirmation;
    }
    return AppStrings.paymentStatusUnpaid;
  }

  String get typeLabel {
    switch (type) {
      case SubscriptionType.trial:
        return AppStrings.subscriptionTypeTrial;
      case SubscriptionType.monthly:
        return lessonsPerMonth != null
            ? AppStrings.subscriptionTypeMonthlyWithCount(lessonsPerMonth!)
            : AppStrings.subscriptionTypeMonthly;
      case SubscriptionType.package:
        return AppStrings.subscriptionTypePackageWithCount(totalLessons ?? 0);
    }
  }

  String get statusLabel {
    switch (status) {
      case SubscriptionStatus.active:
        return AppStrings.subscriptionStatusActive;
      case SubscriptionStatus.expiringSoon:
        return AppStrings.subscriptionStatusExpiringSoon;
      case SubscriptionStatus.expired:
        return AppStrings.subscriptionStatusExpired;
      case SubscriptionStatus.paused:
        return AppStrings.subscriptionStatusPaused;
    }
  }

  String get summaryText {
    if (type == SubscriptionType.trial) {
      return usedLessons > 0
          ? AppStrings.trialCompleted
          : AppStrings.trialOngoing;
    }

    final remaining = remainingLessons;
    final total = totalLessonsForDisplay;
    final days = daysUntilExpiration;

    if (isDepleted && total != null) {
      return AppStrings.subscriptionAllUsed(total);
    }

    if (isExpired && remaining != null && remaining > 0) {
      return AppStrings.subscriptionUnusedExpired(remaining);
    }

    final countPart =
        (remaining != null && total != null)
            ? AppStrings.subscriptionRemainingOf(remaining, total)
            : '';

    String daysPart = '';
    if (status == SubscriptionStatus.paused) {
      daysPart = AppStrings.subscriptionStatusPaused;
    } else if (isExpired) {
      daysPart = AppStrings.subscriptionStatusExpired;
    } else if (days != null && days > 0) {
      daysPart = AppStrings.daysUntilExpirationFormat(days);
    } else if (days != null && days <= 0) {
      daysPart = AppStrings.subscriptionStatusExpired;
    }

    if (countPart.isNotEmpty && daysPart.isNotEmpty) {
      return AppStrings.subscriptionSummaryWithDays(countPart, daysPart);
    }
    return countPart.isNotEmpty ? countPart : daysPart;
  }

  String? get bonusText {
    if (bonusCount <= 0) return null;
    final reason = bonusReason ?? AppStrings.bonusDefault;
    return AppStrings.bonusText(bonusCount, reason);
  }

  String get detailText {
    if (type == SubscriptionType.trial) {
      return amount > 0
          ? AppStrings.trialLessonWithAmount(_formatAmount(amount))
          : AppStrings.freeTrialLesson;
    }

    final base = baseLessons;
    final buffer = StringBuffer();

    if (type == SubscriptionType.monthly) {
      buffer.write(AppStrings.detailBaseLessons(base ?? 0));
    } else {
      buffer.write(AppStrings.detailPackageUsage(base ?? 0, usedLessons));
    }

    if (bonusCount > 0) {
      buffer.write(AppStrings.detailBonusLine(bonusCount));
      if (bonusReason != null) {
        buffer.write(AppStrings.detailBonusReasonInline(bonusReason!));
      }
    }

    return buffer.toString();
  }

  String? get billingTypeLabel {
    if (billingType == null) return null;
    switch (billingType!) {
      case BillingType.perPackage:
        return AppStrings.billingTypePerPackage;
      case BillingType.monthly:
        return billingDay != null
            ? AppStrings.billingTypeMonthlyWithDay(billingDay!)
            : AppStrings.subscriptionTypeMonthly;
    }
  }

  String? get fifthWeekPolicyLabel {
    if (fifthWeekPolicy == null) return null;
    switch (fifthWeekPolicy!) {
      case FifthWeekPolicy.skip:
        return AppStrings.fifthWeekSkip;
      case FifthWeekPolicy.bonus:
        return AppStrings.fifthWeekBonus;
      case FifthWeekPolicy.deduct:
        return AppStrings.fifthWeekDeduct;
      case FifthWeekPolicy.optional:
        return AppStrings.fifthWeekOptional;
    }
  }

  String _formatAmount(int amount) {
    if (amount >= 10000) {
      return AppStrings.amountManwon((amount / 10000).toStringAsFixed(0));
    }
    return AppStrings.amountWon(amount);
  }
}
