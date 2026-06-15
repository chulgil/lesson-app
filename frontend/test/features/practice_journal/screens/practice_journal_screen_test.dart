import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/mock_practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/presentation/extensions/journal_tone.dart';
import 'package:lessonaza/features/practice_journal/presentation/providers/practice_journal_provider.dart';
import 'package:lessonaza/features/practice_journal/presentation/screens/practice_journal_screen.dart';

Widget _buildScreen(JournalRole role) {
  return ProviderScope(
    overrides: [
      practiceJournalRepositoryProvider.overrideWithValue(
        MockPracticeJournalRepository(),
      ),
    ],
    child: MaterialApp(
      home: PracticeJournalScreen(childProfileId: 'child_1', role: role),
    ),
  );
}

void main() {
  group('PracticeJournalScreen smoke tests', () {
    testWidgets('student role renders without exception', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.student));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('guardian role renders without exception', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.guardian));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('teacher role renders without exception', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.teacher));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('student role shows 자가 검인 button', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.student));
      await tester.pumpAndSettle();
      expect(find.text('자가 검인'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('guardian role shows 확인 도장 button', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.guardian));
      await tester.pumpAndSettle();
      expect(find.text('확인 도장'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('teacher role shows 선생님 도장 button', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.teacher));
      await tester.pumpAndSettle();
      expect(find.text('선생님 도장'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('child tone renders with 도장판 title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            practiceJournalRepositoryProvider.overrideWithValue(
              MockPracticeJournalRepository(),
            ),
          ],
          child: const MaterialApp(
            home: PracticeJournalScreen(
              childProfileId: 'child_1',
              role: JournalRole.student,
              tone: JournalTone.child,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('도장판'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
