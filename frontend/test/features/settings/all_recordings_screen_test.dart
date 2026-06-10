import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/settings/presentation/screens/all_recordings_screen.dart';

/// Widget smoke test (HARD-GATE) for the new
/// SettingsRecordingActionsBottomSheet (issue #659 — swipe consistency C5).
///
/// Verifies the bottom sheet shows 재생 / 공유 / 링크 변경 actions that
/// replace the previous trailing IconButton row (play / link / delete).
/// Delete is now a swipe action on the row.
///
/// Note: A full `AllRecordingsScreen` smoke test would require Hive
/// initialization (PracticeRepositoryBase). The pure presentation widget
/// is verified here; the screen wiring is checked manually via dev build.
void main() {
  testWidgets(
    'SettingsRecordingActionsBottomSheet shows 재생 / 공유 / 링크 변경 actions',
    (tester) async {
      var played = false;
      var shared = false;
      var changedLink = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SettingsRecordingActionsBottomSheet(
              onPlay: () => played = true,
              onShare: () => shared = true,
              onChangeLink: () => changedLink = true,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.recordingActionsPlay), findsOneWidget);
      expect(find.text(AppStrings.recordingActionsShare), findsOneWidget);
      expect(find.text(AppStrings.recordingActionsCopyLink), findsOneWidget);

      await tester.tap(find.text(AppStrings.recordingActionsPlay));
      expect(played, isTrue);

      await tester.tap(find.text(AppStrings.recordingActionsShare));
      expect(shared, isTrue);

      await tester.tap(find.text(AppStrings.recordingActionsCopyLink));
      expect(changedLink, isTrue);

      expect(tester.takeException(), isNull);
    },
  );
}
