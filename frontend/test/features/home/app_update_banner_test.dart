import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/home/presentation/widgets/app_update_banner.dart';
import 'package:lessonaza/features/settings/domain/entities/app_release.dart';
import 'package:lessonaza/features/settings/domain/repositories/app_release_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/app_release_provider.dart';

class FakeAppReleaseRepository implements AppReleaseRepository {
  const FakeAppReleaseRepository(this.snapshot);

  final AppReleaseSnapshot snapshot;

  @override
  Future<AppReleaseSnapshot> fetchReleaseSnapshot() async => snapshot;
}

void main() {
  testWidgets('shows update banner and opens news roadmap route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home-test',
      routes: [
        GoRoute(
          path: '/home-test',
          builder: (_, __) => const Scaffold(body: AppUpdateBanner()),
        ),
        GoRoute(
          path: AppRoutes.newsRoadmap,
          builder: (_, __) => const Scaffold(body: Text('news route')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appReleaseRepositoryProvider.overrideWithValue(
            FakeAppReleaseRepository(
              AppReleaseSnapshot(
                version: AppVersionSnapshot(
                  currentVersion: '1.0.0',
                  latestVersion: '1.1.0',
                  checkedAt: DateTime.utc(2026, 5, 7),
                ),
              ),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();

    expect(find.text(AppStrings.appUpdateBannerTitle), findsOneWidget);
    expect(find.text(AppStrings.appUpdateBannerAction), findsOneWidget);

    await tester.tap(find.text(AppStrings.appUpdateBannerAction));
    await tester.pumpAndSettle();

    expect(find.text('news route'), findsOneWidget);
  });

  testWidgets('hides banner when app is already latest', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appReleaseRepositoryProvider.overrideWithValue(
            FakeAppReleaseRepository(
              AppReleaseSnapshot(
                version: AppVersionSnapshot(
                  currentVersion: '1.1.0',
                  latestVersion: '1.1.0',
                  checkedAt: DateTime.utc(2026, 5, 7),
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AppUpdateBanner())),
      ),
    );

    await tester.pump();

    expect(find.text(AppStrings.appUpdateBannerTitle), findsNothing);
  });
}
