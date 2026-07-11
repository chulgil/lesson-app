import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/widgets/empty_state_widget.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/fitness_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/music_practice_tools.dart';

/// #979-B — fitness (헬스 / GX) skeleton practice tools. Data-only registration:
/// the tools render their identity but carry no sensor / camera / IMU / BPM
/// logic. None collides with the music tool ids the modal gates on.
void main() {
  group('fitnessPracticeTools', () {
    test('registers 3 skeleton tools in order (rep / interval / guide)', () {
      expect(fitnessPracticeTools.map((t) => t.id).toList(), [
        FitnessPracticeToolIds.repCounter,
        FitnessPracticeToolIds.intervalTimer,
        FitnessPracticeToolIds.guideMedia,
      ]);
    });

    test('tab labels come from AppStrings', () {
      expect(
        fitnessPracticeTools[0].displayLabel,
        AppStrings.practiceToolRepCounter,
      );
      expect(
        fitnessPracticeTools[1].displayLabel,
        AppStrings.practiceToolIntervalTimer,
      );
      expect(
        fitnessPracticeTools[2].displayLabel,
        AppStrings.practiceToolGuideMedia,
      );
    });

    test('no tool exposes a tuner or metronome (mic + engine gates hold)', () {
      final ids = fitnessPracticeTools.map((t) => t.id).toSet();
      // Must not collide with the music tool ids the modal lifecycle gates on.
      expect(ids.contains(PracticeToolIds.tuner), isFalse);
      expect(ids.contains(PracticeToolIds.metronome), isFalse);
    });

    test('skeleton tools carry no settings affordance', () {
      for (final tool in fitnessPracticeTools) {
        expect(tool.onShowSettings, isNull, reason: tool.id);
      }
    });
  });

  testWidgets('each skeleton panel renders an EmptyStateWidget placeholder', (
    tester,
  ) async {
    for (final tool in fitnessPracticeTools) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (c) => tool.panelBuilder(c, null, null)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(
        find.text(AppStrings.practiceToolSkeletonSubtitle),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
