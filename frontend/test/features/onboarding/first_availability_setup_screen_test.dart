// Widget smoke tests for the first availability onboarding quest (#422).
//
// HARD-GATE: docs/specs/onboarding/teacher_first_availability_setup.md
// requires that the new top-level widgets render without runtime layout
// crashes (BoxConstraints / RenderMetaData). These tests pump each
// widget in isolation and assert `tester.takeException() == null`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/first_availability_setup_screen.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/first_availability_celebration_sheet.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/first_availability_interstitial.dart';

void main() {
  testWidgets(
    'FirstAvailabilitySetupScreen renders day chips and apply button',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const FirstAvailabilitySetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Title and section headers are present.
      expect(find.text(AppStrings.firstAvailabilitySetupTitle), findsOneWidget);
      expect(find.text(AppStrings.firstAvailabilityDaysLabel), findsOneWidget);
      expect(find.text(AppStrings.firstAvailabilityHoursLabel), findsOneWidget);

      // All 7 weekday chips are rendered.
      expect(find.text(AppStrings.firstAvailabilityDayMon), findsOneWidget);
      expect(find.text(AppStrings.firstAvailabilityDaySun), findsOneWidget);

      // Defaults section uses the 50/10/60 lesson defaults from the spec.
      // The default-line widget prefixes each entry with '· ' so we use
      // a substring matcher rather than equality.
      expect(
        find.textContaining(AppStrings.firstAvailabilityLessonDurationDefault),
        findsOneWidget,
      );
      expect(
        find.textContaining(AppStrings.firstAvailabilityBreakTimeDefault),
        findsOneWidget,
      );
      expect(
        find.textContaining(AppStrings.firstAvailabilityStartIntervalDefault),
        findsOneWidget,
      );

      // Apply CTA is visible.
      expect(
        find.text(AppStrings.firstAvailabilityApplyAction),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'FirstAvailabilityInterstitialDialog renders title + CTA without skip',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => Center(
                    child: ElevatedButton(
                      onPressed:
                          () => showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (_) => const PopScope(
                                  canPop: false,
                                  child: FirstAvailabilityInterstitialDialog(),
                                ),
                          ),
                      child: const Text('open'),
                    ),
                  ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Title + description from the spec are present.
      expect(
        find.text(AppStrings.firstAvailabilityInterstitialTitle),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.firstAvailabilityInterstitialDescription),
        findsOneWidget,
      );
      // CTA is the only action — spec §4.1 says no close button.
      expect(
        find.text(AppStrings.firstAvailabilityInterstitialAction),
        findsOneWidget,
      );
    },
  );

  testWidgets('FirstAvailabilityCelebrationSheet renders title + next CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: FirstAvailabilityCelebrationSheet()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.firstAvailabilityCelebrationTitle),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.firstAvailabilityCelebrationDescription),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.firstAvailabilityCelebrationNext),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.firstAvailabilityCelebrationAction),
      findsOneWidget,
    );
  });
}
