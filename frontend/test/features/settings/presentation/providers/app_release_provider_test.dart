import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/features/settings/domain/entities/app_release.dart';
import 'package:lessonaza/features/settings/domain/repositories/app_release_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/app_release_provider.dart';

class FakeAppReleaseRepository implements AppReleaseRepository {
  final AppReleaseSnapshot snapshot;

  const FakeAppReleaseRepository(this.snapshot);

  @override
  Future<AppReleaseSnapshot> fetchReleaseSnapshot() async => snapshot;
}

void main() {
  test(
    'app release providers expose snapshot data through overrides',
    () async {
      final snapshot = AppReleaseSnapshot(
        version: AppVersionSnapshot(
          currentVersion: '2.0.0',
          buildNumber: '7',
          latestVersion: '2.1.0',
          checkedAt: DateTime.utc(2026, 5, 7),
        ),
        news: [
          AppNewsItem(
            id: 'news-1',
            title: 'release',
            summary: 'summary',
            publishedAt: DateTime.utc(2026, 5, 7),
          ),
        ],
        roadmap: [
          AppRoadmapItem(
            id: 'roadmap-1',
            title: 'roadmap',
            summary: 'summary',
            status: AppRoadmapStatus.planned,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          appReleaseRepositoryProvider.overrideWithValue(
            FakeAppReleaseRepository(snapshot),
          ),
        ],
      );
      addTearDown(container.dispose);

      final version = await container.read(appVersionSnapshotProvider.future);
      final news = await container.read(appNewsFeedProvider.future);
      final roadmap = await container.read(appRoadmapFeedProvider.future);

      expect(version.displayVersion, '2.0.0 (7)');
      expect(version.hasUpdate, isTrue);
      expect(news, hasLength(1));
      expect(roadmap, hasLength(1));
    },
  );

  test('review prompt provider uses the lesson threshold policy', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(shouldPromptForReviewProvider(9)), isFalse);
    expect(container.read(shouldPromptForReviewProvider(10)), isTrue);
  });
}
