// Smoke + behavior tests for PracticeRepertoireScreen / _RepertoireCard.
//
// Covers swipe consistency audit (2026-06-10 §2 — practice v2 D2):
// - PopupMenuButton 이 제거되었는지
// - SwipeActionTile 로 destructive [보관] 액션이 노출되는지
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import 'package:lessonaza/features/practice/presentation/screens/practice_repertoire_screen.dart';

void main() {
  PracticeRepertoire makeRepertoire() {
    final now = DateTime(2026, 5, 7);
    return PracticeRepertoire(
      id: 'rep-1',
      studentId: 'student-1',
      name: 'Canon',
      startDate: now,
      sections: const [],
      createdAt: now,
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentRepertoiresProvider(
            'student-1',
          ).overrideWith((_) async => [makeRepertoire()]),
        ],
        child: const MaterialApp(
          home: PracticeRepertoireScreen(studentId: 'student-1'),
        ),
      ),
    );
    // SwipeActionTile AnimatedContainer 가 settle 못 하는 경우가 있어 명시 pump 만.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders without runtime crash', (tester) async {
    await pumpScreen(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not render PopupMenuButton (swipe consistency D2)', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(
      find.byType(PopupMenuButton<String>),
      findsNothing,
      reason: '_RepertoireCard 의 PopupMenuButton 은 SwipeActionTile 로 대체되어야 한다.',
    );
  });

  testWidgets('renders SwipeActionTile for repertoire card', (tester) async {
    await pumpScreen(tester);
    expect(
      find.byType(SwipeActionTile),
      findsWidgets,
      reason: '_RepertoireCard 는 SwipeActionTile 로 래핑되어야 한다.',
    );
  });
}
