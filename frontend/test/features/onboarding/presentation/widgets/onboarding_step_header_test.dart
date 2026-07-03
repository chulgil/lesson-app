// #1104 — Shared onboarding step-progress header behavior + smoke.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/onboarding_step_header.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    required List<String> steps,
    required int currentStep,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: OnboardingStepHeader(steps: steps, currentStep: currentStep),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('N개 스텝 라벨과 번호를 모두 렌더한다', (tester) async {
    await pumpHeader(
      tester,
      steps: const ['하나', '둘', '셋', '넷'],
      currentStep: 1,
    );

    for (final label in const ['하나', '둘', '셋', '넷']) {
      expect(find.text(label), findsOneWidget);
    }
    // 4 스텝이면 번호 1~4 가 모두 표시된다.
    for (final n in const ['1', '2', '3', '4']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('현재 스텝만 활성 색으로 강조된다', (tester) async {
    await pumpHeader(
      tester,
      steps: const ['하나', '둘', '셋', '넷'],
      currentStep: 3,
    );

    // 활성 스텝의 번호 컨테이너는 강조색(paperAccent) 배경을 가진다.
    final activeBadge = tester.widget<Container>(
      find.ancestor(of: find.text('3'), matching: find.byType(Container)).first,
    );
    final activeDecoration = activeBadge.decoration as BoxDecoration;
    expect(activeDecoration.color, AppColors.paperAccent);
    // Notebook 각진 원칙 — 라운드 처리 금지.
    expect(activeDecoration.borderRadius, BorderRadius.zero);

    expect(tester.takeException(), isNull);
  });

  testWidgets('smoke — 좁은 제약(Row) 안에서 예외 없이 렌더된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Row(
            children: const [
              Expanded(
                child: OnboardingStepHeader(
                  steps: OnboardingStepHeader.teacherSteps,
                  currentStep: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('teacherSteps 는 역할→분야→프로필→가용시간 4단계 SSOT 다', () {
    expect(OnboardingStepHeader.teacherSteps, const [
      AppStrings.onboardingStepRole,
      AppStrings.onboardingStepDiscipline,
      AppStrings.onboardingStepProfile,
      AppStrings.onboardingStepAvailability,
    ]);
  });
}
