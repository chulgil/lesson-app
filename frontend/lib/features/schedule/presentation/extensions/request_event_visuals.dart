import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/request_event.dart';

extension RequestEventTypeVisualX on RequestEventType {
  String get label {
    switch (this) {
      case RequestEventType.initialRequest:
        return AppStrings.eventLessonRequest;
      case RequestEventType.approve:
        return AppStrings.eventApprove;
      case RequestEventType.reject:
        return AppStrings.eventReject;
      case RequestEventType.proposeAlternative:
      case RequestEventType.counterPropose:
        return AppStrings.eventProposeAlternative;
      case RequestEventType.acceptAlternative:
        return AppStrings.eventAcceptAlternative;
      case RequestEventType.cancel:
        return AppStrings.eventCancel;
      case RequestEventType.expire:
        return AppStrings.eventExpire;
      case RequestEventType.proposalSent:
        return AppStrings.eventProposalSent;
      case RequestEventType.proposalAccepted:
        return AppStrings.eventProposalAccepted;
      case RequestEventType.paymentNotified:
        return AppStrings.eventPaymentNotified;
      case RequestEventType.completed:
        return AppStrings.eventCompleted;
      case RequestEventType.withdrawApproval:
        return AppStrings.eventWithdrawApproval;
      case RequestEventType.paymentRequested:
        return AppStrings.eventPaymentRequested;
      case RequestEventType.paymentConfirmed:
        return AppStrings.eventPaymentConfirmed;
      case RequestEventType.subscriptionIssued:
        return AppStrings.eventSubscriptionIssued;
      case RequestEventType.lessonCompleted:
        return AppStrings.eventLessonCompleted;
      case RequestEventType.lessonCancelled:
        return AppStrings.eventLessonCancelled;
      case RequestEventType.scheduleChanged:
        return AppStrings.eventScheduleChanged;
      case RequestEventType.lessonNoteAdded:
        return AppStrings.eventLessonNoteAdded;
      case RequestEventType.subscriptionRenewed:
        return AppStrings.eventSubscriptionRenewed;
      case RequestEventType.subscriptionCompleted:
        return AppStrings.eventSubscriptionCompleted;
      case RequestEventType.scheduleChangeProposed:
        return AppStrings.eventScheduleChangeProposed;
      case RequestEventType.scheduleChangeAccepted:
        return AppStrings.eventScheduleChangeAccepted;
      case RequestEventType.scheduleChangeRejected:
        return AppStrings.eventScheduleChangeRejected;
      case RequestEventType.scheduleChangeCountered:
        return AppStrings.eventScheduleChangeCountered;
      case RequestEventType.message:
        return '';
      case RequestEventType.lessonCancellationConfirmed:
        return AppStrings.eventLessonCancellationConfirmed;
      case RequestEventType.cancellationCreditRefunded:
        return AppStrings.eventCancellationCreditRefunded;
      case RequestEventType.lessonCancelledByTeacher:
        return AppStrings.eventLessonCancelledByTeacher;
      case RequestEventType.teacherAnnouncement:
        return AppStrings.eventTeacherAnnouncement;
    }
  }
}

extension RequestEventVisualX on RequestEvent {
  String get chatDisplayMessage {
    switch (eventType) {
      case RequestEventType.initialRequest:
        return AppStrings.chatInitialRequest;
      case RequestEventType.approve:
        return AppStrings.chatApprove;
      case RequestEventType.reject:
        return AppStrings.chatReject;
      case RequestEventType.proposeAlternative:
      case RequestEventType.counterPropose:
        return AppStrings.chatProposeAlternative;
      case RequestEventType.acceptAlternative:
        return AppStrings.chatAcceptAlternative;
      case RequestEventType.cancel:
        return AppStrings.chatCancel;
      case RequestEventType.expire:
        return AppStrings.chatExpire;
      case RequestEventType.proposalSent:
        return AppStrings.chatProposalSent;
      case RequestEventType.proposalAccepted:
        return AppStrings.chatProposalAccepted;
      case RequestEventType.paymentNotified:
        return AppStrings.chatPaymentNotified;
      case RequestEventType.completed:
        return AppStrings.chatCompleted;
      case RequestEventType.withdrawApproval:
        return AppStrings.chatWithdrawApproval;
      case RequestEventType.paymentRequested:
        return AppStrings.chatPaymentRequested;
      case RequestEventType.paymentConfirmed:
        return AppStrings.chatPaymentConfirmed;
      case RequestEventType.subscriptionIssued:
        return AppStrings.chatSubscriptionIssued;
      case RequestEventType.lessonCompleted:
        return AppStrings.chatLessonCompleted;
      case RequestEventType.lessonCancelled:
        return AppStrings.chatLessonCancelled;
      case RequestEventType.scheduleChanged:
        return AppStrings.chatScheduleChanged;
      case RequestEventType.lessonNoteAdded:
        return AppStrings.chatLessonNoteAdded;
      case RequestEventType.subscriptionRenewed:
        return AppStrings.chatSubscriptionRenewed;
      case RequestEventType.subscriptionCompleted:
        return AppStrings.chatSubscriptionCompleted;
      case RequestEventType.scheduleChangeProposed:
        return AppStrings.chatScheduleChangeProposed;
      case RequestEventType.scheduleChangeAccepted:
        return AppStrings.chatScheduleChangeAccepted;
      case RequestEventType.scheduleChangeRejected:
        return AppStrings.chatScheduleChangeRejected;
      case RequestEventType.scheduleChangeCountered:
        return AppStrings.chatScheduleChangeCountered;
      case RequestEventType.message:
        return message ?? '';
      case RequestEventType.lessonCancellationConfirmed:
        return AppStrings.eventLessonCancellationConfirmed;
      case RequestEventType.cancellationCreditRefunded:
        return AppStrings.cancellationCreditRefundedChat;
      case RequestEventType.lessonCancelledByTeacher:
        return AppStrings.chatLessonCancelledByTeacher;
      case RequestEventType.teacherAnnouncement:
        return message ?? AppStrings.chatTeacherAnnouncement;
    }
  }
}
