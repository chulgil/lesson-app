// TDD test for hasInstrumentsProvider — Bug #726 instrument quest SSOT fix.
//
// Problem: hasInstrumentsProvider only reads currentTeacherProfileProvider.
// The instrument MANAGEMENT screen writes to teacherSettingsProvider.
// So editing instruments via the screen never completes the quest.
//
// Fix: return true if EITHER source has instruments.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/home/presentation/providers/teacher_profile_completion_provider.dart';
import 'package:lessonaza/features/onboarding/onboarding_facade.dart'
    show currentTeacherProfileProvider;
import 'package:lessonaza/features/settings/settings_facade.dart'
    show teacherSettingsProvider;
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';

// Minimal TeacherSettings factory for tests.
TeacherSettings _settings({List<String> instruments = const []}) =>
    TeacherSettings(
      id: 'teacher-1',
      instruments: instruments,
      createdAt: DateTime(2026),
    );

/// Read [hasInstrumentsProvider] after async sub-providers settle.
Future<bool> _read(ProviderContainer container) async {
  // Trigger listener so providers begin building.
  container.read(hasInstrumentsProvider);
  // Pump microtasks until async providers resolve.
  await container.pump();
  return container.read(hasInstrumentsProvider);
}

void main() {
  group('hasInstrumentsProvider — Bug #726 두 소스 OR 판정', () {
    test('Case A: settings 에 악기 있고 profile 이 null 이면 → true', () async {
      final container = ProviderContainer(
        overrides: [
          currentTeacherProfileProvider.overrideWith(
            (_) async => null, // profile: no instruments
          ),
          teacherSettingsProvider.overrideWith(
            (_) async => _settings(instruments: ['바이올린']),
          ),
        ],
      );
      addTearDown(container.dispose);

      // RED before fix: only reads profile, so settings instruments ignored → false.
      // GREEN after fix: OR of both sources → true.
      expect(await _read(container), isTrue);
    });

    test('Case B: 양쪽 모두 비어 있으면 → false', () async {
      final container = ProviderContainer(
        overrides: [
          currentTeacherProfileProvider.overrideWith((_) async => null),
          teacherSettingsProvider.overrideWith(
            (_) async => _settings(instruments: []),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await _read(container), isFalse);
    });
  });
}
