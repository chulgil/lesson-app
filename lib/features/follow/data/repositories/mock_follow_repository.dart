import '../../domain/entities/follow.dart';
import '../../domain/entities/follow_target_type.dart';
import '../../domain/repositories/follow_repository.dart';

/// Mock implementation of FollowRepository.
class MockFollowRepository implements FollowRepository {
  final Map<String, Follow> _follows = {};

  MockFollowRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    final follows = [
      // Student following teachers
      Follow(
        id: 'follow_1',
        followerId: 'student_1',
        followingId: 'teacher_1',
        targetType: FollowTargetType.teacher,
        notificationEnabled: true,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Follow(
        id: 'follow_2',
        followerId: 'student_1',
        followingId: 'teacher_2',
        targetType: FollowTargetType.teacher,
        notificationEnabled: true,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Follow(
        id: 'follow_3',
        followerId: 'student_2',
        followingId: 'teacher_1',
        targetType: FollowTargetType.teacher,
        notificationEnabled: true,
        createdAt: now.subtract(const Duration(days: 45)),
      ),

      // Student following academy
      Follow(
        id: 'follow_4',
        followerId: 'student_1',
        followingId: 'academy_1',
        targetType: FollowTargetType.academy,
        notificationEnabled: true,
        createdAt: now.subtract(const Duration(days: 20)),
      ),

      // Parent following teacher (through child)
      Follow(
        id: 'follow_5',
        followerId: 'parent_1',
        followingId: 'teacher_1',
        targetType: FollowTargetType.teacher,
        notificationEnabled: true,
        createdAt: now.subtract(const Duration(days: 25)),
      ),

      // User with notification disabled
      Follow(
        id: 'follow_6',
        followerId: 'student_3',
        followingId: 'teacher_1',
        targetType: FollowTargetType.teacher,
        notificationEnabled: false,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    for (final follow in follows) {
      _follows[follow.id] = follow;
    }
  }

  // ============================================================
  // Query Methods
  // ============================================================

  @override
  Future<Follow?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _follows[id];
  }

  @override
  Future<Follow?> getFollow(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _follows.values.firstWhere(
        (f) => f.followerId == followerId && f.followingId == followingId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isFollowing(String followerId, String followingId) async {
    final follow = await getFollow(followerId, followingId);
    return follow != null;
  }

  @override
  Future<List<Follow>> getByFollower(String followerId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _follows.values
        .where((f) => f.followerId == followerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Follow>> getFollowers(String followingId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _follows.values
        .where((f) => f.followingId == followingId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Follow>> getByFollowerAndType(
    String followerId,
    FollowTargetType targetType,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _follows.values
        .where((f) => f.followerId == followerId && f.targetType == targetType)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> getFollowerCount(String followingId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _follows.values.where((f) => f.followingId == followingId).length;
  }

  @override
  Future<int> getFollowingCount(String followerId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _follows.values.where((f) => f.followerId == followerId).length;
  }

  // ============================================================
  // Command Methods
  // ============================================================

  @override
  Future<Follow> follow({
    required String followerId,
    required String followingId,
    required FollowTargetType targetType,
    bool notificationEnabled = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if already following
    final existing = await getFollow(followerId, followingId);
    if (existing != null) {
      return existing;
    }

    final follow = Follow.create(
      followerId: followerId,
      followingId: followingId,
      targetType: targetType,
      notificationEnabled: notificationEnabled,
    );

    _follows[follow.id] = follow;
    return follow;
  }

  @override
  Future<void> unfollow(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final follow = await getFollow(followerId, followingId);
    if (follow != null) {
      _follows.remove(follow.id);
    }
  }

  @override
  Future<Follow> updateNotification(String id, bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final follow = _follows[id];
    if (follow == null) {
      throw Exception('Follow not found: $id');
    }

    final updated = follow.copyWith(notificationEnabled: enabled);
    _follows[id] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _follows.remove(id);
  }
}
