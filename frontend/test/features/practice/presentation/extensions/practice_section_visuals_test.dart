import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/extensions/practice_section_visuals.dart';

void main() {
  PracticeSection section({
    SectionRangeType rangeType = SectionRangeType.measure,
    int startMeasure = 1,
    int endMeasure = 4,
    int? startLine,
    int? endLine,
  }) => PracticeSection(
    id: 's1',
    repertoireId: 'r1',
    pieceName: 'Canon',
    rangeType: rangeType,
    startMeasure: startMeasure,
    endMeasure: endMeasure,
    startLine: startLine,
    endLine: endLine,
    createdAt: DateTime(2026, 1, 1),
  );

  group('PracticeSectionDisplay.rangeText', () {
    test('measure range keeps the legacy "N~M 마디" form', () {
      expect(section(startMeasure: 1, endMeasure: 4).rangeText, '1~4 마디');
    });

    test('line range keeps the legacy "N~M줄" form (no space)', () {
      expect(
        section(
          rangeType: SectionRangeType.line,
          startLine: 1,
          endLine: 3,
        ).rangeText,
        '1~3줄',
      );
    });

    test('line range with missing bounds is empty', () {
      expect(section(rangeType: SectionRangeType.line).rangeText, '');
    });

    test('full range is "전체"', () {
      expect(section(rangeType: SectionRangeType.full).rangeText, '전체');
    });
  });
}
