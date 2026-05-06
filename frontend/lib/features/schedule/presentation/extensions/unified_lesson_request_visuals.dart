import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/unified_lesson_request.dart';

const _shortWeekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

extension LessonRequestTypeVisualX on LessonRequestType {
  String get label {
    switch (this) {
      case LessonRequestType.trial:
        return AppStrings.lessonRequestTypeTrial;
      case LessonRequestType.regular:
        return AppStrings.lessonRequestTypeRegular;
      case LessonRequestType.package:
        return AppStrings.lessonRequestTypePackage;
    }
  }
}

extension UnifiedLessonGoalVisualX on UnifiedLessonGoal {
  String get label {
    switch (this) {
      case UnifiedLessonGoal.hobby:
        return AppStrings.lessonGoalHobby;
      case UnifiedLessonGoal.exam:
        return AppStrings.lessonGoalExam;
      case UnifiedLessonGoal.major:
        return AppStrings.lessonGoalMajor;
      case UnifiedLessonGoal.other:
        return AppStrings.lessonGoalOther;
    }
  }
}

extension UnifiedExperienceLevelVisualX on UnifiedExperienceLevel {
  String get label {
    switch (this) {
      case UnifiedExperienceLevel.beginner:
        return AppStrings.experienceLevelBeginner;
      case UnifiedExperienceLevel.intermediate:
        return AppStrings.experienceLevelIntermediate;
      case UnifiedExperienceLevel.advanced:
        return AppStrings.experienceLevelAdvanced;
    }
  }
}

extension UnifiedRequestStatusVisualX on UnifiedRequestStatus {
  String get label {
    switch (this) {
      case UnifiedRequestStatus.pending:
        return AppStrings.statusPending;
      case UnifiedRequestStatus.approved:
        return AppStrings.statusApproved;
      case UnifiedRequestStatus.negotiating:
        return AppStrings.statusNegotiatingShort;
      case UnifiedRequestStatus.timeConfirmed:
        return AppStrings.statusTimeConfirmed;
      case UnifiedRequestStatus.proposalSent:
        return AppStrings.statusProposalSent;
      case UnifiedRequestStatus.proposalAccepted:
        return AppStrings.statusProposalAccepted;
      case UnifiedRequestStatus.paymentNotified:
        return AppStrings.statusPaymentDone;
      case UnifiedRequestStatus.completed:
        return AppStrings.statusCompleted;
      case UnifiedRequestStatus.rejected:
        return AppStrings.statusRejected;
      case UnifiedRequestStatus.cancelled:
        return AppStrings.statusCancelled;
      case UnifiedRequestStatus.expired:
        return AppStrings.statusExpiredFull;
      case UnifiedRequestStatus.subscriptionIssued:
        return AppStrings.statusSubscriptionIssued;
      case UnifiedRequestStatus.inProgress:
        return AppStrings.statusInProgress;
    }
  }
}

extension TimeSlotOptionVisualX on TimeSlotOption {
  String get dayLabel => _shortWeekdayLabels[dayOfWeek.clamp(0, 6)];

  String get displayLabel {
    if (date != null) {
      return '${date!.month}/${date!.day}($dayLabel) $startTime ~ $endTime';
    }
    return '$dayLabel $startTime ~ $endTime';
  }
}

extension PreferredTimeSlotVisualX on PreferredTimeSlot {
  String get displayLabel {
    if (date != null) {
      final d = date!;
      final dayLabel = _shortWeekdayLabels[d.weekday - 1];
      return '${d.month}/${d.day}($dayLabel) $startTime ~ $endTime';
    }
    if (dayOfWeek != null) {
      return '${_shortWeekdayLabels[dayOfWeek!.clamp(0, 6)]} '
          '$startTime ~ $endTime';
    }
    return '$startTime ~ $endTime';
  }
}

extension UnifiedLessonRequestVisualX on UnifiedLessonRequest {
  String get typeDisplayLabel {
    if (isReturningStudent && type == LessonRequestType.regular) {
      return AppStrings.returning;
    }
    return type.label;
  }

  String? get preferredDayLabel {
    if (preferredDay == null) return null;
    return '${_shortWeekdayLabels[preferredDay!.clamp(0, 6)]}요일';
  }

  String get statusChipLabel {
    switch (status) {
      case UnifiedRequestStatus.pending:
        return AppStrings.statusPending;
      case UnifiedRequestStatus.approved:
        return AppStrings.statusApproved;
      case UnifiedRequestStatus.negotiating:
        return AppStrings.statusNegotiating(currentRound);
      case UnifiedRequestStatus.timeConfirmed:
        return AppStrings.statusTimeConfirmed;
      case UnifiedRequestStatus.proposalSent:
        return AppStrings.statusProposalSent;
      case UnifiedRequestStatus.proposalAccepted:
        return AppStrings.statusProposalAccepted;
      case UnifiedRequestStatus.paymentNotified:
        return AppStrings.statusPaymentDone;
      case UnifiedRequestStatus.completed:
        return AppStrings.statusCompleted;
      case UnifiedRequestStatus.rejected:
        return AppStrings.statusRejected;
      case UnifiedRequestStatus.cancelled:
        return AppStrings.statusCancelled;
      case UnifiedRequestStatus.expired:
        return AppStrings.statusExpiredFull;
      case UnifiedRequestStatus.subscriptionIssued:
        return AppStrings.statusSubscriptionIssued;
      case UnifiedRequestStatus.inProgress:
        return AppStrings.statusInProgress;
    }
  }

  String get teacherActionLabel {
    if (status.isTerminal) return AppStrings.statusCompleted;
    if (isTeacherActionRequired) return AppStrings.actionRequired;
    return AppStrings.responseWaiting;
  }

  String get studentActionLabel {
    if (status.isTerminal) return AppStrings.statusCompleted;
    if (isStudentActionRequired) return AppStrings.actionRequired;
    return AppStrings.responseWaiting;
  }
}
