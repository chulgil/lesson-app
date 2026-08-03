// Widget smoke test for #1146 — the "레슨 방식" section on
// LessonStyleSettingsScreen. Confirms the section renders its multi-select
// chips and that tapping one flips the selection (render-crash + UI wiring).
//
// Uses fake notifiers so both async gates resolve immediately (no perpetual
// CircularProgressIndicator under pumpAndSettle). The real write→read +
// currentTeacherProfileProvider invalidation is covered by
// lesson_type_write_read_sync_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/profile/presentation/providers/teacher_extended_profile_provider.dart';
import 'package:lessonaza/features/profile/presentation/screens/lesson_style_settings_screen.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_provider.dart';

class _FakeSettingsNotifier extends TeacherSettingsNotifier {
  @override
  Future<TeacherSettings> build() async => TeacherSettings(
    id: 'fake',
    instruments: const [],
    createdAt: DateTime(2026),
  );
}

class _FakeExtendedProfile extends TeacherExtendedProfile {
  _FakeExtendedProfile(this._profile);
  TeacherProfile _profile;

  @override
  AsyncValue<TeacherProfile?> build() => AsyncValue.data(_profile);

  @override
  Future<void> updateLessonTypes(List<LessonType> types) async {
    _profile = _profile.copyWith(lessonTypes: types);
    state = AsyncValue.data(_profile);
  }
}

TeacherProfile _profile() => TeacherProfile(
  id: 'p1',
  userId: 'u1',
  name: '테스트 선생님',
  instruments: const [],
  introduction: '',
  verification: const TeacherVerification(),
  createdAt: DateTime(2026),
);

void main() {
  testWidgets('레슨 방식 section renders chips and tapping flips selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherSettingsNotifierProvider.overrideWith(
            () => _FakeSettingsNotifier(),
          ),
          teacherExtendedProfileProvider.overrideWith(
            () => _FakeExtendedProfile(_profile()),
          ),
        ],
        child: const MaterialApp(home: LessonStyleSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilterChip, '대면 수업'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '온라인'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '방문 수업'), findsOneWidget);

    // Starts unselected (profile has no lessonTypes set).
    FilterChip chipFor(String label) =>
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, label));
    expect(chipFor('대면 수업').selected, isFalse);

    // Tapping flips the selection (onSelected → updateLessonTypes → rebuild).
    await tester.tap(find.widgetWithText(FilterChip, '대면 수업'));
    await tester.pumpAndSettle();

    expect(chipFor('대면 수업').selected, isTrue);
    expect(chipFor('온라인').selected, isFalse);
  });
}
