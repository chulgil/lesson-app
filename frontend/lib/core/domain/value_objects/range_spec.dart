// Practice range value objects for the multi-Discipline platform (#969, Phase 2,
// design doc "36-멀티카테고리-Discipline-플랫폼-설계" §2/§5.1).
//
// Pure domain — no Flutter/serialization/presentation deps. The display
// vocabulary (마디/줄/전체) is resolved at the presentation boundary
// (StringOverlay), never here. Music is discipline 0; the abstraction exists so
// later phases register their own range units without restructuring it.

/// The unit a bounded [SubRange] is measured in.
///
/// Music uses [measure] / [line]. Fitness adds a `set` unit (Phase 4, #979) and
/// language a `sentence` unit (Phase 5) — each is one enum value, so the
/// [RangeSpec] structure already accommodates them (a fitness set range and a
/// language sentence range slot into the same [SubRange]). No structural change
/// is needed to extend.
enum RangeUnit { measure, line }

/// "Where to practice" — a discipline-neutral practice range (#969).
///
/// Either the [WholeRange] target (the whole piece for music, the whole routine
/// for fitness) or a bounded [SubRange] (`start..end` inclusive in some
/// [RangeUnit]).
///
/// Music construction helpers: [RangeSpec.whole], [RangeSpec.measures] (the
/// design's "MeasureRangeSpec"), and [RangeSpec.lines].
sealed class RangeSpec {
  const RangeSpec();

  /// The whole target — no bounded subrange.
  const factory RangeSpec.whole() = WholeRange;

  /// Music: measures [start]..[end] inclusive (the design's MeasureRangeSpec).
  factory RangeSpec.measures(int start, int end) =>
      SubRange(unit: RangeUnit.measure, start: start, end: end);

  /// Music: lines [start]..[end] inclusive.
  factory RangeSpec.lines(int start, int end) =>
      SubRange(unit: RangeUnit.line, start: start, end: end);
}

/// The whole practice target (no bounded subrange).
final class WholeRange extends RangeSpec {
  const WholeRange();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WholeRange;

  @override
  int get hashCode => (WholeRange).hashCode;

  @override
  String toString() => 'WholeRange()';
}

/// A bounded practice subrange: [start]..[end] (inclusive) in [unit].
final class SubRange extends RangeSpec {
  final RangeUnit unit;
  final int start;
  final int end;

  const SubRange({required this.unit, required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubRange &&
          runtimeType == other.runtimeType &&
          unit == other.unit &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(unit, start, end);

  @override
  String toString() => 'SubRange($unit, $start..$end)';
}
