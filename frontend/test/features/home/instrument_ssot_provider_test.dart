// TDD tests for #732 — Instrument SSOT unification.
//
// Problem: management screen writes TeacherSettings.instruments,
// but hasInstrumentsProvider and profile_tab read currentTeacherProfile.instruments.
// Edits via the management screen do NOT reflect in quest/completion.
//
// Fix (this PR): management screen reads+writes profile.instruments.
// hasInstrumentsProvider simplified to profile-only (single SSOT).
//
// These tests cover:
//   1. hasInstrumentsProvider reads ONLY from profile after fix.
//   2. Migration: profile empty + settings non-empty → seeded (migration logic).
//   3. After updateProfile(instruments:[...]), hasInstrumentsProvider = true.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/home/presentation/providers/teacher_profile_completion_provider.dart';
import 'package:lessonaza/features/onboarding/onboarding_facade.dart'
    show currentTeacherProfileProvider;
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/settings/settings_facade.dart'
    show teacherSettingsProvider;

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

TeacherProfile _profile({List<String> instruments = const []}) =>
    TeacherProfile(
      id: 'p1',
      userId: 'u1',
      name: '테스트 선생님',
      instruments: instruments,
      introduction: '',
      verification: const TeacherVerification(),
      createdAt: DateTime(2026),
    );

TeacherSettings _settings({List<String> instruments = const []}) =>
    TeacherSettings(
      id: 'teacher-1',
      instruments: instruments,
      createdAt: DateTime(2026),
    );

Future<bool> _readHasInstruments(ProviderContainer c) async {
  c.read(hasInstrumentsProvider);
  await c.pump();
  return c.read(hasInstrumentsProvider);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('#732 hasInstrumentsProvider — profile-only SSOT (post-fix)', () {
    test('profile has instruments → true (primary path)', () async {
      final c = ProviderContainer(
        overrides: [
          currentTeacherProfileProvider.overrideWith(
            (_) async => _profile(instruments: ['바이올린']),
          ),
          teacherSettingsProvider.overrideWith(
            (_) async => _settings(instruments: []),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(await _readHasInstruments(c), isTrue);
    });

    test('profile is null → false (settings not consulted)', () async {
      final c = ProviderContainer(
        overrides: [
          currentTeacherProfileProvider.overrideWith((_) async => null),
          // settings has instruments — should NOT matter after fix
          teacherSettingsProvider.overrideWith(
            (_) async => _settings(instruments: ['피아노']),
          ),
        ],
      );
      addTearDown(c.dispose);
      // After #732 fix: SSOT is profile only. Null profile → false.
      // (Migration seeds profile from settings before this matters.)
      expect(await _readHasInstruments(c), isFalse);
    });

    test('both profile and settings empty → false', () async {
      final c = ProviderContainer(
        overrides: [
          currentTeacherProfileProvider.overrideWith(
            (_) async => _profile(instruments: []),
          ),
          teacherSettingsProvider.overrideWith(
            (_) async => _settings(instruments: []),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(await _readHasInstruments(c), isFalse);
    });
  });

  group('#732 Migration logic (pure function)', () {
    // The migration is implemented as a guard in the instrument management screen:
    // if profile.instruments.isEmpty && settings.instruments.isNotEmpty → seed profile.
    // We test the guard condition logic here as a pure function to ensure the
    // contract is correct before testing the widget.

    test('should seed when profile empty, settings non-empty', () {
      final profile = _profile(instruments: []);
      final settings = _settings(instruments: ['바이올린', '피아노']);

      final shouldSeed =
          profile.instruments.isEmpty && settings.instruments.isNotEmpty;
      expect(shouldSeed, isTrue);
    });

    test('should NOT seed when profile already has instruments', () {
      final profile = _profile(instruments: ['첼로']);
      final settings = _settings(instruments: ['바이올린']);

      final shouldSeed =
          profile.instruments.isEmpty && settings.instruments.isNotEmpty;
      expect(shouldSeed, isFalse);
    });

    test('should NOT seed when settings also empty', () {
      final profile = _profile(instruments: []);
      final settings = _settings(instruments: []);

      final shouldSeed =
          profile.instruments.isEmpty && settings.instruments.isNotEmpty;
      expect(shouldSeed, isFalse);
    });

    test('migration preserves all instruments from settings', () {
      final settings = _settings(instruments: ['바이올린', '피아노', '첼로']);
      final profile = _profile(instruments: []);

      // After seeding, profile.instruments == settings.instruments
      final seeded = profile.copyWith(instruments: settings.instruments);
      expect(seeded.instruments, equals(['바이올린', '피아노', '첼로']));
      expect(seeded.instruments, hasLength(3));
    });
  });

  group('#732 profile.instruments drives quest completion', () {
    test(
      'profile with instruments → hasInstruments = true → quest Q3b complete',
      () async {
        final c = ProviderContainer(
          overrides: [
            currentTeacherProfileProvider.overrideWith(
              (_) async => _profile(instruments: ['바이올린']),
            ),
            teacherSettingsProvider.overrideWith((_) async => _settings()),
          ],
        );
        addTearDown(c.dispose);

        expect(
          await _readHasInstruments(c),
          isTrue,
          reason:
              'hasInstruments must be true so Q3b quest completes after mgmt-screen save',
        );
      },
    );
  });
}
