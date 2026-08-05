import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/journey_sticker.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/journey_sticker_section.dart';

JourneySticker _sticker({
  required String key,
  StickerFamily family = StickerFamily.practice,
  String metric = 'practice_minutes',
  int tier = 1,
  required int target,
  required int current,
  StickerUnit unit = StickerUnit.count,
}) => JourneySticker(
  key: key,
  family: family,
  metric: metric,
  tier: tier,
  target: target,
  current: current,
  achieved: current >= target,
  unit: unit,
);

Future<void> _pump(
  WidgetTester tester, {
  required List<JourneySticker> stickers,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: JourneyStickerSection(
          catalog: JourneyStickerCatalog(
            studentId: 'student-1',
            stickers: stickers,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('JourneyStickerSection — P3b 여정 스티커', () {
    testWidgets('widget smoke test — render exception 0 (HARD-GATE)', (
      tester,
    ) async {
      await _pump(
        tester,
        stickers: [
          _sticker(key: 'practice_minutes_10h', target: 600, current: 300),
          _sticker(
            key: 'streak_7',
            family: StickerFamily.streak,
            metric: 'streak_days',
            target: 7,
            current: 3,
            unit: StickerUnit.days,
          ),
        ],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty catalog → renders nothing (SizedBox.shrink)', (
      tester,
    ) async {
      await _pump(tester, stickers: const []);
      expect(
        find.byKey(const ValueKey('journey_sticker_section')),
        findsNothing,
      );
    });

    testWidgets('locked sticker (current < target) → dashed tile, no fill', (
      tester,
    ) async {
      await _pump(
        tester,
        stickers: [_sticker(key: 'journey_bound_1', target: 1, current: 0)],
      );

      expect(
        find.byKey(const ValueKey('journey_sticker_tile_journey_bound_1')),
        findsOneWidget,
      );
      expect(find.text('0/1개'), findsOneWidget);
    });

    testWidgets('unlocked sticker (current >= target) → achieved label', (
      tester,
    ) async {
      await _pump(
        tester,
        stickers: [_sticker(key: 'journey_bound_1', target: 1, current: 1)],
      );

      expect(
        find.byKey(const ValueKey('journey_sticker_tile_journey_bound_1')),
        findsOneWidget,
      );
      expect(find.text('1/1개'), findsOneWidget);
    });

    testWidgets('progress state — minutes unit renders hour-formatted label', (
      tester,
    ) async {
      await _pump(
        tester,
        stickers: [
          _sticker(
            key: 'practice_minutes_10h',
            target: 600,
            current: 300,
            unit: StickerUnit.minutes,
          ),
        ],
      );

      expect(find.text('5/10h'), findsOneWidget);
    });

    testWidgets('progress state — days unit renders day-formatted label', (
      tester,
    ) async {
      await _pump(
        tester,
        stickers: [
          _sticker(
            key: 'practice_days_30',
            metric: 'practice_days',
            target: 30,
            current: 18,
            unit: StickerUnit.days,
          ),
        ],
      );

      expect(find.text('18/30일'), findsOneWidget);
    });

    testWidgets('groups stickers by family with a Korean section header', (
      tester,
    ) async {
      await _pump(
        tester,
        stickers: [
          _sticker(key: 'practice_minutes_10h', target: 600, current: 600),
          _sticker(
            key: 'growth_recordings_10',
            family: StickerFamily.growth,
            metric: 'growth_recordings',
            target: 10,
            current: 2,
          ),
        ],
      );

      expect(find.text('여정 스티커'), findsOneWidget);
      expect(find.text('연습'), findsOneWidget);
      expect(find.text('성장'), findsOneWidget);
      expect(find.text('(1/1)'), findsOneWidget);
      expect(find.text('(0/1)'), findsOneWidget);
    });
  });
}
