import 'package:hive/hive.dart';

part 'follow_target_type.g.dart';

/// Follow target type for news subscription.
///
/// Follow is separate from lesson relationship - used for news/events only.
/// See: docs/specs/invite/subscription_based_relationship.md
@HiveType(typeId: 94)
enum FollowTargetType {
  /// Teacher - individual teacher news
  @HiveField(0)
  teacher,

  /// Academy - academy news/events
  @HiveField(1)
  academy,
}

/// Extension methods for FollowTargetType
extension FollowTargetTypeExtension on FollowTargetType {
  /// Display name in Korean
  String get displayName {
    switch (this) {
      case FollowTargetType.teacher:
        return '선생님';
      case FollowTargetType.academy:
        return '학원';
    }
  }
}
