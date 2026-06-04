import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/loop_memo.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/loop_memo_overlay.dart';

void main() {
  group('LoopMemoOverlay — #510', () {
    testWidgets('renders without exceptions when no memos are present', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 180,
              child: LoopMemoOverlay(
                memos: const [],
                currentPositionSeconds: 0,
                onAdd: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.loopMemoAdd), findsOneWidget);
    });

    testWidgets('surfaces a memo when playback enters the visibility window', (
      tester,
    ) async {
      final memo = LoopMemo(
        id: 'm1',
        atSeconds: 30,
        text: '여기 보잉 주의',
        createdAt: DateTime(2026, 6, 4),
      );
      Widget overlayAt(int seconds) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 180,
            child: LoopMemoOverlay(
              memos: [memo],
              currentPositionSeconds: seconds,
            ),
          ),
        ),
      );

      // Before the memo's atSeconds — not visible.
      await tester.pumpWidget(overlayAt(20));
      await tester.pump();
      expect(find.text('여기 보잉 주의'), findsNothing);

      // Within the 3-second window — visible.
      await tester.pumpWidget(overlayAt(30));
      await tester.pump();
      await tester.pump();
      expect(find.text('여기 보잉 주의'), findsOneWidget);

      // After the window — no longer visible.
      await tester.pumpWidget(overlayAt(40));
      await tester.pump();
      await tester.pump();
      expect(find.text('여기 보잉 주의'), findsNothing);
    });

    testWidgets('shows at most one memo at a time (overlap)', (tester) async {
      final m1 = LoopMemo(
        id: 'm1',
        atSeconds: 10,
        text: '메모1',
        createdAt: DateTime(2026, 6, 4),
      );
      final m2 = LoopMemo(
        id: 'm2',
        atSeconds: 11,
        text: '메모2',
        createdAt: DateTime(2026, 6, 4),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 180,
              child: LoopMemoOverlay(
                memos: [m1, m2],
                currentPositionSeconds: 11,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      // Either memo qualifies; UI must surface exactly one.
      final foundFirst = find.text('메모1').evaluate().length;
      final foundSecond = find.text('메모2').evaluate().length;
      expect(foundFirst + foundSecond, 1);
    });

    testWidgets('add button opens editor sheet with input and save action', (
      tester,
    ) async {
      String? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 180,
              child: LoopMemoOverlay(
                memos: const [],
                currentPositionSeconds: 0,
                onAdd: (text) async => saved = text,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(AppStrings.loopMemoAdd));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '새 메모');
      await tester.tap(find.text(AppStrings.loopMemoSave));
      await tester.pumpAndSettle();

      expect(saved, '새 메모');
    });
  });
}
