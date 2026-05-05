/// Follow target type for news subscription.
///
/// Follow is separate from lesson relationship - used for news/events only.
/// See: docs/specs/invite/subscription_based_relationship.md
enum FollowTargetType {
  /// Teacher - individual teacher news
  teacher,

  /// Academy - academy news/events
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
