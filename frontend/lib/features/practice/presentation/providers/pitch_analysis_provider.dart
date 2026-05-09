import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/pitch_analysis.dart';

part 'pitch_analysis_provider.g.dart';

/// Provides pitch analysis for a recording.
/// In mock mode, generates realistic sample data.
@riverpod
Future<PitchAnalysisResult?> pitchAnalysis(
  Ref ref,
  String recordingId,
) async {
  // Remote API not yet available — mock fallback for all modes
  // TODO(remote): Replace with actual analysis when audio processing is ready
  return _generateMockAnalysis(recordingId);
}

/// Generate realistic mock pitch analysis data.
PitchAnalysisResult _generateMockAnalysis(String recordingId) {
  final random = Random(recordingId.hashCode);
  final sampleCount = 60 + random.nextInt(120); // 60-180 samples (~3-9 sec)

  final notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  final baseOctave = 3 + random.nextInt(3); // octave 3-5

  final samples = List.generate(sampleCount, (i) {
    final note = notes[random.nextInt(notes.length)];
    final octave = baseOctave + (random.nextDouble() > 0.8 ? 1 : 0);
    // Base frequency for the note (approximate)
    final baseFreq = 261.63 * pow(2, (octave - 4)).toDouble(); // C4 = 261.63
    final noteOffset = notes.indexOf(note) * 2.0; // rough semitone offset
    final freq = baseFreq * pow(2, noteOffset / 12).toDouble();
    // Add realistic deviation (-30 to +30 cents, normally distributed)
    final deviation = (random.nextDouble() - 0.5) * 40;

    return FrequencySample(
      timestamp: Duration(milliseconds: i * 50), // 50ms intervals
      frequency: freq + (freq * deviation / 1200), // cents to Hz
      noteName: note,
      octave: octave,
      centDeviation: deviation,
    );
  });

  final metrics = PitchAnalysisResult.computeMetrics(samples);

  return PitchAnalysisResult(
    id: const Uuid().v4(),
    recordingId: recordingId,
    samples: samples,
    metrics: metrics,
    analyzedAt: DateTime.now(),
  );
}
