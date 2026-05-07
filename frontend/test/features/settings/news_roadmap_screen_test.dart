import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/settings/domain/entities/app_release.dart';
import 'package:lessonaza/features/settings/domain/repositories/app_release_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/app_release_provider.dart';
import 'package:lessonaza/features/settings/presentation/screens/news_roadmap_screen.dart';

class FakeAppReleaseRepository implements AppReleaseRepository {
  const FakeAppReleaseRepository(this.snapshot);

  final AppReleaseSnapshot snapshot;

  @override
  Future<AppReleaseSnapshot> fetchReleaseSnapshot() async => snapshot;
}

void main() {
  testWidgets('renders release notes and roadmap items', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appReleaseRepositoryProvider.overrideWithValue(
            FakeAppReleaseRepository(
              AppReleaseSnapshot(
                version: AppVersionSnapshot(
                  currentVersion: '1.0.0',
                  buildNumber: '1',
                  latestVersion: '1.1.0',
                  checkedAt: DateTime.utc(2026, 5, 7),
                ),
                news: [
                  AppNewsItem(
                    id: 'news-1',
                    title: '레슨 운영 흐름 안정화',
                    summary: '스케줄 변경 상태 표시 개선',
                    publishedAt: DateTime.utc(2026, 5, 7),
                  ),
                ],
                roadmap: [
                  AppRoadmapItem(
                    id: 'roadmap-1',
                    title: '리뷰 요청 타이밍',
                    summary: '레슨 경험이 쌓인 뒤 리뷰를 요청합니다.',
                    status: AppRoadmapStatus.planned,
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: NewsRoadmapScreen()),
      ),
    );

    await tester.pump();

    expect(find.text(AppStrings.newsRoadmapTitle), findsWidgets);
    expect(find.text('레슨 운영 흐름 안정화'), findsOneWidget);
    expect(find.text('스케줄 변경 상태 표시 개선'), findsOneWidget);
    expect(find.text(AppStrings.newsRoadmapSectionTitle), findsOneWidget);
    expect(find.text('리뷰 요청 타이밍'), findsOneWidget);
    expect(find.text(AppStrings.newsRoadmapStatusPlanned), findsOneWidget);
  });
}
