import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/local_app_release_repository.dart';
import '../../data/repositories/remote_app_release_repository.dart';
import '../../data/repositories/local_app_review_client.dart';
import '../../domain/entities/app_release.dart';
import '../../domain/repositories/app_release_repository.dart';

part 'app_release_provider.g.dart';

@Riverpod(keepAlive: true)
AppReleaseRepository appReleaseRepository(AppReleaseRepositoryRef ref) {
  return createRepository<AppReleaseRepository>(
    ref: ref,
    mock: () => const LocalAppReleaseRepository(),
    remote: (apiClient) => RemoteAppReleaseRepository(apiClient),
  );
}

@Riverpod(keepAlive: true)
Future<AppReleaseSnapshot> appReleaseSnapshot(AppReleaseSnapshotRef ref) async {
  return ref.watch(appReleaseRepositoryProvider).fetchReleaseSnapshot();
}

@Riverpod(keepAlive: true)
Future<AppVersionSnapshot> appVersionSnapshot(AppVersionSnapshotRef ref) async {
  return (await ref.watch(appReleaseSnapshotProvider.future)).version;
}

@Riverpod(keepAlive: true)
Future<List<AppNewsItem>> appNewsFeed(AppNewsFeedRef ref) async {
  return (await ref.watch(appReleaseSnapshotProvider.future)).news;
}

@Riverpod(keepAlive: true)
Future<List<AppRoadmapItem>> appRoadmapFeed(AppRoadmapFeedRef ref) async {
  return (await ref.watch(appReleaseSnapshotProvider.future)).roadmap;
}

@Riverpod(keepAlive: true)
AppReviewClient appReviewClient(AppReviewClientRef ref) {
  return LocalAppReviewClient();
}

@Riverpod(keepAlive: true)
ReviewPromptPolicy reviewPromptPolicy(ReviewPromptPolicyRef ref) {
  return const ReviewPromptPolicy();
}

@Riverpod(keepAlive: true)
bool shouldPromptForReview(
  ShouldPromptForReviewRef ref,
  int completedLessonCount,
) {
  final policy = ref.watch(reviewPromptPolicyProvider);
  return policy.isEligible(completedLessonCount: completedLessonCount);
}
