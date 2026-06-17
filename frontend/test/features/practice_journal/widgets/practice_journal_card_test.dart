import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/mock_practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/presentation/providers/practice_journal_provider.dart';
import 'package:lessonaza/features/practice_journal/presentation/screens/practice_journal_screen.dart';
import 'package:lessonaza/features/practice_journal/presentation/widgets/practice_journal_card.dart';

Widget _buildCard({
  required VoidCallback onTap,
  JournalRole role = JournalRole.student,
}) {
  return ProviderScope(
    overrides: [
      practiceJournalRepositoryProvider.overrideWithValue(
        MockPracticeJournalRepository(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: PracticeJournalCard(
          childProfileId: 'child_1',
          role: role,
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  group('PracticeJournalCard', () {
    testWidgets('renders without exception (student)', (tester) async {
      await tester.pumpWidget(_buildCard(onTap: () {}));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception (guardian)', (tester) async {
      await tester.pumpWidget(
        _buildCard(onTap: () {}, role: JournalRole.guardian),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception (teacher)', (tester) async {
      await tester.pumpWidget(
        _buildCard(onTap: () {}, role: JournalRole.teacher),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap fires onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_buildCard(onTap: () => tapped = true));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PracticeJournalCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception at narrow width (375px)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_buildCard(onTap: () {}));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows actor summary row with glyph chips', (tester) async {
      await tester.pumpWidget(_buildCard(onTap: () {}));
      await tester.pumpAndSettle();
      // Actor chips are rendered via Semantics labels
      expect(find.bySemanticsLabel(RegExp(r'학생 \d')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'보호자 \d')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'선생님 \d')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
