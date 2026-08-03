import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/audio/mock_tuner_engine.dart';
import 'package:lessonaza/core/audio/signal_gauge_tool.dart';
import 'package:lessonaza/core/audio/tuner_engine.dart';

/// A minimal [SignalGaugeTool] proving the neutral contract is satisfiable with
/// NO tuner-specific members (no frequency / note / cents / judgement), and that
/// the inherited concrete [SignalGaugeTool.toggle] works without an override.
/// This is the seam: a fitness form-gauge (Phase 4+) can register the same slot
/// type. (Deliberately does NOT override toggle — see the toggle test.)
class _FakeSignalGauge extends SignalGaugeTool {
  bool _listening = false;

  @override
  bool get isListening => _listening;
  @override
  Future<void> start() async => _listening = true;
  @override
  Future<void> stop() async => _listening = false;
  @override
  void dispose() {}
}

void main() {
  group('SignalGaugeTool (#978)', () {
    test('neutral contract is satisfiable without tuner-specific members', () {
      final gauge = _FakeSignalGauge();
      expect(gauge.isListening, isFalse);
    });

    test('lifecycle toggles active state through the neutral interface', () async {
      final SignalGaugeTool gauge = _FakeSignalGauge();
      await gauge.start();
      expect(gauge.isListening, isTrue);
      await gauge.stop();
      expect(gauge.isListening, isFalse);
    });

    test('inherited (default) toggle flips the active state — no override', () async {
      // _FakeSignalGauge does NOT override toggle, so this exercises the
      // concrete SignalGaugeTool.toggle inherited from the supertype.
      final SignalGaugeTool gauge = _FakeSignalGauge();
      await gauge.toggle();
      expect(gauge.isListening, isTrue);
      await gauge.toggle();
      expect(gauge.isListening, isFalse);
    });

    test('the neutral contract drives the real music tuner (discipline 0)', () async {
      // The seam: the music tuner IS a discipline-neutral signal gauge, and the
      // whole lifecycle can be driven through a SignalGaugeTool reference — so a
      // fitness gauge (Phase 4+) can register and be driven via the same type.
      final SignalGaugeTool gauge = MockTunerEngine();
      expect(gauge, isA<TunerEngine>()); // it really is the music tuner
      expect(gauge.isListening, isFalse);
      await gauge.start();
      expect(gauge.isListening, isTrue);
      await gauge.toggle(); // listening → stop, via the neutral interface
      expect(gauge.isListening, isFalse);
      await gauge.stop();
      expect(gauge.isListening, isFalse);
      gauge.dispose();
    });
  });
}
