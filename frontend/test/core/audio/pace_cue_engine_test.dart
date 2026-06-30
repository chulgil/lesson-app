import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/audio/metronome_engine_interface.dart';
import 'package:lessonaza/core/audio/pace_cue_engine.dart';
import 'package:lessonaza/features/practice/domain/entities/metronome_settings.dart';

/// A minimal [PaceCueEngine] proving the neutral contract is satisfiable with NO
/// music-specific members (no BPM/time-signature/sound).
class _FakePaceCue implements PaceCueEngine {
  @override
  bool isPlaying = false;
  @override
  int currentBeat = 0;
  @override
  BeatCallback? onBeat;
  @override
  Future<void> init() async {}
  @override
  Future<void> start() async => isPlaying = true;
  @override
  Future<void> stop() async => isPlaying = false;
  @override
  Future<void> toggle() async => isPlaying = !isPlaying;
  @override
  Future<void> dispose() async {}
}

/// A [MetronomeEngineInterface] fake — exercised only for the type-hierarchy
/// assertion; music-specific members are not called.
class _FakeMetronome implements MetronomeEngineInterface {
  @override
  bool isPlaying = false;
  @override
  int currentBeat = 0;
  @override
  BeatCallback? onBeat;
  @override
  Future<void> init() async {}
  @override
  Future<void> start() async => isPlaying = true;
  @override
  Future<void> stop() async => isPlaying = false;
  @override
  Future<void> toggle() async => isPlaying = !isPlaying;
  @override
  Future<void> dispose() async {}
  @override
  MetronomeSettings get settings => throw UnimplementedError();
  @override
  Future<void> updateSettings(MetronomeSettings newSettings) async =>
      throw UnimplementedError();
  @override
  Future<void> setBpm(int bpm) async => throw UnimplementedError();
  @override
  Future<void> incrementBpm(int delta) async => throw UnimplementedError();
  @override
  Future<void> playTapSound() async => throw UnimplementedError();
}

void main() {
  group('PaceCueEngine (#974)', () {
    test('neutral contract is satisfiable without music-specific members', () {
      final engine = _FakePaceCue();
      expect(engine.isPlaying, isFalse);
      expect(engine.currentBeat, 0);
      expect(engine.onBeat, isNull);
    });

    test('beat callback round-trips through the neutral interface', () {
      final PaceCueEngine engine = _FakePaceCue();
      int? seenBeat;
      bool? seenAccent;
      engine.onBeat = (beat, isAccent) {
        seenBeat = beat;
        seenAccent = isAccent;
      };
      engine.onBeat!(3, true);
      expect(seenBeat, 3);
      expect(seenAccent, isTrue);
    });

    test('lifecycle toggles play state through the neutral interface', () async {
      final PaceCueEngine engine = _FakePaceCue();
      await engine.start();
      expect(engine.isPlaying, isTrue);
      await engine.toggle();
      expect(engine.isPlaying, isFalse);
      await engine.stop();
      expect(engine.isPlaying, isFalse);
    });

    test('MetronomeEngineInterface is-a PaceCueEngine (music = discipline 0)', () {
      final MetronomeEngineInterface music = _FakeMetronome();
      // The seam: music engine satisfies the discipline-neutral pace contract,
      // so a fitness engine (Phase 4 #979) can register the same slot type.
      expect(music, isA<PaceCueEngine>());
      final PaceCueEngine asNeutral = music; // assignable — compile-time proof
      expect(asNeutral.currentBeat, 0);
    });
  });
}
