// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_access_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteAccessRequest _$NoteAccessRequestFromJson(Map<String, dynamic> json) =>
    NoteAccessRequest(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      academyName: json['academy_name'] as String,
      reason: json['reason'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      status: $enumDecode(_$NoteAccessStatusEnumMap, json['status']),
      recipientUserId: json['recipient_user_id'] as String,
      requestorUserId: json['requestor_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$NoteAccessRequestToJson(NoteAccessRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'academy_id': instance.academyId,
      'academy_name': instance.academyName,
      'reason': instance.reason,
      'expires_at': instance.expiresAt.toIso8601String(),
      'status': _$NoteAccessStatusEnumMap[instance.status]!,
      'recipient_user_id': instance.recipientUserId,
      'requestor_user_id': instance.requestorUserId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$NoteAccessStatusEnumMap = {
  NoteAccessStatus.requested: 'requested',
  NoteAccessStatus.consented: 'consented',
  NoteAccessStatus.rejected: 'rejected',
  NoteAccessStatus.revoked: 'revoked',
};
