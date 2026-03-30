import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_post_repository.dart';
import '../../data/repositories/remote_post_repository.dart';
import '../../domain/entities/teacher_post.dart';
import '../../domain/repositories/post_repository.dart';
import 'follow_providers.dart';

part 'post_providers.g.dart';

/// Repository provider for posts — switches between Mock and Remote.
@Riverpod(keepAlive: true)
PostRepository postRepository(PostRepositoryRef ref) =>
    createRepository<PostRepository>(
      ref: ref,
      mock: () => MockPostRepository(),
      remote: (api) => RemotePostRepository(api),
    );

/// Get feed posts for a user's followed accounts.
///
/// Aggregates posts from all followed teachers/academies, sorted newest first.
@riverpod
Future<List<TeacherPost>> followFeed(
  FollowFeedRef ref,
  String followerId,
) async {
  final followRepo = ref.watch(followRepositoryProvider);
  final postRepo = ref.watch(postRepositoryProvider);

  // Get all followed IDs
  final follows = await followRepo.getByFollower(followerId);
  if (follows.isEmpty) return [];

  final followingIds = follows.map((f) => f.followingId).toList();
  return postRepo.getByAuthors(followingIds);
}
