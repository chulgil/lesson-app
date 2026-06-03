import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/makeup_credit.dart';

/// Presentation-layer display mapping for makeup credits (#432).
///
/// Keeps the domain entity pure — labels live here, not on the enum.
extension MakeupCreditReasonVisualX on MakeupCreditReason {
  String get label {
    switch (this) {
      case MakeupCreditReason.teacherVacation:
        return AppStrings.makeupCreditReasonTeacherVacation;
      case MakeupCreditReason.noShowExempt:
        return AppStrings.makeupCreditReasonNoShowExempt;
      case MakeupCreditReason.bulkChangeLoss:
        return AppStrings.makeupCreditReasonBulkChangeLoss;
      case MakeupCreditReason.manualGrant:
        return AppStrings.makeupCreditReasonManualGrant;
    }
  }
}
