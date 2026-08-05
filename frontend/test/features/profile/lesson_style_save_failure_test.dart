// #1194 — 수업방식 저장 실패 시 사용자 안내 + 폼 보존.
//
// 감사 0712: lesson_style_settings_screen 의 4개 저장 호출이 fire-and-forget
// 이라 실패가 무반응(silent rollback)이거나 화면이 error 뷰로 덮여 폼이
// 사라졌다. 실패 시 SnackBar 안내 + 기존 값·폼 유지를 고정한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/onboarding/onboarding_facade.dart'
    show teacherProfileRepositoryProvider;
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/profile/domain/repositories/teacher_profile_repository.dart';
import 'package:lessonaza/features/profile/presentation/screens/lesson_style_settings_screen.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/settings_repository_provider.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_boot_migration_provider.dart';

TeacherProfile _profile() => TeacherProfile(
  id: 'p1',
  userId: 'u1',
  name: '테스트 선생님',
  instruments: const ['피아노'],
  introduction: '',
  verification: const TeacherVerification(),
  createdAt: DateTime(2026),
);

class _ThrowingProfileRepository implements TeacherProfileRepository {
  @override
  Future<TeacherProfile?> getProfileByUserId(String userId) async => _profile();

  @override
  Future<TeacherProfile?> getProfileById(String id) async => _profile();

  @override
  Future<TeacherProfile> updateProfile(TeacherProfile profile) async {
    throw Exception('network down');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _StubSettingsRepository implements SettingsRepository {
  final _settings = TeacherSettings(
    id: 'teacher-1',
    instruments: const ['피아노'],
    createdAt: DateTime.utc(2026, 7, 12),
  );

  @override
  Future<TeacherSettings> getTeacherSettings() async => _settings;

  @override
  Future<TeacherSettings> getTeacherSettingsById(String teacherId) async =>
      _settings;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  testWidgets('레슨 유형 저장 실패 → SnackBar + 폼 보존 (error 뷰 덮임 금지)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherProfileRepositoryProvider.overrideWithValue(
            _ThrowingProfileRepository(),
          ),
          settingsRepositoryProvider.overrideWithValue(
            _StubSettingsRepository(),
          ),
          teacherSettingsBootMigrationProvider.overrideWith(
            (ref) async => true,
          ),
        ],
        child: const MaterialApp(home: LessonStyleSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 레슨 유형 칩 하나를 토글 → 저장 시도 → 실패.
    final chip = find.byType(FilterChip).first;
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.settingsSaveFailed), findsOneWidget);
    // 폼이 error 뷰로 대체되지 않고 그대로 남아 있어야 한다.
    expect(find.byType(FilterChip), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
