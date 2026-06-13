import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_banner.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pumpAndSettle();
}

void main() {
  group('NotebookBanner', () {
    testWidgets('기본 렌더 — 메시지 표시, render exception 0', (tester) async {
      await _pump(tester, const NotebookBanner(message: '오늘은 비 오는 화요일이에요'));
      expect(find.text('오늘은 비 오는 화요일이에요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leadingIcon + trailing 동시 렌더', (tester) async {
      await _pump(
        tester,
        NotebookBanner(
          message: '다음 레슨까지 30분',
          leadingIcon: Icons.schedule,
          trailing: IconButton(icon: const Icon(Icons.close), onPressed: () {}),
        ),
      );
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('다음 레슨까지 30분'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accent 색 override 적용 (좌측 세로선)', (tester) async {
      await _pump(
        tester,
        const NotebookBanner(message: '체험레슨 안내', accent: AppColors.paperTrial),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NotebookBanner),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.left.color, AppColors.paperTrial);
      expect(border.left.width, 3);
    });

    testWidgets('레이아웃 회귀 — 좁은 Column 제약에서 BoxConstraints 크래시 없음', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 120,
          child: Column(
            children: [
              NotebookBanner(
                message: '아주 긴 손글씨 메시지가 좁은 폭에서 잘리지 않고 줄바꿈되는지 확인',
                leadingIcon: Icons.wb_sunny_outlined,
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
