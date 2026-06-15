import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/onboarding/onboarding_facade.dart'
    show currentTeacherProfileProvider;
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/profile/presentation/screens/instrument_management_screen.dart';
import 'package:lessonaza/features/settings/settings_facade.dart'
    show teacherSettingsProvider;

/// Widget smoke test (HARD-GATE) for InstrumentManagementScreen.
///
/// Asserts the screen renders without runtime crashes that `flutter analyze`
/// cannot detect, and that the instrument row uses SwipeActionTile instead of
/// a trailing IconButton (issue #659 — swipe consistency C3).
///
/// #732 — the screen now reads/writes `currentTeacherProfile.instruments`
/// (SSOT), so tests override that provider instead of relying on the default
/// settings mock.
TeacherProfile _profile({List<String> instruments = const ['바이올린', '피아노']}) =>
    TeacherProfile(
      id: 'p1',
      userId: 'u1',
      name: '테스트 선생님',
      instruments: instruments,
      introduction: '',
      verification: const TeacherVerification(),
      createdAt: DateTime(2026),
    );

// Profile is SSOT for instruments; settings override only keeps the migration
// guard's settings read off Hive in tests (#732).
TeacherSettings _settings() => TeacherSettings(
  id: 'teacher-1',
  instruments: const [],
  createdAt: DateTime(2026),
);

List<Override> _overrides() => [
  currentTeacherProfileProvider.overrideWith((_) async => _profile()),
  teacherSettingsProvider.overrideWith((_) async => _settings()),
];

void main() {
  testWidgets('InstrumentManagementScreen renders without crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const InstrumentManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(AppStrings.profileInstrumentTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'InstrumentManagementScreen instrument row uses SwipeActionTile (no trailing delete IconButton)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const InstrumentManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // At least one instrument row must be wrapped in SwipeActionTile.
      expect(find.byType(SwipeActionTile), findsWidgets);

      // No trailing delete IconButton inside the list — delete moved to swipe.
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );
}
