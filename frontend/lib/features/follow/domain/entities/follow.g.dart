// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Follow _$FollowFromJson(Map<String, dynamic> json) => Follow(
      id: json['id'] as String,
      followerId: json['follower_id'] as String,
      followingId: json['following_id'] as String,
      followingName: json['following_name'] as String?,
      targetType: $enumDecode(_$FollowTargetTypeEnumMap, json['target_type']),
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FollowToJson(Follow instance) => <String, dynamic>{
      'id': instance.id,
      'follower_id': instance.followerId,
      'following_id': instance.followingId,
      'following_name': instance.followingName,
      'target_type': _$FollowTargetTypeEnumMap[instance.targetType]!,
      'notification_enabled': instance.notificationEnabled,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$FollowTargetTypeEnumMap = {
  FollowTargetType.teacher: 'teacher',
  FollowTargetType.academy: 'academy',
};
