import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show activeDisciplineProvider;
import 'package:lessonaza/features/student_home/presentation/providers/student_home_profile_edit_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/add_manual_teacher_screen.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_profile_edit_screen.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

/// #1072 — discipline-aware expertise picker (완결분: 편집 화면 + 공유 selector).
///
/// #1071 covered the 3 onboarding/management pickers. This slice routes the two
/// remaining SAVING pickers through `ExpertiseCatalogRegistry.forDiscipline`:
///  - StudentProfileEditScreen (dropdown; also fixes the 색소폰→바이올린 revert)
///  - the shared InstrumentSelector chips (exercised via AddManualTeacherScreen)
///
/// Music stays byte-identical to the 22-item instrument catalog; fitness
/// surfaces 웨이트/필라테스/PT. The edit-screen dropdown additionally preserves a
/// saved value outside the active catalog (custom/legacy) instead of silently
/// reverting it — the auto-save-on-exit data-loss fix.
///
/// RED before the swap: an active fitness discipline still lists music
/// instruments, so `필라테스` is absent and `첼로` present; and the edit dropdown
/// reverts `색소폰` (not in the old 10-list) to `바이올린`.
void main() {
  // #980: keep Playfair (google_fonts) offline so Notebook surfaces render in
  // widget tests without a late network fetch dangling past teardown.
  GoogleFonts.config.allowRuntimeFetching = false;

  // A music instrument that is NOT a fitness specialty — the discriminator.
  const musicOnlyTag = '첼로';
  // A fitness specialty that is NOT a music instrument.
  const fitnessTag = '필라테스';
  // In the 22-item catalog but NOT the old hardcoded 10-list — the revert repro.
  const outOf10Music = '색소폰';
  // Outside every registered catalog — custom / legacy value preservation.
  const customTag = '가야금';

  List<Override> activeDiscipline(Discipline d) => [
    activeDisciplineProvider.overrideWith((ref) => d),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget home,
    List<Override> overrides,
  ) async {
    // Real phone portrait (iPhone-class 375x812) so the takeException checks
    // run at a shipping viewport. (The chip Wrap sits in a scroll view and the
    // edit dropdown is a menu, so neither overflows here — the guard is against
    // render exceptions, not a repeat of #1071's clipped non-scroll sheet.)
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

  group('공유 InstrumentSelector (AddManualTeacherScreen)', () {
    testWidgets('music: 악기 카탈로그(첼로) 노출 — byte-identity 앵커', (tester) async {
      await pump(
        tester,
        const AddManualTeacherScreen(),
        activeDiscipline(DisciplineRegistry.music),
      );

      expect(find.text(musicOnlyTag), findsOneWidget);
      expect(find.text(fitnessTag), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fitness: specialty(필라테스) 노출 + 악기(첼로) 부재', (tester) async {
      await pump(
        tester,
        const AddManualTeacherScreen(),
        activeDiscipline(DisciplineRegistry.fitness),
      );

      expect(find.text(fitnessTag), findsOneWidget);
      expect(find.text(musicOnlyTag), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('학생 프로필 편집 (StudentProfileEditScreen)', () {
    List<Override> overridesFor(Discipline d, Student student) => [
      activeDisciplineProvider.overrideWith((ref) => d),
      studentHomeProfileEditStudentProvider.overrideWith(
        (ref) async => student,
      ),
      studentHomeProfileEditImagePathProvider(
        student.id,
      ).overrideWith((ref) async => null),
    ];

    Student studentWith(String instrument) => Student(
      id: 'student_1',
      name: '김서연',
      instrument: instrument,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    // Inspect the DropdownButton widget directly: d.value + d.items is a
    // stronger assertion than find.text — it verifies both the preserved
    // selection AND that an out-of-catalog value was prepended to the items.
    DropdownButton<String> dropdown(WidgetTester tester) =>
        tester.widget<DropdownButton<String>>(
          find.byWidgetPredicate((w) => w is DropdownButton<String>),
        );

    testWidgets('revert 회귀: 색소폰(구 10-list 밖) 저장값이 바이올린으로 revert 되지 않고 보존', (
      tester,
    ) async {
      await pump(
        tester,
        const StudentProfileEditScreen(),
        overridesFor(DisciplineRegistry.music, studentWith(outOf10Music)),
      );

      final d = dropdown(tester);
      expect(d.value, outOf10Music); // 바이올린 아님
      final values = d.items!.map((e) => e.value).toList();
      expect(values, contains(outOf10Music));
      expect(values, contains('바이올린')); // 22-카탈로그 노출
      expect(values, isNot(contains(fitnessTag))); // music 카탈로그
      expect(tester.takeException(), isNull);
    });

    testWidgets('카탈로그 밖 커스텀/레거시 값(가야금)도 보존 — 항목에 prepend', (tester) async {
      await pump(
        tester,
        const StudentProfileEditScreen(),
        overridesFor(DisciplineRegistry.music, studentWith(customTag)),
      );

      final d = dropdown(tester);
      expect(d.value, customTag);
      expect(d.items!.map((e) => e.value), contains(customTag));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fitness: 저장된 specialty(필라테스) 값 표시 + specialty 카탈로그', (
      tester,
    ) async {
      await pump(
        tester,
        const StudentProfileEditScreen(),
        overridesFor(DisciplineRegistry.fitness, studentWith(fitnessTag)),
      );

      final d = dropdown(tester);
      expect(d.value, fitnessTag);
      final values = d.items!.map((e) => e.value).toList();
      expect(values, contains(fitnessTag));
      expect(values, isNot(contains(musicOnlyTag))); // 악기 부재
      expect(tester.takeException(), isNull);
    });
  });
}
