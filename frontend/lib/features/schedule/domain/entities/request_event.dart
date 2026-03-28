import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

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
  completed;

  String get label {
    switch (this) {
      case RequestEventType.initialRequest:
        return '레슨 요청';
      case RequestEventType.approve:
        return '수락';
      case RequestEventType.reject:
        return '거절';
      case RequestEventType.proposeAlternative:
        return '다른 시간 제안';
      case RequestEventType.counterPropose:
        return '다른 시간 제안';
      case RequestEventType.acceptAlternative:
        return '시간 수락';
      case RequestEventType.cancel:
        return '취소';
      case RequestEventType.expire:
        return '기간 만료';
      case RequestEventType.proposalSent:
        return '수강권 제안';
      case RequestEventType.proposalAccepted:
        return '수강권 수락';
      case RequestEventType.paymentNotified:
        return '결제 완료';
      case RequestEventType.completed:
        return '발급 완료';
    }
  }

  bool get isTerminal => [
        RequestEventType.cancel,
        RequestEventType.expire,
        RequestEventType.completed,
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
    );
  }

  /// Display message for chat bubble header.
  String get chatDisplayMessage {
    switch (eventType) {
      case RequestEventType.initialRequest:
        return '레슨을 요청했습니다';
      case RequestEventType.approve:
        return '요청을 수락했습니다';
      case RequestEventType.reject:
        return '요청을 거절했습니다';
      case RequestEventType.proposeAlternative:
      case RequestEventType.counterPropose:
        return '다른 시간을 제안했습니다';
      case RequestEventType.acceptAlternative:
        return '제안한 시간을 수락했습니다';
      case RequestEventType.cancel:
        return '요청을 취소했습니다';
      case RequestEventType.expire:
        return '요청이 만료되었습니다';
      case RequestEventType.proposalSent:
        return '수강권을 제안했습니다';
      case RequestEventType.proposalAccepted:
        return '수강권을 수락했습니다';
      case RequestEventType.paymentNotified:
        return '결제가 완료되었습니다';
      case RequestEventType.completed:
        return '수강권이 발급되었습니다';
    }
  }

  @override
  String toString() =>
      'RequestEvent(id: $id, type: $eventType, actor: $actorType/$actorId)';
}
