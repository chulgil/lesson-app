/// A-B Loop state for section repeat in playback.
class ABLoop {
  const ABLoop({this.pointA, this.pointB});

  final Duration? pointA;
  final Duration? pointB;

  bool get isActive => pointA != null && pointB != null;
  bool get hasA => pointA != null;
  bool get hasB => pointB != null;

  ABLoop copyWith({
    Duration? pointA,
    Duration? pointB,
    bool clearA = false,
    bool clearB = false,
  }) {
    return ABLoop(
      pointA: clearA ? null : (pointA ?? this.pointA),
      pointB: clearB ? null : (pointB ?? this.pointB),
    );
  }
}
