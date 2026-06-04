// Widget smoke tests for BadgeCollection.

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/services/badge_checker.dart';
import 'package:lessonaza/features/practice/presentation/providers/badge_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/badge/badge_collection.dart';

void main() {
  group('BadgeCollection smoke', () {
    testWidgets('renders all 17 badges with locked state by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BadgeCollection(studentId: 's1'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('뱃지 컬렉션'), findsOneWidget);
      expect(find.text('0 / 17'), findsOneWidget);
      // Category labels (all four).
      expect(find.text('꾸준함'), findsOneWidget);
      expect(find.text('성실함'), findsOneWidget);
      expect(find.text('도전'), findsOneWidget);
      expect(find.text('특별'), findsOneWidget);
    });

    testWidgets('reflects earned count when badges are granted', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Pre-grant via the notifier.
      container
          .read(practiceBadgeStateNotifierProvider('s1').notifier)
          .evaluate(
            stats: const PracticeStatsSnapshot(
              totalPracticeCount: 1,
              currentStreakDays: 3,
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BadgeCollection(studentId: 's1'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // firstPractice + streak3 awarded → 2/17.
      expect(find.text('2 / 17'), findsOneWidget);
    });

    testWidgets('renders inside narrow viewport without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BadgeCollection(studentId: 's_narrow'),
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
