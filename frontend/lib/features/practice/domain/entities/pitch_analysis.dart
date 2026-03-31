/// Pitch analysis result for a practice recording.
///
/// Captures frequency data over time and computes summary metrics.

class FrequencySample {
  const FrequencySample({
    required this.timestamp,
    required this.frequency,
    required this.noteName,
    required this.octave,
    required this.centDeviation,
  });

  /// Time offset from recording start.
  final Duration timestamp;

  /// Detected frequency in Hz.
  final double frequency;

  /// Detected note name (e.g., 'A', 'C#').
  final String noteName;

  /// Detected octave number.
  final int octave;

  /// Deviation from perfect pitch in cents (-50 to +50).
  final double centDeviation;

  String get noteLabel => '$noteName$octave';

  Map<String, dynamic> toJson() => {
        'timestamp_ms': timestamp.inMilliseconds,
        'frequency': frequency,
        'note_name': noteName,
        'octave': octave,
        'cent_deviation': centDeviation,
      };

  factory FrequencySample.fromJson(Map<String, dynamic> json) =>
      FrequencySample(
        timestamp: Duration(milliseconds: json['timestamp_ms'] as int),
        frequency: (json['frequency'] as num).toDouble(),
        noteName: json['note_name'] as String,
        octave: json['octave'] as int,
        centDeviation: (json['cent_deviation'] as num).toDouble(),
      );
}

class PitchAnalysisMetrics {
  const PitchAnalysisMetrics({
    required this.averageCentDeviation,
    required this.stabilityScore,
    required this.frequencyMin,
    required this.frequencyMax,
    required this.totalSamples,
    required this.inTuneSamples,
    required this.noteDistribution,
  });

  /// Average absolute cent deviation from perfect pitch.
  final double averageCentDeviation;

  /// Stability score (0.0 ~ 1.0). Higher = more consistent pitch.
  final double stabilityScore;

  /// Lowest detected frequency (Hz).
  final double frequencyMin;

  /// Highest detected frequency (Hz).
  final double frequencyMax;

  /// Total pitch samples captured.
  final int totalSamples;

  /// Samples within ±10 cents of perfect pitch.
  final int inTuneSamples;

  /// Note name → count distribution.
  final Map<String, int> noteDistribution;

  /// Percentage of in-tune samples (0 ~ 100).
  double get inTunePercent =>
      totalSamples > 0 ? (inTuneSamples / totalSamples) * 100 : 0;

  /// Overall grade based on inTunePercent.
  String get grade {
    if (inTunePercent >= 90) return 'S';
    if (inTunePercent >= 75) return 'A';
    if (inTunePercent >= 60) return 'B';
    if (inTunePercent >= 40) return 'C';
    return 'D';
  }

  /// Grade color name for UI.
  String get gradeColorName {
    if (inTunePercent >= 90) return 'success';
    if (inTunePercent >= 75) return 'primary';
    if (inTunePercent >= 60) return 'info';
    if (inTunePercent >= 40) return 'warning';
    return 'error';
  }

  Map<String, dynamic> toJson() => {
        'average_cent_deviation': averageCentDeviation,
        'stability_score': stabilityScore,
        'frequency_min': frequencyMin,
        'frequency_max': frequencyMax,
        'total_samples': totalSamples,
        'in_tune_samples': inTuneSamples,
        'note_distribution': noteDistribution,
      };

  factory PitchAnalysisMetrics.fromJson(Map<String, dynamic> json) =>
      PitchAnalysisMetrics(
        averageCentDeviation:
            (json['average_cent_deviation'] as num).toDouble(),
        stabilityScore: (json['stability_score'] as num).toDouble(),
        frequencyMin: (json['frequency_min'] as num).toDouble(),
        frequencyMax: (json['frequency_max'] as num).toDouble(),
        totalSamples: json['total_samples'] as int,
        inTuneSamples: json['in_tune_samples'] as int,
        noteDistribution:
            Map<String, int>.from(json['note_distribution'] as Map),
      );
}

class PitchAnalysisResult {
  const PitchAnalysisResult({
    required this.id,
    required this.recordingId,
    required this.samples,
    required this.metrics,
    required this.analyzedAt,
  });

  final String id;
  final String recordingId;
  final List<FrequencySample> samples;
  final PitchAnalysisMetrics metrics;
  final DateTime analyzedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'recording_id': recordingId,
        'samples': samples.map((s) => s.toJson()).toList(),
        'metrics': metrics.toJson(),
        'analyzed_at': analyzedAt.toIso8601String(),
      };

  factory PitchAnalysisResult.fromJson(Map<String, dynamic> json) =>
      PitchAnalysisResult(
        id: json['id'] as String,
        recordingId: json['recording_id'] as String,
        samples: (json['samples'] as List)
            .map((s) => FrequencySample.fromJson(s as Map<String, dynamic>))
            .toList(),
        metrics: PitchAnalysisMetrics.fromJson(
            json['metrics'] as Map<String, dynamic>),
        analyzedAt: DateTime.parse(json['analyzed_at'] as String),
      );

  /// Compute metrics from raw frequency samples.
  static PitchAnalysisMetrics computeMetrics(List<FrequencySample> samples) {
    if (samples.isEmpty) {
      return const PitchAnalysisMetrics(
        averageCentDeviation: 0,
        stabilityScore: 0,
        frequencyMin: 0,
        frequencyMax: 0,
        totalSamples: 0,
        inTuneSamples: 0,
        noteDistribution: {},
      );
    }

    double sumAbsDeviation = 0;
    double minFreq = double.infinity;
    double maxFreq = 0;
    int inTuneCount = 0;
    final noteCount = <String, int>{};

    for (final s in samples) {
      sumAbsDeviation += s.centDeviation.abs();
      if (s.frequency < minFreq) minFreq = s.frequency;
      if (s.frequency > maxFreq) maxFreq = s.frequency;
      if (s.centDeviation.abs() <= 10) inTuneCount++;
      noteCount[s.noteName] = (noteCount[s.noteName] ?? 0) + 1;
    }

    // Stability: inverse of deviation variance
    final avgDev = sumAbsDeviation / samples.length;
    double sumVariance = 0;
    for (final s in samples) {
      final diff = s.centDeviation.abs() - avgDev;
      sumVariance += diff * diff;
    }
    final variance = sumVariance / samples.length;
    // Normalize to 0-1 (50 cents max deviation → 0 stability)
    final stability = (1.0 - (variance / 2500)).clamp(0.0, 1.0);

    return PitchAnalysisMetrics(
      averageCentDeviation: avgDev,
      stabilityScore: stability,
      frequencyMin: minFreq,
      frequencyMax: maxFreq,
      totalSamples: samples.length,
      inTuneSamples: inTuneCount,
      noteDistribution: noteCount,
    );
  }
}
