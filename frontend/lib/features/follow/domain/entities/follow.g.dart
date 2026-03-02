// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FollowAdapter extends TypeAdapter<Follow> {
  @override
  final int typeId = 93;

  @override
  Follow read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Follow(
      id: fields[0] as String,
      followerId: fields[1] as String,
      followingId: fields[2] as String,
      targetType: fields[3] as FollowTargetType,
      notificationEnabled: fields[4] as bool,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Follow obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.followerId)
      ..writeByte(2)
      ..write(obj.followingId)
      ..writeByte(3)
      ..write(obj.targetType)
      ..writeByte(4)
      ..write(obj.notificationEnabled)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Follow _$FollowFromJson(Map<String, dynamic> json) => Follow(
      id: json['id'] as String,
      followerId: json['follower_id'] as String,
      followingId: json['following_id'] as String,
      targetType: $enumDecode(_$FollowTargetTypeEnumMap, json['target_type']),
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FollowToJson(Follow instance) => <String, dynamic>{
      'id': instance.id,
      'follower_id': instance.followerId,
      'following_id': instance.followingId,
      'target_type': _$FollowTargetTypeEnumMap[instance.targetType]!,
      'notification_enabled': instance.notificationEnabled,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$FollowTargetTypeEnumMap = {
  FollowTargetType.teacher: 'teacher',
  FollowTargetType.academy: 'academy',
};
