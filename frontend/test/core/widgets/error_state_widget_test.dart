import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/widgets/error_state_widget.dart';

void main() {
  group('ErrorStateWidget', () {
    testWidgets('renders without exceptions with minimal fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorStateWidget(title: '데이터를 불러올 수 없습니다')),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('데이터를 불러올 수 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders subtitle and retry action when provided', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              icon: Icons.search_off,
              title: '찾을 수 없습니다',
              subtitle: '삭제되었거나 존재하지 않는 항목입니다',
              actionLabel: '다시 시도',
              actionIcon: Icons.refresh,
              onAction: () => retried = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('찾을 수 없습니다'), findsOneWidget);
      expect(find.text('삭제되었거나 존재하지 않는 항목입니다'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    // Row/Column constrained layout regression (narrow width — swipe/compact
    // context per ux-rules.md "레이아웃 크래시 방지").
    testWidgets('renders without overflow in a narrow constrained width', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: ErrorStateWidget(
                title: '데이터를 불러올 수 없습니다',
                actionLabel: '다시 시도',
                actionIcon: Icons.refresh,
                onAction: () {},
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
