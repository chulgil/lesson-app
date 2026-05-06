import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/no_show_policy.dart';

extension NoShowPolicyVisualX on NoShowPolicy {
  String get label {
    switch (this) {
      case NoShowPolicy.deductCredit:
        return AppStrings.noShowPolicyDeductCredit;
      case NoShowPolicy.halfCredit:
        return AppStrings.noShowPolicyHalfCredit;
      case NoShowPolicy.noDeduction:
        return AppStrings.noShowPolicyNoDeduction;
      case NoShowPolicy.reschedule:
        return AppStrings.noShowPolicyReschedule;
    }
  }

  String get description {
    switch (this) {
      case NoShowPolicy.deductCredit:
        return AppStrings.noShowPolicyDeductCreditDescription;
      case NoShowPolicy.halfCredit:
        return AppStrings.noShowPolicyHalfCreditDescription;
      case NoShowPolicy.noDeduction:
        return AppStrings.noShowPolicyNoDeductionDescription;
      case NoShowPolicy.reschedule:
        return AppStrings.noShowPolicyRescheduleDescription;
    }
  }
}
