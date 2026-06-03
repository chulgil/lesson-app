// Regression (#2): saving the visibility screen before the profile finishes
// loading must NOT overwrite the real visibility flags with defaults.
//
// The screen captured `_settings` in initState from `valueOrNull` (null while
// loading), defaulting to `const ProfileVisibilitySettings()`. After the
// provider resolved, the form was never re-synced, so Save PUT the defaults and
// silently wiped the teacher's real flags. The fix re-syncs `_settings` when
// the profile resolves (unless the user has edited it).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/academy/academy_facade.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/presentation/providers/teacher_extended_profile_provider.dart';
import 'package:lessonaza/features/profile/presentation/screens/profile_visibility_screen.dart';

void main() {
  testWidgets(
    'Save after a cold load keeps the real visibility flags (not defaults)',
    (tester) async {
      // Profile whose visibility differs from the defaults so an accidental
      // overwrite is detectable. (defaults: isSearchable=true, name=public)
      final loadedProfile = TeacherProfile(
        id: 'p1',
        userId: 'u1',
        name: '김선생',
        instruments: const ['피아노'],
        introduction: '소개글 텍스트입니다 20자 이상으로 충분히 길게 작성합니다.',
        visibilitySettings: const ProfileVisibilitySettings(
          isSearchable: false,
          nameVisibility: ProfileVisibility.private,
        ),
        createdAt: DateTime.utc(2026, 5, 1),
      );

      final fake = _FakeProfileNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherExtendedProfileProvider.overrideWith(() => fake),
            currentUserIdProvider.overrideWithValue('u1'),
            // The screen reads this family with '' while loading and the real
            // userId once resolved; override both with an empty list.
            teacherAcademiesProvider('').overrideWith(
              (ref) async => <TeacherAcademyMembership>[],
            ),
            teacherAcademiesProvider('u1').overrideWith(
              (ref) async => <TeacherAcademyMembership>[],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileVisibilityScreen(),
          ),
        ),
      );

      // Screen opened while still loading — this is the cold-load path.
      await tester.pump();

      // Profile resolves after the screen built.
      fake.emit(loadedProfile);
      await tester.pumpAndSettle();

      // The Save button sits below the fold in the scrollable list; scroll it
      // into view, then tap it without touching any toggle.
      final saveFinder = find.widgetWithText(FilledButton, '저장');
      await tester.scrollUntilVisible(saveFinder, 200);
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();

      // The saved settings must be the loaded (non-default) flags, NOT defaults.
      expect(fake.savedSettings, isNotNull);
      expect(fake.savedSettings!.isSearchable, isFalse);
      expect(
        fake.savedSettings!.nameVisibility,
        ProfileVisibility.private,
      );
    },
  );
}

/// Fake notifier that starts in loading, lets the test emit a value, and
/// records the settings passed to [updateVisibilitySettings].
class _FakeProfileNotifier extends TeacherExtendedProfile {
  ProfileVisibilitySettings? savedSettings;
  TeacherProfile? _current;

  @override
  AsyncValue<TeacherProfile?> build() => const AsyncValue.loading();

  void emit(TeacherProfile profile) {
    _current = profile;
    state = AsyncValue.data(profile);
  }

  @override
  Future<void> updateVisibilitySettings(
    ProfileVisibilitySettings settings,
  ) async {
    savedSettings = settings;
    _current = _current?.copyWith(visibilitySettings: settings);
    if (_current != null) state = AsyncValue.data(_current);
  }
}
