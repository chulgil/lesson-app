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
