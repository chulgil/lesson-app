// Widget smoke test (HARD-GATE) for PieceCard.
//
// Asserts the swipe consistency followup audit #668 D4 — the legacy
// PopupMenuButton has been replaced by SwipeActionTile + tap-to-open
// PieceActionsBottomSheet, and the card renders without runtime crashes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/practice/domain/entities/piece.dart';
import 'package:lessonaza/features/profile/presentation/widgets/repertoire_management_widgets.dart';

void main() {
  final piece = Piece(
    id: 'p-1',
    title: '봄의 소리 왈츠',
    composer: 'J. Strauss II',
    opus: 'Op. 410',
    difficulty: '중급',
    createdAt: DateTime(2026, 1, 1),
  );

  testWidgets('PieceCard renders without crash and exposes no PopupMenu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PieceCard(
            piece: piece,
            onEdit: () {},
            onDelete: () {},
            onAssign: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // PopupMenuButton removed in favor of SwipeActionTile + BottomSheet.
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    // Card content still renders.
    expect(find.text(piece.title), findsOneWidget);
  });

  testWidgets('tapping PieceCard opens action bottom sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PieceCard(
            piece: piece,
            onEdit: () {},
            onDelete: () {},
            onAssign: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text(piece.title));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.pieceActionsSheetTitle), findsOneWidget);
    expect(find.text(AppStrings.pieceActionsEdit), findsOneWidget);
    expect(find.text(AppStrings.pieceActionsAssign), findsOneWidget);
    expect(find.text(AppStrings.swipeActionDelete), findsOneWidget);
  });
}
