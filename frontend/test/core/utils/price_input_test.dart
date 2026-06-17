import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/utils/price_input.dart';

void main() {
  group('formatPriceWithCommas', () {
    test('천단위 콤마 삽입', () {
      expect(formatPriceWithCommas(0), '0');
      expect(formatPriceWithCommas(100), '100');
      expect(formatPriceWithCommas(1000), '1,000');
      expect(formatPriceWithCommas(10000), '10,000');
      expect(formatPriceWithCommas(100000), '100,000');
      expect(formatPriceWithCommas(1234567), '1,234,567');
    });
  });

  group('parsePrice', () {
    test('콤마/기호 제거 후 정수', () {
      expect(parsePrice('100,000'), 100000);
      expect(parsePrice('1,234,567'), 1234567);
      expect(parsePrice('₩ 50,000'), 50000);
      expect(parsePrice('0'), 0);
      expect(parsePrice(''), isNull);
      expect(parsePrice('abc'), isNull);
    });

    test('format ↔ parse 라운드트립', () {
      for (final v in [0, 5, 999, 1000, 45000, 1500000]) {
        expect(parsePrice(formatPriceWithCommas(v)), v);
      }
    });
  });

  group('ThousandsSeparatorInputFormatter', () {
    const formatter = ThousandsSeparatorInputFormatter();
    TextEditingValue fmt(String s) => formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      TextEditingValue(text: s),
    );

    test('입력 시 콤마 삽입 + 커서 끝', () {
      expect(fmt('100000').text, '100,000');
      expect(fmt('1000').text, '1,000');
      expect(fmt('').text, '');
      // 이미 콤마가 있어도 정규화.
      expect(fmt('100,000').text, '100,000');
      // 비숫자 제거.
      expect(fmt('1a2b3').text, '123');
      final v = fmt('100000');
      expect(v.selection.baseOffset, v.text.length);
    });
  });
}
