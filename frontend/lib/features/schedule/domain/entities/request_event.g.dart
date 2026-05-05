// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RequestEventAdapter extends TypeAdapter<RequestEvent> {
  @override
  final int typeId = 131;

  @override
  RequestEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RequestEvent(
      id: fields[0] as String,
      requestId: fields[1] as String,
      actorType: fields[2] as ProposerRole,
      actorId: fields[3] as String,
      eventType: fields[4] as RequestEventType,
      suggestedSlots: (fields[5] as List).cast<TimeSlotOption>(),
      selectedSlotIndex: fields[6] as int?,
      message: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      scheduleChangeType: fields[9] as ScheduleChangeType?,
      proposedDayOfWeek: fields[10] as int?,
      proposedTime: fields[11] as String?,
      subscriptionId: fields[12] as String?,
      sessionNumber: fields[13] as int?,
      changeCreditUsed: fields[14] as int?,
      changeCreditRemainingAfter: fields[15] as int?,
      keepsSessionNumber: fields[16] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, RequestEvent obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.requestId)
      ..writeByte(2)
      ..write(obj.actorType)
      ..writeByte(3)
      ..write(obj.actorId)
      ..writeByte(4)
      ..write(obj.eventType)
      ..writeByte(5)
      ..write(obj.suggestedSlots)
      ..writeByte(6)
      ..write(obj.selectedSlotIndex)
      ..writeByte(7)
      ..write(obj.message)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.scheduleChangeType)
      ..writeByte(10)
      ..write(obj.proposedDayOfWeek)
      ..writeByte(11)
      ..write(obj.proposedTime)
      ..writeByte(12)
      ..write(obj.subscriptionId)
      ..writeByte(13)
      ..write(obj.sessionNumber)
      ..writeByte(14)
      ..write(obj.changeCreditUsed)
      ..writeByte(15)
      ..write(obj.changeCreditRemainingAfter)
      ..writeByte(16)
      ..write(obj.keepsSessionNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleChangeTypeAdapter extends TypeAdapter<ScheduleChangeType> {
  @override
  final int typeId = 132;

  @override
  ScheduleChangeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduleChangeType.singleLesson;
      case 1:
        return ScheduleChangeType.bulkChange;
      default:
        return ScheduleChangeType.singleLesson;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduleChangeType obj) {
    switch (obj) {
      case ScheduleChangeType.singleLesson:
        writer.writeByte(0);
        break;
      case ScheduleChangeType.bulkChange:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleChangeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RequestEventTypeAdapter extends TypeAdapter<RequestEventType> {
  @override
  final int typeId = 130;

  @override
  RequestEventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RequestEventType.initialRequest;
      case 1:
        return RequestEventType.approve;
      case 2:
        return RequestEventType.reject;
      case 3:
        return RequestEventType.proposeAlternative;
      case 4:
        return RequestEventType.counterPropose;
      case 5:
        return RequestEventType.acceptAlternative;
      case 6:
        return RequestEventType.cancel;
      case 7:
        return RequestEventType.expire;
      case 8:
        return RequestEventType.proposalSent;
      case 9:
        return RequestEventType.proposalAccepted;
      case 10:
        return RequestEventType.paymentNotified;
      case 11:
        return RequestEventType.completed;
      case 12:
        return RequestEventType.withdrawApproval;
      case 13:
        return RequestEventType.paymentRequested;
      case 14:
        return RequestEventType.paymentConfirmed;
      case 15:
        return RequestEventType.subscriptionIssued;
      case 16:
        return RequestEventType.lessonCompleted;
      case 17:
        return RequestEventType.lessonCancelled;
      case 18:
        return RequestEventType.scheduleChanged;
      case 19:
        return RequestEventType.lessonNoteAdded;
      case 20:
        return RequestEventType.subscriptionRenewed;
      case 21:
        return RequestEventType.subscriptionCompleted;
      case 22:
        return RequestEventType.scheduleChangeProposed;
      case 23:
        return RequestEventType.scheduleChangeAccepted;
      case 24:
        return RequestEventType.scheduleChangeRejected;
      case 25:
        return RequestEventType.scheduleChangeCountered;
      case 26:
        return RequestEventType.message;
      default:
        return RequestEventType.initialRequest;
    }
  }

  @override
  void write(BinaryWriter writer, RequestEventType obj) {
    switch (obj) {
      case RequestEventType.initialRequest:
        writer.writeByte(0);
        break;
      case RequestEventType.approve:
        writer.writeByte(1);
        break;
      case RequestEventType.reject:
        writer.writeByte(2);
        break;
      case RequestEventType.proposeAlternative:
        writer.writeByte(3);
        break;
      case RequestEventType.counterPropose:
        writer.writeByte(4);
        break;
      case RequestEventType.acceptAlternative:
        writer.writeByte(5);
        break;
      case RequestEventType.cancel:
        writer.writeByte(6);
        break;
      case RequestEventType.expire:
        writer.writeByte(7);
        break;
      case RequestEventType.proposalSent:
        writer.writeByte(8);
        break;
      case RequestEventType.proposalAccepted:
        writer.writeByte(9);
        break;
      case RequestEventType.paymentNotified:
        writer.writeByte(10);
        break;
      case RequestEventType.completed:
        writer.writeByte(11);
        break;
      case RequestEventType.withdrawApproval:
        writer.writeByte(12);
        break;
      case RequestEventType.paymentRequested:
        writer.writeByte(13);
        break;
      case RequestEventType.paymentConfirmed:
        writer.writeByte(14);
        break;
      case RequestEventType.subscriptionIssued:
        writer.writeByte(15);
        break;
      case RequestEventType.lessonCompleted:
        writer.writeByte(16);
        break;
      case RequestEventType.lessonCancelled:
        writer.writeByte(17);
        break;
      case RequestEventType.scheduleChanged:
        writer.writeByte(18);
        break;
      case RequestEventType.lessonNoteAdded:
        writer.writeByte(19);
        break;
      case RequestEventType.subscriptionRenewed:
        writer.writeByte(20);
        break;
      case RequestEventType.subscriptionCompleted:
        writer.writeByte(21);
        break;
      case RequestEventType.scheduleChangeProposed:
        writer.writeByte(22);
        break;
      case RequestEventType.scheduleChangeAccepted:
        writer.writeByte(23);
        break;
      case RequestEventType.scheduleChangeRejected:
        writer.writeByte(24);
        break;
      case RequestEventType.scheduleChangeCountered:
        writer.writeByte(25);
        break;
      case RequestEventType.message:
        writer.writeByte(26);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestEventTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestEvent _$RequestEventFromJson(Map<String, dynamic> json) => RequestEvent(
  id: json['id'] as String,
  requestId: json['request_id'] as String,
  actorType: $enumDecode(_$ProposerRoleEnumMap, json['actor_type']),
  actorId: json['actor_id'] as String,
  eventType: $enumDecode(_$RequestEventTypeEnumMap, json['event_type']),
  suggestedSlots:
      (json['suggested_slots'] as List<dynamic>?)
          ?.map((e) => TimeSlotOption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  selectedSlotIndex: (json['selected_slot_index'] as num?)?.toInt(),
  message: json['message'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  scheduleChangeType: $enumDecodeNullable(
    _$ScheduleChangeTypeEnumMap,
    json['schedule_change_type'],
  ),
  proposedDayOfWeek: (json['proposed_day_of_week'] as num?)?.toInt(),
  proposedTime: json['proposed_time'] as String?,
  subscriptionId: json['subscription_id'] as String?,
  sessionNumber: (json['session_number'] as num?)?.toInt(),
  changeCreditUsed: (json['changeCreditUsed'] as num?)?.toInt(),
  changeCreditRemainingAfter:
      (json['changeCreditRemainingAfter'] as num?)?.toInt(),
  keepsSessionNumber: json['keepsSessionNumber'] as bool?,
);

Map<String, dynamic> _$RequestEventToJson(
  RequestEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'request_id': instance.requestId,
  'actor_type': _$ProposerRoleEnumMap[instance.actorType]!,
  'actor_id': instance.actorId,
  'event_type': _$RequestEventTypeEnumMap[instance.eventType]!,
  'suggested_slots': instance.suggestedSlots.map((e) => e.toJson()).toList(),
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
  RequestEventType.message: 'message',
};

const _$ScheduleChangeTypeEnumMap = {
  ScheduleChangeType.singleLesson: 'singleLesson',
  ScheduleChangeType.bulkChange: 'bulkChange',
};
