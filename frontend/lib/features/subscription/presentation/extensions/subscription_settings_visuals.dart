import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/subscription_settings.dart';

extension PackageDiscountPolicyVisualX on PackageDiscountPolicy {
  String get displayText {
    switch (type) {
      case DiscountType.discount:
        return AppStrings.packageDiscountPolicyText(
          minLessons: minLessons,
          value: value,
        );
      case DiscountType.bonusLessons:
        return AppStrings.packageBonusPolicyText(
          minLessons: minLessons,
          value: value,
        );
    }
  }
}
