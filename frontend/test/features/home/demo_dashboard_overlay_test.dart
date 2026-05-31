import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/features/home/presentation/widgets/demo_dashboard_overlay.dart';
import 'package:lessonaza/features/onboarding/presentation/providers/onboarding_progress_storage_provider.dart';

void main() {
  testWidgets('completed onboarding teacher sees demo overlay once', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProgressStorageProvider.overrideWith(
            CompletedOnboardingProgressStorageFake.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: DemoDashboardOverlay()),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(DemoDashboardOverlay), findsOneWidget);
    expect(find.byType(NotebookCard), findsOneWidget);
    expect(find.text(AppStrings.demoDashboardOverlayEyebrow), findsOneWidget);
    expect(find.text(AppStrings.demoDashboardOverlayTitle), findsOneWidget);
    expect(
      find.text(AppStrings.demoDashboardOverlayDescription),
      findsOneWidget,
    );
    expect(find.text(AppStrings.demoDashboardOverlayConfirm), findsOneWidget);
    expect(
      find.text(AppStrings.demoDashboardOverlayNeverShowAgain),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.demoDashboardOverlayConfirm));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NotebookCard), findsNothing);
    expect(
      CompletedOnboardingProgressStorageFake.latest?.state.valueOrNull,
      isNotNull,
    );
    expect(
      CompletedOnboardingProgressStorageFake
          .latest
          ?.state
          .valueOrNull
          ?.demoOverlayDismissed,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismissed demo overlay stays hidden on first home entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProgressStorageProvider.overrideWith(
            DismissedOnboardingProgressStorageFake.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: DemoDashboardOverlay()),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(NotebookCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다시 보지 않기 action dismisses and persists overlay state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProgressStorageProvider.overrideWith(
            CompletedOnboardingProgressStorageFake.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: DemoDashboardOverlay()),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text(AppStrings.demoDashboardOverlayNeverShowAgain));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NotebookCard), findsNothing);
    expect(
      CompletedOnboardingProgressStorageFake
          .latest
          ?.state
          .valueOrNull
          ?.demoOverlayDismissed,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'teacher without completed onboarding does not see demo overlay',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingProgressStorageProvider.overrideWith(
              IncompleteOnboardingProgressStorageFake.new,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: DemoDashboardOverlay()),
          ),
        ),
      );

      await tester.pump();

      expect(find.text(AppStrings.demoDashboardOverlayEyebrow), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class CompletedOnboardingProgressStorageFake extends OnboardingProgressStorage {
  static CompletedOnboardingProgressStorageFake? latest;

  CompletedOnboardingProgressStorageFake() {
    latest = this;
  }

  @override
  Future<OnboardingProgressStorageState> build() async {
    return const OnboardingProgressStorageState(
      teacherOnboardingCompleted: true,
      demoOverlayDismissed: false,
      coachMarkCompleted: true,
    );
  }

  @override
  Future<void> dismissDemoOverlay() async {
    state = const AsyncData(
      OnboardingProgressStorageState(
        teacherOnboardingCompleted: true,
        demoOverlayDismissed: true,
        coachMarkCompleted: true,
      ),
    );
  }
}

class DismissedOnboardingProgressStorageFake extends OnboardingProgressStorage {
  @override
  Future<OnboardingProgressStorageState> build() async {
    return const OnboardingProgressStorageState(
      teacherOnboardingCompleted: true,
      demoOverlayDismissed: true,
      coachMarkCompleted: true,
    );
  }
}

class IncompleteOnboardingProgressStorageFake
    extends OnboardingProgressStorage {
  @override
  Future<OnboardingProgressStorageState> build() async {
    return const OnboardingProgressStorageState.defaults();
  }
}
