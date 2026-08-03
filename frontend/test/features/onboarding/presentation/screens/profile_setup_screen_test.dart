import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/auth/auth_state.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/auth/presentation/providers/auth_provider.dart';
import 'package:lessonaza/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'package:lessonaza/core/widgets/onboarding_step_header.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_onboarding.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';

// ---------------------------------------------------------------------------
// Stubs for submit-flow test
// ---------------------------------------------------------------------------

class _StubProfileNotifier extends CurrentTeacherProfileNotifier {
  int createFromOnboardingCalls = 0;

  @override
  Future<TeacherProfile?> build() async => null;

  @override
  Future<TeacherProfile> createFromOnboarding(
    TeacherOnboardingState onboardingState,
  ) async {
    createFromOnboardingCalls++;
    return TeacherProfile(
      id: 'stub',
      userId: 'u1',
      name: onboardingState.profile?.name ?? '',
      instruments: onboardingState.profile?.instruments ?? [],
      introduction: '',
      createdAt: DateTime(2026),
    );
  }
}

class _StubAuthNotifier extends AuthNotifier {
  int completeOnboardingCalls = 0;

  @override
  AuthState build() => AuthAuthenticated(
    userId: 'u1',
    name: '김선생',
    email: 'test@test.com',
    role: UserRole.teacher,
  );

  @override
  Future<void> completeOnboarding() async {
    completeOnboardingCalls++;
  }
}

// ---------------------------------------------------------------------------

void main() {
  Future<void> pumpProfileSetup(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // #1071: the instrument picker now reads the active discipline;
          // pin it to music (what these tests exercise) so it never hits Hive.
          activeDisciplineProvider.overrideWith(
            (ref) => DisciplineRegistry.music,
          ),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProfileSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('선생님 프로필 사진은 선택 항목이며 사진 없이 다음 버튼이 활성화된다', (tester) async {
    await pumpProfileSetup(tester);

    // A1: 이름 필드 1개만 존재 (소개글 입력 제거됨).
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '김선생');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(ProfileSetupScreen.instrumentSelectorKey),
    );
    await tester.tap(find.byKey(ProfileSetupScreen.instrumentSelectorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('바이올린'));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.onboardingProfilePhotoOptional),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.onboardingProfilePhotoTrustHint),
      findsOneWidget,
    );
    expect(find.textContaining('프로필 사진'), findsOneWidget);

    final nextButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, AppStrings.onboardingNext),
    );
    expect(nextButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('악기 선택 팝업은 Notebook 불투명 시트로 표시된다', (tester) async {
    await pumpProfileSetup(tester);

    await tester.ensureVisible(
      find.byKey(ProfileSetupScreen.instrumentSelectorKey),
    );
    await tester.tap(find.byKey(ProfileSetupScreen.instrumentSelectorKey));
    await tester.pumpAndSettle();

    expect(find.byType(NotebookBottomSheet), findsOneWidget);
    expect(find.text(AppStrings.onboardingSelectInstrument), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('프로필 사진 선택 시 갤러리와 카메라 선택지를 표시한다', (tester) async {
    await pumpProfileSetup(tester);

    await tester.tap(find.byIcon(Icons.camera_alt).first);
    await tester.pumpAndSettle();

    expect(find.byType(NotebookBottomSheet), findsOneWidget);
    expect(find.text(AppStrings.onboardingSelectFromGallery), findsOneWidget);
    expect(find.text(AppStrings.onboardingTakePhoto), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다음 버튼 탭 시 createFromOnboarding을 호출하여 프로필을 백엔드에 저장한다 (#14)', (
    tester,
  ) async {
    final profileNotifier = _StubProfileNotifier();
    final authNotifier = _StubAuthNotifier();

    await pumpProfileSetup(
      tester,
      overrides: [
        currentTeacherProfileNotifierProvider.overrideWith(
          () => profileNotifier,
        ),
        authNotifierProvider.overrideWith(() => authNotifier),
      ],
    );

    // 이름·악기 입력 (필수 필드)
    await tester.enterText(find.byType(TextField).at(0), '김선생');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(ProfileSetupScreen.instrumentSelectorKey),
    );
    await tester.tap(find.byKey(ProfileSetupScreen.instrumentSelectorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('바이올린'));
    await tester.pumpAndSettle();

    // 다음(submit)
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.onboardingNext),
    );
    await tester.pumpAndSettle();

    expect(
      profileNotifier.createFromOnboardingCalls,
      1,
      reason: 'submit 시 createFromOnboarding이 정확히 1회 호출되어야 한다 (#14)',
    );
    expect(
      authNotifier.completeOnboardingCalls,
      1,
      reason: '프로필 저장 후 onboarding-complete도 호출되어야 한다',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('#1104 프로필 화면은 스텝 헤더에서 3/4(프로필) 단계를 활성화한다', (tester) async {
    await pumpProfileSetup(tester);

    expect(find.byType(OnboardingStepHeader), findsOneWidget);
    final header = tester.widget<OnboardingStepHeader>(
      find.byType(OnboardingStepHeader),
    );
    expect(header.steps, OnboardingStepHeader.teacherSteps);
    expect(header.currentStep, 3, reason: '프로필은 4단계 중 3번째');
    expect(tester.takeException(), isNull);
  });
}
