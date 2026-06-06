import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/cancel_reason.dart';

/// Display strings for [CancelReason] (presentation boundary — domain stays pure).
extension CancelReasonVisuals on CancelReason {
  String get label => switch (this) {
    CancelReason.studentSchedule => AppStrings.cancelReasonStudentSchedule,
    CancelReason.studentSick => AppStrings.cancelReasonStudentSick,
    CancelReason.teacherCancel => AppStrings.cancelReasonTeacher,
    CancelReason.mutual => AppStrings.cancelReasonMutual,
  };
}
