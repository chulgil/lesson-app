/// Bank account number masking (data-privacy.md Level 1 — 결제 정보).
///
/// Masks every digit except the last 4, preserving non-digit separators
/// (hyphens) so the grouping stays readable.
library;

/// Masks [raw] to reveal only the last 4 digits.
///
/// Examples:
/// - `maskAccountNumber('110-123-456789')` -> `'***-***-**6789'`
/// - `maskAccountNumber('1234')` -> `'1234'` (too short to mask meaningfully)
///
/// Idempotent: masking an already-masked string is a no-op, since the
/// masked string's digit-only content is just the 4 visible digits.
String maskAccountNumber(String raw) {
  final digitCount = raw.replaceAll(RegExp(r'[^0-9]'), '').length;
  if (digitCount <= 4) return raw;

  var digitIndex = 0;
  final buffer = StringBuffer();
  for (final char in raw.split('')) {
    if (RegExp(r'[0-9]').hasMatch(char)) {
      final remaining = digitCount - digitIndex;
      buffer.write(remaining <= 4 ? char : '*');
      digitIndex++;
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}
