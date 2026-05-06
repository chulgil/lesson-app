import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/subscription_template.dart';

extension SubscriptionTemplateVisualX on SubscriptionTemplate {
  /// Display label (e.g., "8회권 (50분)")
  String get displayLabel =>
      '$name (${AppStrings.durationMinutesValue(lessonDurationMinutes)})';

  /// Owner type display label
  String get ownerTypeLabel {
    switch (ownerType) {
      case SubscriptionTemplateOwnerType.teacher:
        return AppStrings.individual;
      case SubscriptionTemplateOwnerType.academy:
        return AppStrings.academy;
    }
  }

  /// Formatted price (e.g., "40만원")
  String get formattedPrice => _formatWon(price);

  /// Formatted price per lesson
  String get formattedPricePerLesson => _formatWon(pricePerLesson);

  /// Formatted validity period
  String get formattedValidity {
    if (validityDays >= 30) {
      final months = validityDays ~/ 30;
      return AppStrings.monthCount(months);
    }
    return AppStrings.dayCount(validityDays);
  }

  /// Summary text (e.g., "8회 · 50분 · 40만원")
  String get summaryText => AppStrings.subscriptionTemplateSummaryText(
    totalLessons: totalLessons,
    durationMinutes: lessonDurationMinutes,
    priceLabel: formattedPrice,
  );

  String _formatWon(int amount) {
    if (amount >= 10000) {
      final man = amount ~/ 10000;
      final remainder = amount % 10000;
      if (remainder == 0) {
        return AppStrings.amountManwon(man.toString());
      }
      return AppStrings.amountManwonWithRemainder(man, remainder);
    }
    return AppStrings.amountWon(amount);
  }
}
