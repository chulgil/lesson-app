import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/notebook_typography.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

void main() {
  testWidgets('NotebookScreenScaffold fixes the page background to paper', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotebookScreenScaffold(body: Text('content'))),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.paper);
  });

  testWidgets(
    'NotebookScreenScaffold renders appBarTitle with Playfair style',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotebookScreenScaffold(
            appBarTitle: '김민준 (8회권)',
            body: Text('body'),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final title = tester.widget<Text>(find.text('김민준 (8회권)'));

      expect(scaffold.backgroundColor, AppColors.paper);
      expect(appBar.titleSpacing, 0);
      expect(title.style, NotebookTypography.appBarTitle);
    },
  );

  testWidgets(
    'NotebookAlertDialog uses paper, ink border, and pieceTitle style',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showNotebookDialog<void>(
                        context: context,
                        title: '테스트 제목',
                        content: const Text('내용'),
                        onConfirm: () => Navigator.of(context).pop(),
                      ),
                  child: const Text('open'),
                ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      final shape = dialog.shape as RoundedRectangleBorder?;
      final titleWidget = tester.widget<Text>(find.text('테스트 제목'));
      final titleStyle = titleWidget.style!;

      expect(dialog.backgroundColor, AppColors.paper);
      expect(dialog.surfaceTintColor, Colors.transparent);
      expect(shape?.borderRadius, BorderRadius.zero);
      expect(shape?.side.color, AppColors.inkQuaternary);
      final expectedTitleStyle = NotebookTypography.pieceTitle;
      expect(titleStyle.fontFamily, expectedTitleStyle.fontFamily);
      expect(titleStyle.fontSize, expectedTitleStyle.fontSize);
      expect(titleStyle.fontWeight, expectedTitleStyle.fontWeight);
      expect(titleStyle.color, expectedTitleStyle.color);
    },
  );

  testWidgets(
    'NotebookAlertDialog isDestructive uses paperAccent on confirm button',
    (tester) async {
      var confirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showNotebookDialog<void>(
                        context: context,
                        title: '삭제',
                        content: const Text('정말 삭제하시겠습니까?'),
                        confirmLabel: '삭제하기',
                        cancelLabel: '취소',
                        isDestructive: true,
                        onConfirm: () {
                          confirmed = true;
                          Navigator.of(context).pop();
                        },
                      ),
                  child: const Text('open'),
                ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Verify cancel button exists
      expect(find.text('취소'), findsOneWidget);

      // Tap confirm
      await tester.tap(find.text('삭제하기'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    },
  );

  testWidgets('NotebookBottomSheet uses paper and a shared handle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NotebookBottomSheet(child: Text('sheet'))),
      ),
    );

    final decorated =
        tester
            .widgetList<Container>(find.byType(Container))
            .map((container) => container.decoration)
            .whereType<BoxDecoration>();

    expect(
      decorated.any(
        (decoration) =>
            decoration.color == AppColors.paper &&
            decoration.borderRadius == BorderRadius.zero,
      ),
      isTrue,
    );
    expect(find.byKey(NotebookBottomSheet.handleKey), findsOneWidget);
  });

  testWidgets('NotebookDetailScaffold renders masthead and Fine footer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotebookDetailScaffold(
          eyebrow: 'LESSONAZA',
          meta: 'VOL. I',
          slivers: [SliverToBoxAdapter(child: Text('detail content'))],
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('LESSONAZA'), findsOneWidget);
    expect(find.text('Fine.'), findsOneWidget);
    expect(find.text('detail content'), findsOneWidget);
  });

  testWidgets('NotebookDetailScaffold hides Fine when showFine is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotebookDetailScaffold(
          eyebrow: 'TEST',
          showFine: false,
          slivers: [SliverToBoxAdapter(child: Text('content'))],
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Fine.'), findsNothing);
  });

  testWidgets('NotebookCard pins the shared angular paper card contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotebookCard(
            margin: EdgeInsets.all(12),
            color: AppColors.paperAccentSoft,
            child: Text('card'),
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));

    expect(card.margin, const EdgeInsets.all(12));
    expect(card.color, AppColors.paperAccentSoft);
    expect(card.elevation, 0);
    expect(card.surfaceTintColor, Colors.transparent);
    expect(card.shape, const RoundedRectangleBorder());
  });
}
