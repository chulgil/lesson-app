import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/home/presentation/widgets/home_quick_action_fab.dart';

void main() {
  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(floatingActionButton: HomeQuickActionFab()),
      ),
    );
  }

  testWidgets('FAB 렌더 — 예외 없음', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('탭 시 퀵액션 시트가 예외 없이 열린다', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
