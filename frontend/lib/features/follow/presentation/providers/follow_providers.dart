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
