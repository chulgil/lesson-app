import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_follow_repository.dart';
import '../../data/repositories/remote_follow_repository.dart';
import '../../domain/entities/follow.dart';
import '../../domain/entities/follow_target_type.dart';
import '../../domain/repositories/follow_repository.dart';

part 'follow_providers.g.dart';

/// Repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
FollowRepository followRepository(FollowRepositoryRef ref) =>
    createRepository<FollowRepository>(
      ref: ref,
      mock: () => MockFollowRepository(),
      remote: (api) => RemoteFollowRepository(api),
    );

/// Get follow by ID
@riverpod
Future<Follow?> followById(FollowByIdRef ref, String id) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getById(id);
}

/// Check if user is following a target
@riverpod
Future<bool> isFollowing(
  IsFollowingRef ref, {
  required String followerId,
  required String followingId,
}) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.isFollowing(followerId, followingId);
}

/// Get all follows by a user
@riverpod
Future<List<Follow>> userFollowing(
  UserFollowingRef ref,
  String followerId,
) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getByFollower(followerId);
}

/// Get all followers of a target
@riverpod
Future<List<Follow>> targetFollowers(
  TargetFollowersRef ref,
  String followingId,
) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getFollowers(followingId);
}

/// Get follows by follower and target type
@riverpod
Future<List<Follow>> userFollowingByType(
  UserFollowingByTypeRef ref, {
  required String followerId,
  required FollowTargetType targetType,
}) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getByFollowerAndType(followerId, targetType);
}

/// Get follower count for a target
@riverpod
Future<int> followerCount(FollowerCountRef ref, String followingId) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getFollowerCount(followingId);
}

/// Get following count for a user
@riverpod
Future<int> followingCount(FollowingCountRef ref, String followerId) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getFollowingCount(followerId);
}

/// Get teachers followed by a user
@riverpod
Future<List<Follow>> followedTeachers(
  FollowedTeachersRef ref,
  String followerId,
) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getByFollowerAndType(followerId, FollowTargetType.teacher);
}

/// Get academies followed by a user
@riverpod
Future<List<Follow>> followedAcademies(
  FollowedAcademiesRef ref,
  String followerId,
) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getByFollowerAndType(followerId, FollowTargetType.academy);
}

/// Follow/unfollow actions per spec §4 Provider 설계.
///
/// Stateless notifier — actions invalidate the related read-side providers
/// (`isFollowingProvider`, `followerCountProvider`, `followedTeachersProvider`,
/// `followedAcademiesProvider`).
@riverpod
class FollowNotifier extends _$FollowNotifier {
  @override
  FutureOr<void> build() {}

  /// Follow [followingId] (defaults to teacher target).
  Future<void> follow({
    required String followerId,
    required String followingId,
    FollowTargetType targetType = FollowTargetType.teacher,
  }) async {
    final repository = ref.read(followRepositoryProvider);
    await repository.follow(
      followerId: followerId,
      followingId: followingId,
      targetType: targetType,
    );
    _invalidateRelated(followerId, followingId, targetType);
  }

  /// Unfollow [followingId].
  Future<void> unfollow({
    required String followerId,
    required String followingId,
    FollowTargetType targetType = FollowTargetType.teacher,
  }) async {
    final repository = ref.read(followRepositoryProvider);
    await repository.unfollow(followerId, followingId);
    _invalidateRelated(followerId, followingId, targetType);
  }

  void _invalidateRelated(
    String followerId,
    String followingId,
    FollowTargetType targetType,
  ) {
    ref.invalidate(
      isFollowingProvider(followerId: followerId, followingId: followingId),
    );
    ref.invalidate(followerCountProvider(followingId));
    ref.invalidate(followingCountProvider(followerId));
    if (targetType == FollowTargetType.teacher) {
      ref.invalidate(followedTeachersProvider(followerId));
    } else if (targetType == FollowTargetType.academy) {
      ref.invalidate(followedAcademiesProvider(followerId));
    }
    ref.invalidate(userFollowingProvider(followerId));
    ref.invalidate(
      userFollowingByTypeProvider(
        followerId: followerId,
        targetType: targetType,
      ),
    );
  }
}
