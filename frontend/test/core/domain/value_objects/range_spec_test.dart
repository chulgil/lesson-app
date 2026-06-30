import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/range_spec.dart';

void main() {
  // #969 멀티 Discipline Phase 2 — RangeSpec 값객체 (whole|subrange) + music factory.
  // 순수 도메인 값객체: 동등성·factory 매핑·sealed 망라성. 음악 동작 변경 0.
  group('RangeSpec', () {
    test('whole 은 WholeRange 인스턴스', () {
      const r = RangeSpec.whole();
      expect(r, isA<WholeRange>());
    });

    test('measures factory 는 measure unit 의 SubRange (= MeasureRangeSpec)', () {
      final r = RangeSpec.measures(1, 4);
      expect(r, isA<SubRange>());
      final sub = r as SubRange;
      expect(sub.unit, RangeUnit.measure);
      expect(sub.start, 1);
      expect(sub.end, 4);
    });

    test('lines factory 는 line unit 의 SubRange', () {
      final r = RangeSpec.lines(2, 3);
      expect(r, isA<SubRange>());
      final sub = r as SubRange;
      expect(sub.unit, RangeUnit.line);
      expect(sub.start, 2);
      expect(sub.end, 3);
    });

    test('WholeRange 동등성 — 모든 인스턴스 동일', () {
      expect(const WholeRange(), const WholeRange());
      expect(const RangeSpec.whole(), const WholeRange());
      expect(const WholeRange().hashCode, const WholeRange().hashCode);
    });

    test('SubRange 동등성 — unit/start/end 모두 같을 때만', () {
      expect(RangeSpec.measures(1, 4), RangeSpec.measures(1, 4));
      expect(
        RangeSpec.measures(1, 4).hashCode,
        RangeSpec.measures(1, 4).hashCode,
      );
      expect(RangeSpec.measures(1, 4), isNot(RangeSpec.measures(1, 5)));
      expect(RangeSpec.measures(1, 4), isNot(RangeSpec.lines(1, 4)));
      expect(RangeSpec.measures(1, 4), isNot(const RangeSpec.whole()));
    });

    test('sealed 망라 switch — whole/sub 두 갈래만', () {
      String describe(RangeSpec r) => switch (r) {
        WholeRange() => 'whole',
        SubRange(:final unit, :final start, :final end) => '$unit:$start-$end',
      };
      expect(describe(const RangeSpec.whole()), 'whole');
      expect(describe(RangeSpec.measures(1, 4)), 'RangeUnit.measure:1-4');
      expect(describe(RangeSpec.lines(2, 3)), 'RangeUnit.line:2-3');
    });
  });
}
