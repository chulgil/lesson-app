import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/range_spec.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_section_range.dart';

void main() {
  // #969 — PracticeSection.range 뷰가 음악 저장 필드(full/line/measure)를
  // RangeSpec 추상으로 매핑한다. 기존 필드/직렬화 불변(additive), 회귀 0 가드.
  PracticeSection section({
    SectionRangeType rangeType = SectionRangeType.measure,
    int startMeasure = 1,
    int endMeasure = 4,
    int? startLine,
    int? endLine,
  }) {
    return PracticeSection(
      id: 's1',
      repertoireId: 'r1',
      pieceName: 'Etude',
      rangeType: rangeType,
      startMeasure: startMeasure,
      endMeasure: endMeasure,
      startLine: startLine,
      endLine: endLine,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('PracticeSection.range', () {
    test('measure -> RangeSpec.measures', () {
      final r = section(
        rangeType: SectionRangeType.measure,
        startMeasure: 1,
        endMeasure: 8,
      ).range;
      expect(r, RangeSpec.measures(1, 8));
    });

    test('line -> RangeSpec.lines', () {
      final r = section(
        rangeType: SectionRangeType.line,
        startLine: 2,
        endLine: 3,
      ).range;
      expect(r, RangeSpec.lines(2, 3));
    });

    test('full -> WholeRange', () {
      final r = section(rangeType: SectionRangeType.full).range;
      expect(r, const RangeSpec.whole());
    });

    test('line 인데 bounds 누락 -> WholeRange 폴백 (rangeText 빈문자 동작 미러)', () {
      final r = section(
        rangeType: SectionRangeType.line,
        startLine: null,
        endLine: null,
      ).range;
      expect(r, const RangeSpec.whole());
    });
  });
}
