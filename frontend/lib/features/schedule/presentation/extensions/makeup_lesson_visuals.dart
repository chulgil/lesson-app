import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/makeup_lesson.dart';

extension MakeupStatusVisualX on MakeupStatus {
  String get label {
    switch (this) {
      case MakeupStatus.pending:
        return AppStrings.makeupStatusPending;
      case MakeupStatus.scheduled:
        return AppStrings.makeupStatusScheduled;
      case MakeupStatus.completed:
        return AppStrings.makeupStatusCompleted;
      case MakeupStatus.expired:
        return AppStrings.makeupStatusExpired;
      case MakeupStatus.waived:
        return AppStrings.makeupStatusWaived;
    }
  }
}

extension MakeupReasonVisualX on MakeupReason {
  String get label {
    switch (this) {
      case MakeupReason.studentCancellation:
        return AppStrings.makeupReasonStudentCancellation;
      case MakeupReason.teacherCancellation:
        return AppStrings.makeupReasonTeacherCancellation;
      case MakeupReason.noShowReschedule:
        return AppStrings.makeupReasonNoShowReschedule;
      case MakeupReason.other:
        return AppStrings.makeupReasonOther;
    }
  }
}
