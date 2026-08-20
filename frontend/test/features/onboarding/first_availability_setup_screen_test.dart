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
import 'package:lessonaza/core/widgets/onboarding_step_header.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/first_availability_celebration_sheet.dart';

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

  // FirstAvailabilityInterstitialDialog test removed (2026-06-10) —
  // interstitial widget deprecated, see spec §4.1.

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

  testWidgets('#1287 UXC-4b 가용시간 화면 본문에 왜 필요한지가 보인다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const FirstAvailabilitySetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // '가용시간' 은 도메인 용어다. WHY 가 죽은 코치마크 카피에만 있으면 안 된다.
    expect(
      find.text(AppStrings.firstAvailabilityInterstitialDescription),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('#1104 첫 가용시간 화면은 스텝 헤더에서 4/4 단계를 활성화한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const FirstAvailabilitySetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingStepHeader), findsOneWidget);
    final header = tester.widget<OnboardingStepHeader>(
      find.byType(OnboardingStepHeader),
    );
    expect(header.steps, OnboardingStepHeader.teacherSteps);
    expect(header.currentStep, 4, reason: '첫 가용시간은 4단계 중 마지막');
    expect(tester.takeException(), isNull);
  });
}
