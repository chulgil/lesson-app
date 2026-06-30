import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/metronome_settings.dart';
import 'package:lessonaza/features/practice/presentation/providers/metronome_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/tuner_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/metronome_panel.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools_modal.dart';

import '../../../../test_helper.dart';

/// #973 — the practice tools modal renders its tab structure (count, labels,
/// panels, settings button) from the injected [musicPracticeTools] list. These
/// tests assert the music shell is byte-identical at desktop + mobile.
///
/// Audio/permission flows are out of scope: metronome + tuner are stubbed
/// (pattern from practice_start_section_sc1_test).

class _NoopMetronome extends Notifier<MetronomeState> implements Metronome {
  @override
  MetronomeState build() => const MetronomeState(isReady: true);

  @override
  Future<void> warmUp() async {}

  @override
  void start() {}

  @override
  void stop({String? studentId, int? practiceMinutesElapsed}) {}

  @override
  void toggle() {}

  @override
  Future<void> setBpm(int bpm) async {}

  @override
  Future<void> incrementBpm(int delta) async {}

  @override
  Future<void> setTimeSignature(TimeSignature timeSignature) async {}

  @override
  Future<void> setSound(MetronomeSound sound) async {}

  @override
  void toggleVisualFlash() {}

  @override
  void toggleVibration() {}

  @override
  Future<void> setAccentPattern(AccentPattern pattern) async {}

  @override
  Future<void> updateSettings(MetronomeSettings settings) async {}

  @override
  Future<void> playTapSound() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopTuner extends Notifier<TunerProviderState> implements Tuner {
  @override
  TunerProviderState build() => const TunerProviderState();

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> enableProcessing() async {}

  @override
  void disableProcessing() {}

  @override
  Future<void> stopCompletely() async {}

  @override
  Future<void> onAppPaused() async {}

  @override
  Future<void> onAppResumed() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeTestEnvironment();
  });

  tearDownAll(() async {
    await cleanupTestEnvironment();
  });

  Future<void> pumpModal(WidgetTester tester, {int initialTab = 0}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metronomeProvider.overrideWith(() => _NoopMetronome()),
          tunerProvider.overrideWith(() => _NoopTuner()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PracticeToolsModal(initialTab: initialTab, studentId: 's1'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  for (final viewport in const [Size(1440, 900), Size(375, 667)]) {
    final label = '${viewport.width.toInt()}x${viewport.height.toInt()}';
    testWidgets('renders 2 music tabs; settings toggles on tuner @ $label', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpModal(tester);

      // Exactly 2 tabs, in music tool order.
      expect(find.text('메트로놈'), findsOneWidget);
      expect(find.text('튜너'), findsOneWidget);
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 2);

      // The modal threads its studentId into the metronome panel — the join the
      // refactor introduced (tool.panelBuilder(context, widget.studentId)).
      expect(
        tester.widget<MetronomePanel>(find.byType(MetronomePanel)).studentId,
        's1',
      );

      // Metronome tab (index 0) has no settings affordance.
      expect(find.byIcon(Icons.settings_outlined), findsNothing);

      // Switching to the tuner tab (index 1) reveals the settings button.
      await tester.tap(find.text('튜너'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opens directly on the tuner tab when initialTab == 1', (
    tester,
  ) async {
    await pumpModal(tester, initialTab: 1);

    // Tuner tab active from the first frame -> settings button shown at once.
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
