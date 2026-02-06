import '../entities/follow.dart';
import '../entities/follow_target_type.dart';

/// Repository interface for follows (news subscription).
///
/// Manages follow relationships for news/events (not lessons).
/// See: docs/specs/invite/subscription_based_relationship.md
abstract class FollowRepository {
  // ============================================================
  // Query Methods
  // ============================================================

  /// Get follow by ID
  Future<Follow?> getById(String id);

  /// Get follow by follower and following
  Future<Follow?> getFollow(String followerId, String followingId);

  /// Check if user is following a target
  Future<bool> isFollowing(String followerId, String followingId);

  /// Get all follows by a user
  Future<List<Follow>> getByFollower(String followerId);

  /// Get all follows of a target (followers)
  Future<List<Follow>> getFollowers(String followingId);

  /// Get follows by follower and target type
  Future<List<Follow>> getByFollowerAndType(
    String followerId,
    FollowTargetType targetType,
  );

  /// Get follower count for a target
  Future<int> getFollowerCount(String followingId);

  /// Get following count for a user
  Future<int> getFollowingCount(String followerId);

  // ============================================================
  // Command Methods
  // ============================================================

  /// Follow a teacher or academy
  Future<Follow> follow({
    required String followerId,
    required String followingId,
    required FollowTargetType targetType,
    bool notificationEnabled = true,
  });

  /// Unfollow a teacher or academy
  Future<void> unfollow(String followerId, String followingId);

  /// Update follow notification setting
  Future<Follow> updateNotification(String id, bool enabled);

  /// Delete follow by ID
  Future<void> delete(String id);
}
