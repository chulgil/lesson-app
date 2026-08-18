import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show activeDisciplineProvider;
import 'package:lessonaza/features/onboarding/onboarding_facade.dart'
    show currentTeacherProfileProvider;
import 'package:lessonaza/features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/student_profile_setup_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/profile/presentation/screens/instrument_management_screen.dart';
import 'package:lessonaza/features/settings/settings_facade.dart'
    show teacherSettingsProvider;

/// #1071 — discipline-aware expertise picker.
///
/// The onboarding + expertise-management pickers must list the ACTIVE
/// discipline's expertise catalog (`ExpertiseCatalogRegistry.forDiscipline`),
/// not a hardcoded music instrument list. Music stays byte-identical (the music
/// catalog == `InstrumentList.all`).
///
/// #1278 (음악 단일 포커스): music 이 유일한 등록 분야이므로 미등록 분야는
/// music 카탈로그로 degrade 한다. 각 그룹의 두 번째 케이스가 그 폴백 계약을
/// 고정한다 — 카탈로그 조회가 분야 하드코딩이 아니라 레지스트리 경유임을 보장.
void main() {
  // #980: keep Playfair (google_fonts) offline so Notebook surfaces render in
  // widget tests without a late network fetch dangling past teardown.
  GoogleFonts.config.allowRuntimeFetching = false;

  // A music instrument — present whenever the music catalog is the source.
  const musicOnlyTag = '첼로';
  // A tag that belongs to no registered catalog — must never surface (#1278).
  const unregisteredTag = '필라테스';

  /// An unregistered discipline (its catalog id resolves to nothing) — the
  /// picker must degrade to the music catalog rather than render empty.
  const unregisteredDiscipline = Discipline(
    id: 'unregistered',
    displayKey: 'discipline.unregistered',
    themeColorSeed: 0xFF000000,
    expertiseCatalogId: 'specialties',
  );

  List<Override> activeDiscipline(Discipline d) => [
    activeDisciplineProvider.overrideWith((ref) => d),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget home,
    List<Override> overrides,
  ) async {
    // Real phone portrait (iPhone-class 375x812). The `takeException` checks in
    // each case then also guard the picker sheets against layout overflow at a
    // shipping viewport (the student sheet is now isScrollControlled). The 800x600
    // test default is landscape-short and overflows the onboarding columns for
    // reasons unrelated to the picker source.
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(theme: AppTheme.light, home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('교사 온보딩 picker (ProfileSetupScreen)', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.ensureVisible(
        find.byKey(ProfileSetupScreen.instrumentSelectorKey),
      );
      await tester.tap(find.byKey(ProfileSetupScreen.instrumentSelectorKey));
      await tester.pumpAndSettle();
    }

    testWidgets('music: 악기 카탈로그(첼로) 노출 — byte-identity 앵커', (tester) async {
      await pump(
        tester,
        const ProfileSetupScreen(),
        activeDiscipline(DisciplineRegistry.music),
      );
      await openSheet(tester);

      expect(find.text(musicOnlyTag), findsOneWidget);
      expect(find.text(unregisteredTag), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('미등록 분야: music 카탈로그로 degrade (첼로 노출) — #1278', (tester) async {
      await pump(
        tester,
        const ProfileSetupScreen(),
        activeDiscipline(unregisteredDiscipline),
      );
      await openSheet(tester);

      expect(find.text(musicOnlyTag), findsOneWidget);
      expect(find.text(unregisteredTag), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('학생 온보딩 picker (StudentProfileSetupScreen)', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.text(AppStrings.studentProfileSetupInstrumentHint));
      await tester.pumpAndSettle();
    }

    testWidgets('music: 악기 카탈로그(첼로) 노출 — byte-identity 앵커', (tester) async {
      await pump(
        tester,
        const StudentProfileSetupScreen(),
        activeDiscipline(DisciplineRegistry.music),
      );
      await openSheet(tester);

      expect(find.text(musicOnlyTag), findsOneWidget);
      expect(find.text(unregisteredTag), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('미등록 분야: music 카탈로그로 degrade (첼로 노출) — #1278', (tester) async {
      await pump(
        tester,
        const StudentProfileSetupScreen(),
        activeDiscipline(unregisteredDiscipline),
      );
      await openSheet(tester);

      expect(find.text(musicOnlyTag), findsOneWidget);
      expect(find.text(unregisteredTag), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('교사 전문분야 관리 add 시트 (InstrumentManagementScreen)', () {
    // Empty current profile so the add sheet lists the full catalog (nothing
    // filtered out as already-added).
    TeacherProfile emptyProfile() => TeacherProfile(
      id: 'p1',
      userId: 'u1',
      name: '테스트 선생님',
      instruments: const [],
      introduction: '',
      verification: const TeacherVerification(),
      createdAt: DateTime(2026),
    );

    List<Override> overridesFor(Discipline d) => [
      activeDisciplineProvider.overrideWith((ref) => d),
      currentTeacherProfileProvider.overrideWith((_) async => emptyProfile()),
      teacherSettingsProvider.overrideWith(
        (_) async => TeacherSettings(
          id: 'teacher-1',
          instruments: const [],
          createdAt: DateTime(2026),
        ),
      ),
    ];

    Future<void> openAddSheet(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
    }

    testWidgets('music: 추가 시트에 악기 카탈로그(첼로) 노출 — byte-identity 앵커', (
      tester,
    ) async {
      await pump(
        tester,
        const InstrumentManagementScreen(),
        overridesFor(DisciplineRegistry.music),
      );
      await openAddSheet(tester);

      expect(find.text(musicOnlyTag), findsOneWidget);
      expect(find.text(unregisteredTag), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('미등록 분야: 추가 시트가 music 카탈로그로 degrade (첼로 노출) — #1278', (
      tester,
    ) async {
      await pump(
        tester,
        const InstrumentManagementScreen(),
        overridesFor(unregisteredDiscipline),
      );
      await openAddSheet(tester);

      expect(find.text(musicOnlyTag), findsOneWidget);
      expect(find.text(unregisteredTag), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
