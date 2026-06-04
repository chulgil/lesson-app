/// Allowed playback speeds for YouTube loop practice.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §3.4
class PracticeLoopSpeeds {
  PracticeLoopSpeeds._();

  /// 5-step ladder: precise → preview.
  static const List<double> allowed = [0.25, 0.5, 0.75, 1.0, 1.25];

  /// Default playback speed when no override is set.
  static const double defaultSpeed = 1.0;

  /// Returns true if [speed] is one of the [allowed] values.
  static bool isAllowed(double speed) {
    for (final s in allowed) {
      if ((s - speed).abs() < 0.001) return true;
    }
    return false;
  }

  /// Returns the closest allowed speed to [speed].
  static double clamp(double speed) {
    double best = defaultSpeed;
    double bestDiff = double.infinity;
    for (final s in allowed) {
      final diff = (s - speed).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = s;
      }
    }
    return best;
  }
}
