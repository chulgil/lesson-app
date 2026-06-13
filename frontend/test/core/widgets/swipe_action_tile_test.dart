// 2026-06-12 — SwipeActionTile 방향 정책 회귀 테스트 (사용자 요구 반영).
//
// 방향 정책 (4원칙):
//   - 오른쪽→왼쪽 스와이프 = 삭제·편집 등 관리 액션 (actions, 오른쪽 노출)
//   - 왼쪽→오른쪽 스와이프 = 편의 기능 (startActions, 왼쪽 노출 — 선택)
//   - startActions 없으면 좌→우는 닫기만 수행
//
// SSOT: docs/_components/swipe_action.md §방향 정책
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';

void main() {
  Widget harness({
    required List<SwipeAction> actions,
    List<SwipeAction> startActions = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: SwipeActionTile(
            actions: actions,
            startActions: startActions,
            child: const SizedBox(
              height: 56,
              child: Center(child: Text('row-content')),
            ),
          ),
        ),
      ),
    );
  }

  SwipeAction deleteAction(VoidCallback onPressed) => SwipeAction(
    label: '삭제',
    icon: Icons.delete_outline,
    tone: SwipeActionTone.destructive,
    onPressed: onPressed,
  );

  SwipeAction shareAction(VoidCallback onPressed) => SwipeAction(
    label: '공유',
    icon: Icons.share_outlined,
    onPressed: onPressed,
  );

  group('SwipeActionTile 방향 정책', () {
    testWidgets('우→좌 스와이프 → 관리 액션(삭제) 노출', (tester) async {
      await tester.pumpWidget(harness(actions: [deleteAction(() {})]));

      await tester.drag(find.text('row-content'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('좌→우 스와이프 — startActions 없으면 아무것도 노출 안 됨', (tester) async {
      await tester.pumpWidget(harness(actions: [deleteAction(() {})]));

      await tester.drag(find.text('row-content'), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('좌→우 스와이프 → 편의 액션(startActions) 노출', (tester) async {
      await tester.pumpWidget(
        harness(
          actions: [deleteAction(() {})],
          startActions: [shareAction(() {})],
        ),
      );

      await tester.drag(find.text('row-content'), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(find.text('공유'), findsOneWidget);
      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('관리 액션 노출 후 좌→우 스와이프 → 닫힘 (편의 패널로 점프 X)', (tester) async {
      await tester.pumpWidget(
        harness(
          actions: [deleteAction(() {})],
          startActions: [shareAction(() {})],
        ),
      );

      await tester.drag(find.text('row-content'), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(find.text('삭제'), findsOneWidget);

      await tester.drag(find.text('row-content'), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(find.text('삭제'), findsNothing);
      expect(find.text('공유'), findsNothing);
    });

    testWidgets('노출된 삭제 버튼 tap → onPressed 호출 + 패널 닫힘', (tester) async {
      var deleted = 0;
      await tester.pumpWidget(
        harness(actions: [deleteAction(() => deleted++)]),
      );

      await tester.drag(find.text('row-content'), const Offset(-200, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(deleted, 1);
      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('convenience tone 버튼 배경 = paperOk(녹색)', (tester) async {
      await tester.pumpWidget(
        harness(
          actions: [deleteAction(() {})],
          startActions: [
            SwipeAction(
              label: '완료',
              icon: Icons.check,
              tone: SwipeActionTone.convenience,
              onPressed: () {},
            ),
          ],
        ),
      );

      await tester.drag(find.text('row-content'), const Offset(200, 0));
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find
            .ancestor(of: find.text('완료'), matching: find.byType(Material))
            .first,
      );
      expect(material.color, AppColors.paperOk);
    });
  });
}
