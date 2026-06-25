// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestEvent _$RequestEventFromJson(Map<String, dynamic> json) => RequestEvent(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      actorType: $enumDecode(_$ProposerRoleEnumMap, json['actor_type']),
      actorId: json['actor_id'] as String,
      eventType: $enumDecode(_$RequestEventTypeEnumMap, json['event_type']),
      suggestedSlots: (json['suggested_slots'] as List<dynamic>?)
              ?.map((e) => TimeSlotOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedSlotIndex: (json['selected_slot_index'] as num?)?.toInt(),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      scheduleChangeType: $enumDecodeNullable(
          _$ScheduleChangeTypeEnumMap, json['schedule_change_type']),
      proposedDayOfWeek: (json['proposed_day_of_week'] as num?)?.toInt(),
      proposedTime: json['proposed_time'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      sessionNumber: (json['session_number'] as num?)?.toInt(),
      changeCreditUsed: (json['changeCreditUsed'] as num?)?.toInt(),
      changeCreditRemainingAfter:
          (json['changeCreditRemainingAfter'] as num?)?.toInt(),
      keepsSessionNumber: json['keepsSessionNumber'] as bool?,
    );

Map<String, dynamic> _$RequestEventToJson(RequestEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'request_id': instance.requestId,
      'actor_type': _$ProposerRoleEnumMap[instance.actorType]!,
      'actor_id': instance.actorId,
      'event_type': _$RequestEventTypeEnumMap[instance.eventType]!,
      'suggested_slots':
          instance.suggestedSlots.map((e) => e.toJson()).toList(),
      'selected_slot_index': instance.selectedSlotIndex,
      'message': instance.message,
      'created_at': instance.createdAt.toIso8601String(),
      'schedule_change_type':
          _$ScheduleChangeTypeEnumMap[instance.scheduleChangeType],
      'proposed_day_of_week': instance.proposedDayOfWeek,
      'proposed_time': instance.proposedTime,
      'subscription_id': instance.subscriptionId,
      'session_number': instance.sessionNumber,
      'changeCreditUsed': instance.changeCreditUsed,
      'changeCreditRemainingAfter': instance.changeCreditRemainingAfter,
      'keepsSessionNumber': instance.keepsSessionNumber,
    };

const _$ProposerRoleEnumMap = {
  ProposerRole.student: 'student',
  ProposerRole.teacher: 'teacher',
  ProposerRole.system: 'system',
};

const _$RequestEventTypeEnumMap = {
  RequestEventType.initialRequest: 'initialRequest',
  RequestEventType.approve: 'approve',
  RequestEventType.reject: 'reject',
  RequestEventType.proposeAlternative: 'proposeAlternative',
  RequestEventType.counterPropose: 'counterPropose',
  RequestEventType.acceptAlternative: 'acceptAlternative',
  RequestEventType.cancel: 'cancel',
  RequestEventType.expire: 'expire',
  RequestEventType.proposalSent: 'proposalSent',
  RequestEventType.proposalAccepted: 'proposalAccepted',
  RequestEventType.paymentNotified: 'paymentNotified',
  RequestEventType.completed: 'completed',
  RequestEventType.withdrawApproval: 'withdrawApproval',
  RequestEventType.paymentRequested: 'paymentRequested',
  RequestEventType.paymentConfirmed: 'paymentConfirmed',
  RequestEventType.subscriptionIssued: 'subscriptionIssued',
  RequestEventType.lessonCompleted: 'lessonCompleted',
  RequestEventType.lessonCancelled: 'lessonCancelled',
  RequestEventType.scheduleChanged: 'scheduleChanged',
  RequestEventType.lessonNoteAdded: 'lessonNoteAdded',
  RequestEventType.subscriptionRenewed: 'subscriptionRenewed',
  RequestEventType.subscriptionCompleted: 'subscriptionCompleted',
  RequestEventType.scheduleChangeProposed: 'scheduleChangeProposed',
  RequestEventType.scheduleChangeAccepted: 'scheduleChangeAccepted',
  RequestEventType.scheduleChangeRejected: 'scheduleChangeRejected',
  RequestEventType.scheduleChangeCountered: 'scheduleChangeCountered',
  RequestEventType.scheduleChangeExpired: 'scheduleChangeExpired',
  RequestEventType.scheduleChangeReminder: 'scheduleChangeReminder',
  RequestEventType.message: 'message',
  RequestEventType.lessonCancellationConfirmed: 'lessonCancellationConfirmed',
  RequestEventType.cancellationCreditRefunded: 'cancellationCreditRefunded',
  RequestEventType.lessonCancelledByTeacher: 'lessonCancelledByTeacher',
  RequestEventType.teacherAnnouncement: 'teacherAnnouncement',
};

const _$ScheduleChangeTypeEnumMap = {
  ScheduleChangeType.singleLesson: 'singleLesson',
  ScheduleChangeType.bulkChange: 'bulkChange',
};
