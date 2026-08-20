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

  testWidgets('#1287 UXC-1 도달할 수 없는 분야 단계는 빼고 번호를 다시 매긴다', (tester) async {
    // 등록된 discipline 이 music 하나뿐이면 RoleSelectScreen 이 분야 화면을
    // 건너뛴다. 4단계를 그리면 프로필이 "3/4" 로 읽혀 실제 여정과 어긋난다.
    await pumpHeader(
      tester,
      steps: OnboardingStepHeader.teacherSteps,
      currentStep: 3, // 프로필 — 4단계 리스트 기준
    );

    expect(find.text(AppStrings.onboardingStepDiscipline), findsNothing);
    expect(find.text(AppStrings.onboardingStepRole), findsOneWidget);
    expect(find.text(AppStrings.onboardingStepProfile), findsOneWidget);
    expect(find.text(AppStrings.onboardingStepAvailability), findsOneWidget);
    // 3단계로 줄었으므로 '4' 번은 없고, 프로필이 2번이 된다.
    expect(find.text('4'), findsNothing);

    final profileBadge = tester.widget<Container>(
      find.ancestor(of: find.text('2'), matching: find.byType(Container)).first,
    );
    expect(
      (profileBadge.decoration as BoxDecoration).color,
      AppColors.paperAccent,
      reason: '프로필은 3단계 여정의 2번째로 활성화돼야 한다',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('#1287 현재 서 있는 단계는 건너뛰기 대상이어도 감추지 않는다', (tester) async {
    // 분야 화면에 deep-link 로 도달한 경우 — 본인 위치를 숨기면 안 된다.
    await pumpHeader(
      tester,
      steps: OnboardingStepHeader.teacherSteps,
      currentStep: 2, // 분야
    );

    expect(find.text(AppStrings.onboardingStepDiscipline), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
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
