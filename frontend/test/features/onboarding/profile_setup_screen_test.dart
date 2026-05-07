import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/profile_setup_screen.dart';

void main() {
  test(
    'saveOnboardingProfileImage falls back to the picked file when crop is cancelled',
    () async {
      final picked = XFile('/tmp/gallery-picked.jpg');
      String? savedSource;

      final result = await saveOnboardingProfileImage(
        pickedImage: picked,
        cropper: (_) async => null,
        saver: (sourcePath, fileName) async {
          savedSource = sourcePath;
          expect(fileName, 'onboarding_test');
          return 'saved:$sourcePath';
        },
        fileName: 'onboarding_test',
      );

      expect(savedSource, picked.path);
      expect(result, 'saved:${picked.path}');
    },
  );

  testWidgets(
    'ProfileSetupScreen allows moving forward without a profile photo',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '테스트 선생님');

      await tester.ensureVisible(
        find.byKey(ProfileSetupScreen.instrumentSelectorKey),
      );
      await tester.tap(find.byKey(ProfileSetupScreen.instrumentSelectorKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('바이올린'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        '학생들에게 보여질 소개글입니다. 20자 이상이어야 합니다.',
      );
      await tester.pumpAndSettle();

      final submitButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(submitButton.onPressed, isNotNull);
      expect(
        find.text(AppStrings.onboardingProfilePhotoOptional),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.onboardingProfilePhotoTrustHint),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Instrument selector sheet renders an opaque paper surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProfileSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(ProfileSetupScreen.instrumentSelectorKey),
    );
    await tester.tap(find.byKey(ProfileSetupScreen.instrumentSelectorKey));
    await tester.pumpAndSettle();

    final sheet = tester.widget<Container>(
      find.byKey(const Key('profile_setup_instrument_selector_sheet')),
    );
    final decoration = sheet.decoration as BoxDecoration;

    expect(decoration.color, AppColors.paper);
    expect(decoration.borderRadius, BorderRadius.zero);
    expect(tester.takeException(), isNull);
  });
}
