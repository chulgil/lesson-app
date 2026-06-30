// #975 CenterActionSlot — 셸 배선 회귀 가드.
//
// 학생 셸만 중앙버튼을 CenterActionSlot 으로 감싼다. 교사/학부모 셸은
// 중앙버튼이 없으므로 슬롯을 추가하지 않는다 — spaceAround Row 에 빈 슬롯을
// 넣으면 N→N+1 로 간격이 재분배되어 기존 nav 아이콘이 시프트되기 때문이다.
// 교사/학부모 채택은 실제 centerAction 이 생기는 Phase 4(#979)로 미룬다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  group('CenterActionSlot shell wiring (#975)', () {
    test('학생 셸은 중앙버튼을 CenterActionSlot 으로 감싼다', () {
      final src = read(
        'lib/features/student_home/presentation/screens/student_home_screen.dart',
      );
      expect(
        src,
        contains(
          "import '../../../../core/widgets/center_action_slot.dart';",
        ),
      );
      expect(src, contains('const CenterActionSlot('));
      expect(src, contains('centerAction: PracticeCenterButton(size: 48),'));
    });

    test('교사 셸은 중앙버튼/슬롯이 없다 (미변경 — N→N+1 시프트 방지)', () {
      final src = read(
        'lib/features/home/presentation/screens/home_screen.dart',
      );
      expect(src, isNot(contains('CenterActionSlot')));
      expect(src, isNot(contains('PracticeCenterButton')));
    });

    test('학부모 셸은 중앙버튼/슬롯이 없다 (미변경 — N→N+1 시프트 방지)', () {
      final src = read(
        'lib/features/parent_home/presentation/screens/parent_home_screen.dart',
      );
      expect(src, isNot(contains('CenterActionSlot')));
      expect(src, isNot(contains('PracticeCenterButton')));
    });
  });
}
