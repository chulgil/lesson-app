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
/// catalog == `InstrumentList.all`); fitness surfaces 웨이트/필라테스/PT.
///
/// RED before the swap: with an active fitness discipline the pickers still
/// list music instruments, so `필라테스` is absent and `첼로` is present. The
/// music cases are byte-identity anchors — they pass before AND after the swap.
void main() {
  // #980: keep Playfair (google_fonts) offline so Notebook surfaces render in
  // widget tests without a late network fetch dangling past teardown.
  GoogleFonts.config.allowRuntimeFetching = false;

  // A music instrument that is NOT a fitness specialty — the discriminator.
  const musicOnlyTag = '첼로';
  // A fitness specialty that is NOT a music instrument.
  const fitnessTag = '필라테스';

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
      expect(find.text(fitnessTag), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fitness: specialty(필라테스) 노출 + 악기(첼로) 부재', (tester) async {
      await pump(
        tester,
        const ProfileSetupScreen(),
        activeDiscipline(DisciplineRegistry.fitness),
      );
      await openSheet(tester);

      expect(find.text(fitnessTag), findsOneWidget);
      expect(find.text(musicOnlyTag), findsNothing);
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
      expect(find.text(fitnessTag), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fitness: specialty(필라테스) 노출 + 악기(첼로) 부재', (tester) async {
      await pump(
        tester,
        const StudentProfileSetupScreen(),
        activeDiscipline(DisciplineRegistry.fitness),
      );
      await openSheet(tester);

      expect(find.text(fitnessTag), findsOneWidget);
      expect(find.text(musicOnlyTag), findsNothing);
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
      expect(find.text(fitnessTag), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fitness: 추가 시트에 specialty(필라테스) 노출 + 악기(첼로) 부재', (
      tester,
    ) async {
      await pump(
        tester,
        const InstrumentManagementScreen(),
        overridesFor(DisciplineRegistry.fitness),
      );
      await openAddSheet(tester);

      expect(find.text(fitnessTag), findsOneWidget);
      expect(find.text(musicOnlyTag), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
