import 'package:json_annotation/json_annotation.dart';

import 'unified_lesson_request.dart';

part 'request_event.g.dart';

/// 스케줄 변경 유형 (1회성 vs 일괄).
///
/// 원래 LessonScheduleChange 엔티티에 있었으나 RequestEvent SSOT 정렬을 위해
/// 이쪽으로 이동 (Phase 2, 2026-04-28). LessonScheduleChange 엔티티 자체는
/// 미사용 dead code 로 제거됨.
enum ScheduleChangeType {
  singleLesson, // 1회성 변경 (이번 주만)

  bulkChange, // 일괄 변경 (앞으로 모든 레슨)
}

/// Type of event in a lesson request lifecycle (chat history).
enum RequestEventType {
  initialRequest,

  approve,

  reject,

  proposeAlternative,

  counterPropose,

  acceptAlternative,

  cancel,

  expire,

  proposalSent,

  proposalAccepted,

  paymentNotified,

  completed,

  withdrawApproval,

  // Phase 2: 수강권 & 입금 (NEW)
  paymentRequested,

  paymentConfirmed,

  subscriptionIssued,

  // Phase 3: 레슨 진행 (NEW)
  lessonCompleted,

  lessonCancelled,

  scheduleChanged,

  lessonNoteAdded,

  subscriptionRenewed,

  subscriptionCompleted,

  // Phase 3: 스케줄 변경 협상 (NEW)
  scheduleChangeProposed,

  scheduleChangeAccepted,

  scheduleChangeRejected,

  scheduleChangeCountered,

  /// 72h 무응답 자동 만료 — #692
  scheduleChangeExpired,

  /// 24h 무응답 리마인드 알림 — #692 (시스템 이벤트, UI 표시 없음)
  scheduleChangeReminder,

  /// General text message (subscription detail chat)
  message,

  // Phase 3: 레슨 취소 확정 + 크레딧 반환
  lessonCancellationConfirmed,

  cancellationCreditRefunded,

  // Phase 3: 선생님 일괄 작업 (bulk_teacher_actions_spec.md)
  /// 선생님 사유 레슨 휴강 (일괄 또는 개별).
  /// sessionNumber + message(사유) + changeCreditUsed(0) 포함.
  lessonCancelledByTeacher,

  /// 선생님 공지 메시지.
  /// message(제목\n본문) 포함.
  teacherAnnouncement;

  bool get isTerminal => [
    RequestEventType.cancel,
    RequestEventType.expire,
    RequestEventType.subscriptionCompleted,
    RequestEventType.reject,
  ].contains(this);
}

/// A single event in a lesson request's history.
/// Replaces the legacy TimeProposal — tracks all state changes as chat messages.
@JsonSerializable()
class RequestEvent {
  final String id;

  final String requestId;

  final ProposerRole actorType;

  final String actorId;

  final RequestEventType eventType;

  final List<TimeSlotOption> suggestedSlots;

  final int? selectedSlotIndex;

  final String? message;

  final DateTime createdAt;

  /// Schedule change type (singleLesson / bulkChange) — for schedule change events only.
  final ScheduleChangeType? scheduleChangeType;

  /// Proposed new day of week (0=Mon) — for bulkChange proposals.
  final int? proposedDayOfWeek;

  /// Proposed new time "HH:mm" — for bulkChange proposals.
  final String? proposedTime;

  /// Links this event to a subscription.
  final String? subscriptionId;

  /// Which session of the subscription (1-based).
  final int? sessionNumber;

  /// Snapshot of reschedule/cancellation credits used by this event.
  @JsonKey(name: 'changeCreditUsed')
  final int? changeCreditUsed;

  /// Remaining credits after this event, preserved for historical rendering.
  @JsonKey(name: 'changeCreditRemainingAfter')
  final int? changeCreditRemainingAfter;

  /// Whether this event keeps the same session number after cancellation/change.
  @JsonKey(name: 'keepsSessionNumber')
  final bool? keepsSessionNumber;

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
    this.subscriptionId,
    this.sessionNumber,
    this.changeCreditUsed,
    this.changeCreditRemainingAfter,
    this.keepsSessionNumber,
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
    String? subscriptionId,
    int? sessionNumber,
    int? changeCreditUsed,
    int? changeCreditRemainingAfter,
    bool? keepsSessionNumber,
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
      subscriptionId: subscriptionId ?? this.subscriptionId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      changeCreditUsed: changeCreditUsed ?? this.changeCreditUsed,
      changeCreditRemainingAfter:
          changeCreditRemainingAfter ?? this.changeCreditRemainingAfter,
      keepsSessionNumber: keepsSessionNumber ?? this.keepsSessionNumber,
    );
  }

  @override
  String toString() =>
      'RequestEvent(id: $id, type: $eventType, actor: $actorType/$actorId)';
}
