import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_note.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_note_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/note/practice_note_card.dart';

void main() {
  group('PracticeNoteCard — §2.4 학생 홈 통합 smoke (#492)', () {
    testWidgets('renders empty state without exceptions when no notes', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sectionNotesProvider(
              'section-1',
            ).overrideWith((_) async => <PracticeNote>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PracticeNoteCard(
                sectionId: 'section-1',
                sectionTitle: 'Canon',
                sectionSubtitle: '1~8마디',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Canon'), findsOneWidget);
      expect(find.text('1~8마디'), findsOneWidget);
      expect(find.text(AppStrings.practiceNoteHomeEmpty), findsOneWidget);
    });

    testWidgets('renders inline notes with content', (tester) async {
      final note = PracticeNote(
        id: 'n-1',
        sectionId: 'section-1',
        content: '비브라토를 조금만 천천히',
        createdAt: DateTime(2026, 6, 4, 10, 30),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sectionNotesProvider('section-1').overrideWith((_) async => [note]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PracticeNoteCard(
                sectionId: 'section-1',
                sectionTitle: 'Canon',
                sectionSubtitle: '1~8마디',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('비브라토를 조금만 천천히'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
    });

    testWidgets('shows 전체보기 link when notes exceed maxInlineNotes', (
      tester,
    ) async {
      final notes = List.generate(
        4,
        (i) => PracticeNote(
          id: 'n-$i',
          sectionId: 'section-1',
          content: '노트 $i',
          createdAt: DateTime(2026, 6, 4, 10 + i, 0),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sectionNotesProvider('section-1').overrideWith((_) async => notes),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PracticeNoteCard(
                sectionId: 'section-1',
                sectionTitle: 'Canon',
                maxInlineNotes: 3,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.practiceNoteShowMore), findsOneWidget);
    });

    testWidgets('header add button is present with accessible tooltip', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sectionNotesProvider(
              'section-1',
            ).overrideWith((_) async => <PracticeNote>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PracticeNoteCard(
                sectionId: 'section-1',
                sectionTitle: 'Canon',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip(AppStrings.practiceNoteAddTooltip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inside a narrow Row without BoxConstraints crash', (
      tester,
    ) async {
      // RenderBox layout regression guard (CLAUDE.md HARD-GATE).
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sectionNotesProvider(
              'section-1',
            ).overrideWith((_) async => <PracticeNote>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: Row(
                  children: [
                    Expanded(
                      child: PracticeNoteCard(
                        sectionId: 'section-1',
                        sectionTitle: 'Canon',
                        sectionSubtitle: '1~8마디',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
