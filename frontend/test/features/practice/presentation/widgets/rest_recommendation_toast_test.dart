import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/services/rest_recommendation_policy.dart';
import 'package:lessonaza/features/practice/presentation/widgets/rest_recommendation_toast.dart';

Future<void> _pump(
  WidgetTester tester, {
  required RestRecommendationKind kind,
  VoidCallback? onDismiss,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RestRecommendationToast(
          kind: kind,
          onDismiss: onDismiss ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('RestRecommendationToast — Job 8 Task 8.2 / AC-7', () {
    testWidgets('widget smoke test (HARD-GATE) — render exception 0', (
      tester,
    ) async {
      await _pump(tester, kind: RestRecommendationKind.session30);
      expect(tester.takeException(), isNull);
    });

    testWidgets('session30 → "잠깐 쉬는 게 어때요?" 메시지', (tester) async {
      await _pump(tester, kind: RestRecommendationKind.session30);
      expect(find.text('잠깐 쉬는 게 어때요?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('rest_recommendation_toast')),
        findsOneWidget,
      );
    });

    testWidgets('daily180 → "오늘은 충분히 했어요" 메시지', (tester) async {
      await _pump(tester, kind: RestRecommendationKind.daily180);
      expect(find.text('오늘은 충분히 했어요'), findsOneWidget);
    });

    testWidgets('none → render exception 0 (defensive)', (tester) async {
      await _pump(tester, kind: RestRecommendationKind.none);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dismiss 버튼 tap → onDismiss callback 호출', (tester) async {
      var dismissed = 0;
      await _pump(
        tester,
        kind: RestRecommendationKind.session30,
        onDismiss: () => dismissed++,
      );

      await tester.tap(
        find.byKey(const ValueKey('rest_recommendation_dismiss')),
      );
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('계속하기 버튼 라벨 존재 — 강제 X (옵트아웃)', (tester) async {
      await _pump(tester, kind: RestRecommendationKind.session30);
      expect(find.text('계속하기'), findsOneWidget);
    });
  });
}
