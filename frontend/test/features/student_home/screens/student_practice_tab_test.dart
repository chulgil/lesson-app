import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_note.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_note_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_practice_tab.dart';

void main() {
  group('StudentPracticeTab — §2.4 노트 섹션 통합 smoke (#492)', () {
    PracticeRepertoire makeRepertoire({
      required List<PracticeSection> sections,
    }) {
      final now = DateTime.now();
      return PracticeRepertoire(
        id: 'rep-1',
        studentId: 'student-1',
        name: 'Canon Practice',
        startDate: now.subtract(const Duration(days: 1)),
        sections: sections,
        createdAt: now.subtract(const Duration(days: 1)),
      );
    }

    PracticeSection makeSection({
      String id = 'section-1',
      String pieceName = 'Canon',
    }) {
      final now = DateTime.now();
      return PracticeSection(
        id: id,
        repertoireId: 'rep-1',
        pieceName: pieceName,
        startMeasure: 1,
        endMeasure: 8,
        createdAt: now.subtract(const Duration(days: 1)),
      );
    }

    testWidgets('renders without exceptions when repertoire has sections', (
      tester,
    ) async {
      // 440x900: 사전 존재(pre-existing) masthead 27px 오버플로 회피용.
      // 본 테스트의 검증 대상은 노트 섹션 와이어링 — 마스트헤드 폭은 별도 이슈.
      await tester.binding.setSurfaceSize(const Size(440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repertoire = makeRepertoire(sections: [makeSection()]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('student-1'),
            studentRepertoiresProvider(
              'student-1',
            ).overrideWith((_) async => [repertoire]),
            repertoiresForDateProvider(
              RepertoiresForDateParams(
                studentId: 'student-1',
                date: DateTime.now(),
              ),
            ).overrideWith((_) async => [repertoire]),
            sectionNotesProvider(
              'section-1',
            ).overrideWith((_) async => <PracticeNote>[]),
          ],
          child: const MaterialApp(home: Scaffold(body: StudentPracticeTab())),
        ),
      );
      // Use pump (not pumpAndSettle) because CompactWeekStrip kicks animations.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('header has 노트 추가 action button', (tester) async {
      // 440x900: 사전 존재(pre-existing) masthead 27px 오버플로 회피용.
      // 본 테스트의 검증 대상은 노트 섹션 와이어링 — 마스트헤드 폭은 별도 이슈.
      await tester.binding.setSurfaceSize(const Size(440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('student-1'),
            studentRepertoiresProvider(
              'student-1',
            ).overrideWith((_) async => const <PracticeRepertoire>[]),
            repertoiresForDateProvider(
              RepertoiresForDateParams(
                studentId: 'student-1',
                date: DateTime.now(),
              ),
            ).overrideWith((_) async => const <PracticeRepertoire>[]),
          ],
          child: const MaterialApp(home: Scaffold(body: StudentPracticeTab())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip(AppStrings.practiceNoteAddTooltip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows notes section title when visible sections exist', (
      tester,
    ) async {
      // 440x900: 사전 존재(pre-existing) masthead 27px 오버플로 회피용.
      // 본 테스트의 검증 대상은 노트 섹션 와이어링 — 마스트헤드 폭은 별도 이슈.
      await tester.binding.setSurfaceSize(const Size(440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final note = PracticeNote(
        id: 'n-1',
        sectionId: 'section-1',
        content: '비브라토 천천히',
        createdAt: DateTime.now(),
      );
      final repertoire = makeRepertoire(sections: [makeSection()]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('student-1'),
            studentRepertoiresProvider(
              'student-1',
            ).overrideWith((_) async => [repertoire]),
            repertoiresForDateProvider(
              RepertoiresForDateParams(
                studentId: 'student-1',
                date: DateTime.now(),
              ),
            ).overrideWith((_) async => [repertoire]),
            sectionNotesProvider('section-1').overrideWith((_) async => [note]),
          ],
          child: const MaterialApp(home: Scaffold(body: StudentPracticeTab())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Notes section header label is visible.
      expect(find.text(AppStrings.practiceNoteSectionTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
