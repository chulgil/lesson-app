import '../../../../core/network/api_client.dart';
import '../../domain/entities/follow.dart';
import '../../domain/entities/follow_target_type.dart';
import '../../domain/repositories/follow_repository.dart';

/// Remote implementation of [FollowRepository] using FastAPI backend.
///
/// Backend routes: POST `/follows`, DELETE `/follows/{id}`.
/// Follow list is fetched via `/relationships` and filtered client-side.
class RemoteFollowRepository implements FollowRepository {
  final ApiClient _apiClient;

  RemoteFollowRepository(this._apiClient);

  // ============================================================
  // Query Methods
  // ============================================================

  @override
  Future<Follow?> getById(String id) async {
    final all = await _fetchAllFollows();
    try {
      return all.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Follow?> getFollow(String followerId, String followingId) async {
    final all = await _fetchAllFollows();
    try {
      return all.firstWhere(
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
    final all = await _fetchAllFollows();
    return all.where((f) => f.followerId == followerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Follow>> getFollowers(String followingId) async {
    final all = await _fetchAllFollows();
    return all.where((f) => f.followingId == followingId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Follow>> getByFollowerAndType(
    String followerId,
    FollowTargetType targetType,
  ) async {
    final all = await getByFollower(followerId);
    return all.where((f) => f.targetType == targetType).toList();
  }

  @override
  Future<int> getFollowerCount(String followingId) async {
    final followers = await getFollowers(followingId);
    return followers.length;
  }

  @override
  Future<int> getFollowingCount(String followerId) async {
    final following = await getByFollower(followerId);
    return following.length;
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
    final response = await _apiClient.post(
      '/follows',
      data: {'following_id': followingId, 'target_type': targetType.name},
    );
    return _followFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> unfollow(String followerId, String followingId) async {
    final follow = await getFollow(followerId, followingId);
    if (follow != null) {
      await _apiClient.delete('/follows/${follow.id}');
    }
  }

  @override
  Future<Follow> updateNotification(String id, bool enabled) async {
    final response = await _apiClient.patch(
      '/follows/$id',
      data: {'notification_enabled': enabled},
    );
    return _followFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/follows/$id');
  }

  // --- Private helpers ---

  Future<List<Follow>> _fetchAllFollows() async {
    final response = await _apiClient.get('/follows');
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('items')) {
      final items = data['items'] as List<dynamic>;
      return items
          .map((e) => _followFromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List<dynamic>) {
      return data
          .map((e) => _followFromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Follow _followFromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['id'] as String,
      followerId: json['follower_id'] as String,
      followingId: json['following_id'] as String,
      targetType: _parseTargetType(json['target_type'] as String?),
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  FollowTargetType _parseTargetType(String? value) {
    if (value == null) return FollowTargetType.teacher;
    try {
      return FollowTargetType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return FollowTargetType.teacher;
    }
  }
}
