import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/metronome_settings.dart';
import 'package:lessonaza/features/practice/presentation/providers/metronome_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/tuner_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/fitness_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/metronome_panel.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/practice_tool.dart';
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
  void stop({
    String? studentId,
    int? practiceMinutesElapsed,
    String? sectionId,
  }) {}

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

/// A tuner that throws if any member is accessed — proves the modal never reads
/// the tuner when the active discipline has no tuner tool (#979-A mic gate).
class _ThrowingTuner extends Notifier<TunerProviderState> implements Tuner {
  @override
  TunerProviderState build() => const TunerProviderState();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError(
        'tunerProvider touched for a non-tuner tool set: ${invocation.memberName}',
      );
}

/// A metronome that throws if any member is accessed — proves the modal never
/// warms the metronome when the active discipline has no metronome tool
/// (#979-B metronome gate).
class _ThrowingMetronome extends Notifier<MetronomeState> implements Metronome {
  @override
  MetronomeState build() => const MetronomeState(isReady: true);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError(
        'metronomeProvider touched for a metronome-less tool set: '
        '${invocation.memberName}',
      );
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
    testWidgets('renders 3 music tabs; settings toggles on tuner @ $label', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpModal(tester);

      // Exactly 3 tabs, in music tool order (metronome, tuner, 녹음 — #973 +
      // 녹음 launch tab wired to the quick-record route).
      expect(find.text('메트로놈'), findsOneWidget);
      expect(find.text('튜너'), findsOneWidget);
      expect(find.text(AppStrings.practiceRecordingTitle), findsOneWidget);
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 3);

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

  testWidgets(
    'a discipline without a tuner never touches the tuner (mic gate)',
    (tester) async {
      // Two non-tuner tools (fitness-readiness): _tunerIndex == -1, so tab
      // changes, lifecycle and teardown must never read tunerProvider. The
      // metronome warm-up is not gated in #979-A, so it stays stubbed.
      final tools = <PracticeTool>[
        PracticeTool(
          id: 'a',
          displayLabel: 'A',
          panelBuilder: (_, __, ___) => const SizedBox(),
        ),
        PracticeTool(
          id: 'b',
          displayLabel: 'B',
          panelBuilder: (_, __, ___) => const SizedBox(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metronomeProvider.overrideWith(() => _NoopMetronome()),
            tunerProvider.overrideWith(() => _ThrowingTuner()),
          ],
          child: MaterialApp(
            home: Scaffold(body: PracticeToolsModal(tools: tools)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Two non-tuner tabs, no settings affordance.
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);

      // Switching tabs fires _onTabChanged, which must skip the tuner.
      await tester.tap(find.text('B'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // App lifecycle changes fire didChangeAppLifecycleState, which must also
      // skip the tuner (guards Phase 4 / #979-B tuner-less disciplines).
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Tearing the modal down runs deactivate, which must also skip the tuner.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fitness tool set: 3 tabs (real ids), warms neither metronome nor tuner (#979-B gates)',
    (tester) async {
      // The real fitness tool ids/labels/count drive the modal gate logic —
      // _metronomeIndex and _tunerIndex both resolve to -1. Panels are stubbed
      // so the render stays free of the EmptyStateWidget google_fonts fetch
      // (the real skeleton panels are covered by fitness_practice_tools_test).
      // Throwing stubs prove the modal reads neither provider across init, tab
      // switch, lifecycle and teardown (red-green: drop the metronome gate and
      // the init microtask warmUp throws; drop the tuner gate and the tab
      // switch / lifecycle / deactivate throws).
      final tools = [
        for (final tool in fitnessPracticeTools)
          PracticeTool(
            id: tool.id,
            displayLabel: tool.displayLabel,
            panelBuilder: (_, __, ___) => const SizedBox(),
          ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metronomeProvider.overrideWith(() => _ThrowingMetronome()),
            tunerProvider.overrideWith(() => _ThrowingTuner()),
          ],
          child: MaterialApp(
            home: Scaffold(body: PracticeToolsModal(tools: tools)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Three fitness tabs, in tool order; no settings affordance (skeletons).
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 3);
      expect(find.text(fitnessPracticeTools[0].displayLabel), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);

      // Switching tabs fires _onTabChanged, which must skip the absent tuner.
      await tester.tap(find.text(fitnessPracticeTools[1].displayLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // App lifecycle + teardown must also skip the absent tuner.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}
