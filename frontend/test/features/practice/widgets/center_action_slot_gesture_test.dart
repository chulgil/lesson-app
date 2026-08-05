// #975 CenterActionSlot — gesture-forwarding regression.
//
// A StatelessWidget passthrough cannot intercept pointer events, but the
// explicit "zero behavioral regression" claim deserves an exercised proof:
// tapping / long-pressing the center button THROUGH the slot must still open
// the practice tools modal on the correct tab (#932 routing, #973 tabs).
//
// Audio/permission flows are out of scope: metronome + tuner are stubbed
// (noop pattern from practice_tools_modal_injection_test).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/widgets/center_action_slot.dart';
import 'package:lessonaza/core/widgets/practice_center_button.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/practice/domain/entities/metronome_settings.dart';
import 'package:lessonaza/features/practice/presentation/providers/metronome_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/tuner_provider.dart';

import '../../../test_helper.dart';

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

void main() {
  setUpAll(() async {
    await initializeTestEnvironment();
  });

  tearDownAll(() async {
    await cleanupTestEnvironment();
  });

  Future<void> pumpButtonInSlot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('s1'),
          metronomeProvider.overrideWith(() => _NoopMetronome()),
          tunerProvider.overrideWith(() => _NoopTuner()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CenterActionSlot(
                centerAction: PracticeCenterButton(size: 48),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CenterActionSlot gesture forwarding (#975)', () {
    testWidgets('tap through the slot opens the modal on the metronome tab', (
      tester,
    ) async {
      await pumpButtonInSlot(tester);

      await tester.tap(find.byType(PracticeCenterButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Modal opened → the tap reached the button through the slot.
      expect(find.text('메트로놈'), findsOneWidget);
      expect(find.text('튜너'), findsOneWidget);
      // initialTab 0 = metronome → no settings affordance (#973).
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'long-press through the slot opens the modal on the tuner tab',
      (tester) async {
        await pumpButtonInSlot(tester);

        await tester.longPress(find.byType(PracticeCenterButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('메트로놈'), findsOneWidget);
        expect(find.text('튜너'), findsOneWidget);
        // initialTab 1 = tuner → settings affordance visible (#973).
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
