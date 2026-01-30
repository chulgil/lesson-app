import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'follow_target_type.dart';

part 'follow.g.dart';

/// Follow for news subscription (performances, events, announcements).
///
/// Separate from lesson relationship:
/// - Anyone can follow teachers/academies
/// - No approval required (Instagram-style one-way)
/// - Used for news/events only, not for lessons
///
/// See: docs/specs/invite/subscription_based_relationship.md
@HiveType(typeId: 93)
@JsonSerializable()
class Follow extends HiveObject {
  @HiveField(0)
  final String id;

  /// Follower user ID (student, parent, or anyone)
  @HiveField(1)
  final String followerId;

  /// Following target ID (teacher or academy)
  @HiveField(2)
  final String followingId;

  /// Target type (teacher or academy)
  @HiveField(3)
  final FollowTargetType targetType;

  /// Notification enabled (default ON)
  @HiveField(4)
  final bool notificationEnabled;

  @HiveField(5)
  final DateTime createdAt;

  Follow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.targetType,
    this.notificationEnabled = true,
    required this.createdAt,
  });

  /// Create a new follow
  factory Follow.create({
    required String followerId,
    required String followingId,
    required FollowTargetType targetType,
    bool notificationEnabled = true,
  }) {
    return Follow(
      id: 'follow_${DateTime.now().millisecondsSinceEpoch}',
      followerId: followerId,
      followingId: followingId,
      targetType: targetType,
      notificationEnabled: notificationEnabled,
      createdAt: DateTime.now(),
    );
  }

  Follow copyWith({
    String? id,
    String? followerId,
    String? followingId,
    FollowTargetType? targetType,
    bool? notificationEnabled,
    DateTime? createdAt,
  }) {
    return Follow(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      targetType: targetType ?? this.targetType,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Follow.fromJson(Map<String, dynamic> json) => _$FollowFromJson(json);

  Map<String, dynamic> toJson() => _$FollowToJson(this);

  @override
  String toString() {
    return 'Follow(id: $id, followerId: $followerId, '
        'followingId: $followingId, targetType: $targetType)';
  }
}
