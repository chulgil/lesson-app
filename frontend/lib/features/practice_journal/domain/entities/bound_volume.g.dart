// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bound_volume.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BoundVolume _$BoundVolumeFromJson(Map<String, dynamic> json) => BoundVolume(
      childProfileId: json['child_profile_id'] as String,
      pieceId: json['piece_id'] as String,
      pieceName: json['piece_name'] as String,
      volumeNo: (json['volume_no'] as num).toInt(),
      boundDate: DateTime.parse(json['bound_date'] as String),
    );

Map<String, dynamic> _$BoundVolumeToJson(BoundVolume instance) =>
    <String, dynamic>{
      'child_profile_id': instance.childProfileId,
      'piece_id': instance.pieceId,
      'piece_name': instance.pieceName,
      'volume_no': instance.volumeNo,
      'bound_date': instance.boundDate.toIso8601String(),
    };
