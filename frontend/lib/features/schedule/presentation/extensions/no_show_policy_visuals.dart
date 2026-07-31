import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/group_class.dart';

/// Presentation-layer visuals for [NoShowPolicy].
///
/// Domain stays pure (no display getters) — the labels live here per the C3
/// consistency contract, and the switches are exhaustive so a new backend
/// policy value fails the build instead of silently falling through.
extension NoShowPolicyVisuals on NoShowPolicy {
  /// Short label for inline policy summaries.
  String get label => switch (this) {
    NoShowPolicy.deductCredit => AppStrings.noShowPolicyDeductCredit,
    NoShowPolicy.halfCredit => AppStrings.noShowPolicyHalfCredit,
    NoShowPolicy.noDeduction => AppStrings.noShowPolicyNoDeduction,
    NoShowPolicy.reschedule => AppStrings.noShowPolicyReschedule,
  };

  /// Full sentence describing what happens to an absent student.
  String get description => switch (this) {
    NoShowPolicy.deductCredit => AppStrings.noShowPolicyDeductCreditDescription,
    NoShowPolicy.halfCredit => AppStrings.noShowPolicyHalfCreditDescription,
    NoShowPolicy.noDeduction => AppStrings.noShowPolicyNoDeductionDescription,
    NoShowPolicy.reschedule => AppStrings.noShowPolicyRescheduleDescription,
  };
}
