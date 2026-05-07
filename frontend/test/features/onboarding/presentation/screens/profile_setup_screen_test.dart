import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/profile_setup_screen.dart';

void main() {
  Future<void> pumpProfileSetup(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
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

    await tester.enterText(find.byType(TextField).at(0), '김선생');
    await tester.enterText(
      find.byType(TextField).at(1),
      '학생의 음악적 성장을 차분하게 돕는 선생님입니다.',
    );
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
}
