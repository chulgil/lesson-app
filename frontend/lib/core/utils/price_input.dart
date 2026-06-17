import 'package:flutter/services.dart';

/// 가격/금액 입력 공통 모듈 — 천단위 콤마 표기 일괄 적용.
///
/// 사용:
/// - `inputFormatters: [ThousandsSeparatorInputFormatter()]` (digitsOnly 대체)
/// - 컨트롤러에 프리필할 때: `controller.text = formatPriceWithCommas(value)`
/// - 값을 읽을 때: `parsePrice(controller.text)` (콤마 제거 후 정수)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = formatPriceWithCommas(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      // 커서는 항상 끝으로 (가격 입력은 뒤에 이어 붙이는 패턴).
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 정수를 천단위 콤마 문자열로 변환. 예: `100000 -> "100,000"`.
/// 음수는 부호를 유지한다(가격은 보통 음수가 아니지만 방어적으로).
String formatPriceWithCommas(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buf.write(',');
    }
    buf.write(digits[i]);
  }
  return negative ? '-${buf.toString()}' : buf.toString();
}

/// 콤마 등 비숫자를 제거하고 정수로 파싱. 예: `"100,000" -> 100000`.
/// 빈 문자열·숫자 없음이면 `null`.
int? parsePrice(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}
