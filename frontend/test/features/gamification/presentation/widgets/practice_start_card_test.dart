import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/practice_start_card.dart';

Future<void> _pump(
  WidgetTester tester, {
  String name = '민지',
  int streakDays = 3,
  int yesterdayMinutes = 25,
  VoidCallback? onStart,
  VoidCallback? onMore,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PracticeStartCard(
          studentName: name,
          streakDays: streakDays,
          yesterdayMinutes: yesterdayMinutes,
          onStartTap: onStart ?? () {},
          onMoreTap: onMore,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders header / streak / button / yesterday', (tester) async {
    await _pump(tester);
    expect(
      find.byKey(const ValueKey('practice_start_card_header')),
      findsOneWidget,
    );
    expect(find.text('민지의 연습'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('practice_start_card_streak')),
      findsOneWidget,
    );
    expect(find.text('3일'), findsOneWidget);
    expect(find.byKey(const ValueKey('practice_start_button')), findsOneWidget);
    expect(find.text('연습 시작'), findsOneWidget);
    expect(find.text('어제 25분 했어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping start button invokes onStartTap exactly once', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, onStart: () => taps++);
    await tester.tap(find.byKey(const ValueKey('practice_start_button')));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('more button hidden when onMoreTap is null', (tester) async {
    await _pump(tester);
    expect(
      find.byKey(const ValueKey('practice_start_card_more')),
      findsNothing,
    );
  });

  testWidgets('more button shown and tappable when onMoreTap provided', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, onMore: () => taps++);
    expect(
      find.byKey(const ValueKey('practice_start_card_more')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('practice_start_card_more')));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('renders without overflow on narrow viewport (mobile 375x667)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375 * 3, 667 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    await _pump(
      tester,
      name: '아주아주긴이름입니다',
      streakDays: 999,
      yesterdayMinutes: 9999,
    );
    expect(tester.takeException(), isNull);
  });
}
