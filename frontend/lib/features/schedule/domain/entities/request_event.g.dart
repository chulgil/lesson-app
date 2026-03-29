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
    );
  }

  @override
  void write(BinaryWriter writer, RequestEvent obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.createdAt);
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
      suggestedSlots: (json['suggested_slots'] as List<dynamic>?)
              ?.map((e) => TimeSlotOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedSlotIndex: (json['selected_slot_index'] as num?)?.toInt(),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
};
