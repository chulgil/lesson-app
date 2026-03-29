import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/l10n/app_strings.dart';
import 'lesson_schedule_change.dart';
import 'unified_lesson_request.dart';

part 'request_event.g.dart';

/// Type of event in a lesson request lifecycle (chat history).
@HiveType(typeId: 130)
enum RequestEventType {
  @HiveField(0)
  initialRequest,

  @HiveField(1)
  approve,

  @HiveField(2)
  reject,

  @HiveField(3)
  proposeAlternative,

  @HiveField(4)
  counterPropose,

  @HiveField(5)
  acceptAlternative,

  @HiveField(6)
  cancel,

  @HiveField(7)
  expire,

  @HiveField(8)
  proposalSent,

  @HiveField(9)
  proposalAccepted,

  @HiveField(10)
  paymentNotified,

  @HiveField(11)
  completed,

  @HiveField(12)
  withdrawApproval,

  // Phase 2: 수강권 & 결제 (NEW)
  @HiveField(13)
  paymentRequested,

  @HiveField(14)
  paymentConfirmed,

  @HiveField(15)
  subscriptionIssued,

  // Phase 3: 레슨 진행 (NEW)
  @HiveField(16)
  lessonCompleted,

  @HiveField(17)
  lessonCancelled,

  @HiveField(18)
  scheduleChanged,

  @HiveField(19)
  lessonNoteAdded,

  @HiveField(20)
  subscriptionRenewed,

  @HiveField(21)
  subscriptionCompleted,

  // Phase 3: 스케줄 변경 협상 (NEW)
  @HiveField(22)
  scheduleChangeProposed,

  @HiveField(23)
  scheduleChangeAccepted,

  @HiveField(24)
  scheduleChangeRejected,

  @HiveField(25)
  scheduleChangeCountered;

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
    }
  }

  bool get isTerminal => [
        RequestEventType.cancel,
        RequestEventType.expire,
        RequestEventType.subscriptionCompleted,
        RequestEventType.reject,
      ].contains(this);
}

/// A single event in a lesson request's history.
/// Replaces the legacy TimeProposal — tracks all state changes as chat messages.
@HiveType(typeId: 131)
@JsonSerializable()
class RequestEvent {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String requestId;

  @HiveField(2)
  final ProposerRole actorType;

  @HiveField(3)
  final String actorId;

  @HiveField(4)
  final RequestEventType eventType;

  @HiveField(5)
  final List<TimeSlotOption> suggestedSlots;

  @HiveField(6)
  final int? selectedSlotIndex;

  @HiveField(7)
  final String? message;

  @HiveField(8)
  final DateTime createdAt;

  /// Schedule change type (singleLesson / bulkChange) — for schedule change events only.
  @HiveField(9)
  final ScheduleChangeType? scheduleChangeType;

  /// Proposed new day of week (0=Mon) — for bulkChange proposals.
  @HiveField(10)
  final int? proposedDayOfWeek;

  /// Proposed new time "HH:mm" — for bulkChange proposals.
  @HiveField(11)
  final String? proposedTime;

  const RequestEvent({
    required this.id,
    required this.requestId,
    required this.actorType,
    required this.actorId,
    required this.eventType,
    this.suggestedSlots = const [],
    this.selectedSlotIndex,
    this.message,
    required this.createdAt,
    this.scheduleChangeType,
    this.proposedDayOfWeek,
    this.proposedTime,
  });

  factory RequestEvent.fromJson(Map<String, dynamic> json) =>
      _$RequestEventFromJson(json);

  Map<String, dynamic> toJson() => _$RequestEventToJson(this);

  RequestEvent copyWith({
    String? id,
    String? requestId,
    ProposerRole? actorType,
    String? actorId,
    RequestEventType? eventType,
    List<TimeSlotOption>? suggestedSlots,
    int? selectedSlotIndex,
    String? message,
    DateTime? createdAt,
    ScheduleChangeType? scheduleChangeType,
    int? proposedDayOfWeek,
    String? proposedTime,
  }) {
    return RequestEvent(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      actorType: actorType ?? this.actorType,
      actorId: actorId ?? this.actorId,
      eventType: eventType ?? this.eventType,
      suggestedSlots: suggestedSlots ?? this.suggestedSlots,
      selectedSlotIndex: selectedSlotIndex ?? this.selectedSlotIndex,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      scheduleChangeType: scheduleChangeType ?? this.scheduleChangeType,
      proposedDayOfWeek: proposedDayOfWeek ?? this.proposedDayOfWeek,
      proposedTime: proposedTime ?? this.proposedTime,
    );
  }

  /// Display message for chat bubble header.
  String get chatDisplayMessage {
    switch (eventType) {
      // Phase 1: 레슨 신청
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
      // Phase 2: 수강권 & 결제
      case RequestEventType.paymentRequested:
        return AppStrings.chatPaymentRequested;
      case RequestEventType.paymentConfirmed:
        return AppStrings.chatPaymentConfirmed;
      case RequestEventType.subscriptionIssued:
        return AppStrings.chatSubscriptionIssued;
      // Phase 3: 레슨 진행
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
    }
  }

  @override
  String toString() =>
      'RequestEvent(id: $id, type: $eventType, actor: $actorType/$actorId)';
}
