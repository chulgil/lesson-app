// Widget smoke tests for BadgePopup.

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/badge.dart';
import 'package:lessonaza/features/practice/presentation/widgets/badge/badge_popup.dart';

void main() {
  group('BadgePopup smoke', () {
    testWidgets('renders name + description + confirm button', (tester) async {
      final badge = Badge.earned(
        BadgeType.firstPractice,
        at: DateTime(2026, 6, 4),
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BadgePopup(badge: badge))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('첫 연습'), findsOneWidget);
      expect(find.text('첫 연습을 완료했어요'), findsOneWidget);
      expect(find.text('새 뱃지 획득!'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('renders streak badge with proper labels', (tester) async {
      final badge = Badge.earned(BadgeType.streak7);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BadgePopup(badge: badge))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('7일 연속'), findsOneWidget);
      expect(find.text('7일 연속 연습 달성'), findsOneWidget);
    });

    testWidgets('confirm button invokes onDismiss callback', (tester) async {
      var dismissed = false;
      final badge = Badge.earned(BadgeType.firstPiece);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgePopup(badge: badge, onDismiss: () => dismissed = true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('확인'));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('renders inside narrow viewport without layout overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final badge = Badge.earned(BadgeType.streak100);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BadgePopup(badge: badge))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
