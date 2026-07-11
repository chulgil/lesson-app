// R2 (audit 2026-07-10) — fee range formatting must not truncate the manwon
// remainder (D3-class): 45,000 was rendered "4만원". Presentation extension
// replaces the domain entity's display getter (flutter-architecture).

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/presentation/extensions/fee_range_visuals.dart';

void main() {
  group('FeeRangeVisuals.label', () {
    test('나머지가 있는 금액은 절사 없이 "N만 M원" 으로 표기한다', () {
      const range = FeeRange(minFee: 45000, maxFee: 45000, duration: 60);
      expect(range.label, '4만 5000원 / 1시간');
    });

    test('라운드 금액은 "N만원" 으로 표기한다', () {
      const range = FeeRange(minFee: 60000, maxFee: 80000, duration: 60);
      expect(range.label, '6만원 ~ 8만원 / 1시간');
    });

    test('만원 미만 금액은 원 단위 그대로 표기한다', () {
      const range = FeeRange(minFee: 9000, maxFee: 9000, duration: 30);
      expect(range.label, '9000원 / 30분');
    });
  });
}
