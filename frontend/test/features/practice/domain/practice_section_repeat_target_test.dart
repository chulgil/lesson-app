import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/repeat_target.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_section_repeat_target.dart';

void main() {
  // #970 — PracticeSection.repeatTarget 뷰가 음악 N회 반복 필드(repeatCount)를
  // RepeatTarget 추상으로 매핑한다. 기존 필드/직렬화 불변(additive), 회귀 0 가드.
  PracticeSection section({int? repeatCount}) {
    return PracticeSection(
      id: 's1',
      repertoireId: 'r1',
      pieceName: 'Etude',
      startMeasure: 1,
      endMeasure: 4,
      repeatCount: repeatCount,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('PracticeSection.repeatTarget', () {
    test('repeatCount >= 2 -> single(repeatCount)', () {
      expect(section(repeatCount: 5).repeatTarget, RepeatTarget.single(5));
    });

    test('repeatCount null -> single(1) (off = 한 번 연습)', () {
      expect(section().repeatTarget, RepeatTarget.single(1));
    });

    test('repeatCount 1 (임계값 미만, hasRepeatCount=false) -> single(1)', () {
      // repeatCount 1 은 hasRepeatCount(>=2) 기준 off 로 취급 → 단일 연습.
      expect(section(repeatCount: 1).repeatTarget, RepeatTarget.single(1));
    });

    test('음악은 항상 단일축 — secondary null', () {
      expect(section(repeatCount: 5).repeatTarget.secondary, isNull);
      expect(section(repeatCount: 5).repeatTarget.isSingleAxis, isTrue);
      expect(section().repeatTarget.isSingleAxis, isTrue);
    });
  });
}
