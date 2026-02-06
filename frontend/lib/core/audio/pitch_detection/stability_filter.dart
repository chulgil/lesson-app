// Stability filter for pitch detection
// Filters out noise and stabilizes detected notes

import 'dart:collection';

/// Configuration for stability filtering.
class StabilityConfig {
  const StabilityConfig({
    this.minProbability = 0.85,
    this.stabilityFrames = 3,
    this.frequencyTolerance = 5.0,
    this.smoothingFactor = 0.3,
  });

  /// Minimum probability from YIN detector to accept (0.0-1.0).
  final double minProbability;

  /// Number of consecutive frames with same note required.
  final int stabilityFrames;

  /// Tolerance in Hz for considering notes as "same".
  final double frequencyTolerance;

  /// Smoothing factor for frequency averaging (0.0-1.0).
  /// Lower = more smoothing, higher = more responsive.
  final double smoothingFactor;
}

/// Result from stability filter.
class StabilityResult {
  const StabilityResult({
    required this.frequency,
    required this.isStable,
    required this.confidence,
  });

  /// Smoothed frequency value.
  final double frequency;

  /// Whether the note is stable (consistent over multiple frames).
  final bool isStable;

  /// Confidence level (0.0-1.0).
  final double confidence;

  static const empty = StabilityResult(
    frequency: 0,
    isStable: false,
    confidence: 0,
  );
}

/// Stability filter that requires consistent pitch over multiple frames.
class StabilityFilter {
  StabilityFilter({
    this.config = const StabilityConfig(),
  });

  final StabilityConfig config;

  final Queue<double> _frequencyBuffer = Queue<double>();
  double _smoothedFrequency = 0;
  int _stableCount = 0;
  double _lastStableFrequency = 0;
  double _lastRawFrequency = 0; // Track raw frequency before correction

  /// Process a new pitch detection result.
  ///
  /// Returns [StabilityResult] indicating if pitch is stable.
  StabilityResult process({
    required double frequency,
    required double probability,
    required bool pitched,
  }) {
    // Not pitched = no valid audio
    if (!pitched || frequency <= 0) {
      _reset();
      return StabilityResult.empty;
    }

    // Probability too low = unreliable
    if (probability < config.minProbability) {
      _stableCount = 0;
      return StabilityResult(
        frequency: _smoothedFrequency,
        isStable: false,
        confidence: probability,
      );
    }

    // Correct octave errors (YIN sometimes detects 2x frequency)
    var correctedFrequency = _correctOctaveError(frequency);

    // Apply exponential moving average smoothing
    if (_smoothedFrequency == 0) {
      _smoothedFrequency = correctedFrequency;
    } else {
      _smoothedFrequency = config.smoothingFactor * correctedFrequency +
          (1 - config.smoothingFactor) * _smoothedFrequency;
    }

    // Check if frequency is consistent with previous
    final isConsistent = _isConsistent(correctedFrequency);

    if (isConsistent) {
      _stableCount++;
    } else {
      _stableCount = 1;
      _lastStableFrequency = correctedFrequency;
    }

    // Update buffer
    _frequencyBuffer.addLast(correctedFrequency);
    if (_frequencyBuffer.length > config.stabilityFrames * 2) {
      _frequencyBuffer.removeFirst();
    }

    final isStable = _stableCount >= config.stabilityFrames;

    return StabilityResult(
      frequency: _smoothedFrequency,
      isStable: isStable,
      confidence: probability,
    );
  }

  /// Correct octave errors where YIN detects 2x the actual frequency.
  ///
  /// YIN algorithm sometimes detects 2nd harmonic instead of fundamental.
  /// Uses multiple strategies:
  /// 1. Ratio comparison with previous stable frequency
  /// 2. Continuity check with previous raw frequency
  double _correctOctaveError(double frequency) {
    final halfFreq = frequency / 2;

    // Strategy 1: Compare with last stable frequency
    if (_lastStableFrequency > 0) {
      final ratio = frequency / _lastStableFrequency;
      // If ratio is between 1.9 and 2.1, it's likely an octave error
      if (ratio >= 1.9 && ratio <= 2.1) {
        _lastRawFrequency = frequency;
        return halfFreq;
      }
    }

    // Strategy 2: Compare both f and f/2 with previous raw frequency
    // Choose the one that's closer (more continuous)
    if (_lastRawFrequency > 0) {
      final diffFull = (frequency - _lastRawFrequency).abs();
      final diffHalf = (halfFreq - _lastRawFrequency).abs();

      // If f/2 is significantly closer to previous frequency, use it
      // This catches cases where YIN suddenly jumps to 2x
      if (diffHalf < diffFull * 0.5 && halfFreq > 50) {
        _lastRawFrequency = halfFreq;
        return halfFreq;
      }
    }

    _lastRawFrequency = frequency;
    return frequency;
  }

  bool _isConsistent(double frequency) {
    if (_lastStableFrequency == 0) return true;

    // Check if within tolerance (in cents for better accuracy)
    final centsDiff = _frequencyToCents(frequency, _lastStableFrequency).abs();
    return centsDiff < 50; // Within 50 cents = same note
  }

  double _frequencyToCents(double freq1, double freq2) {
    if (freq1 <= 0 || freq2 <= 0) return 0;
    return 1200 * _log2(freq1 / freq2);
  }

  double _log2(double x) => x > 0 ? _ln(x) / _ln(2) : 0;
  double _ln(double x) {
    // Natural log approximation
    if (x <= 0) return 0;
    double result = 0;
    double term = (x - 1) / (x + 1);
    double termSquared = term * term;
    double currentTerm = term;
    for (int i = 1; i <= 50; i += 2) {
      result += currentTerm / i;
      currentTerm *= termSquared;
    }
    return 2 * result;
  }

  void _reset() {
    _stableCount = 0;
    _smoothedFrequency = 0;
    _lastStableFrequency = 0;
    _lastRawFrequency = 0;
  }

  /// Reset the filter state.
  void reset() {
    _frequencyBuffer.clear();
    _reset();
  }
}

/// Amplitude gate to filter out quiet sounds (noise).
class AmplitudeGate {
  AmplitudeGate({
    this.threshold = 0.05,
    this.holdTime = const Duration(milliseconds: 500),
  });

  /// Minimum amplitude to pass through (0.0-1.0).
  final double threshold;

  /// Time to hold gate open after signal drops.
  /// Increased from 200ms to 500ms for better stability during brief gaps.
  final Duration holdTime;

  DateTime? _lastAboveThreshold;
  bool _isOpen = false;

  /// Check if amplitude passes the gate.
  bool check(double amplitude) {
    if (amplitude >= threshold) {
      _lastAboveThreshold = DateTime.now();
      _isOpen = true;
      return true;
    }

    // Check hold time
    if (_lastAboveThreshold != null) {
      final elapsed = DateTime.now().difference(_lastAboveThreshold!);
      if (elapsed < holdTime) {
        return true;
      }
    }

    _isOpen = false;
    return false;
  }

  bool get isOpen => _isOpen;

  void reset() {
    _lastAboveThreshold = null;
    _isOpen = false;
  }
}
