import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/metronome_panel.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/music_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/tuner_panel.dart';

/// #973 — the music practice-tool set that drives the practice tools modal.
/// These assertions pin the data so the modal stays byte-identical to its
/// previous hardcoded `[메트로놈, 튜너]` tabs.
void main() {
  group('musicPracticeTools (#973)', () {
    test('is metronome then tuner, in tab order', () {
      expect(musicPracticeTools.map((t) => t.id).toList(), [
        PracticeToolIds.metronome,
        PracticeToolIds.tuner,
      ]);
    });

    test('tab labels are 메트로놈 / 튜너 (verbatim from the old modal)', () {
      expect(musicPracticeTools.map((t) => t.displayLabel).toList(), [
        '메트로놈',
        '튜너',
      ]);
    });

    test('only the tuner exposes a settings affordance', () {
      expect(musicPracticeTools[0].onShowSettings, isNull);
      expect(musicPracticeTools[1].onShowSettings, isNotNull);
    });

    testWidgets('panelBuilder builds the right panel and threads studentId', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      );

      final metronome =
          musicPracticeTools[0].panelBuilder(ctx, 's1', 'sec1')
              as MetronomePanel;
      expect(metronome.studentId, 's1');
      // sectionId 도 함께 스레딩된다 (선택적 곡 연결, practice_master §1.2).
      expect(metronome.sectionId, 'sec1');

      final tuner = musicPracticeTools[1].panelBuilder(ctx, 's1', null);
      expect(tuner, isA<TunerPanel>());

      // A null studentId (non-student entry point) is forwarded as-is.
      final nullStudent =
          musicPracticeTools[0].panelBuilder(ctx, null, null) as MetronomePanel;
      expect(nullStudent.studentId, isNull);
      expect(nullStudent.sectionId, isNull);
    });
  });
}
