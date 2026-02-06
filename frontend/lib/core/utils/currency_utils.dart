/// Currency formatting utilities for Korean Won (KRW).
///
/// Provides consistent formatting across the app for prices and amounts.
library;

/// Formats a price in Korean Won with 만원 notation.
///
/// Examples:
/// - 50000 → "5만원"
/// - 55000 → "5만 5000원"
/// - 5000 → "5000원"
String formatKoreanWon(int amount) {
  if (amount >= 10000) {
    final man = amount ~/ 10000;
    final remainder = amount % 10000;
    if (remainder == 0) {
      return '$man만원';
    }
    return '$man만 $remainder원';
  }
  return '$amount원';
}

/// Formats a price with comma separators.
///
/// Example: 1500000 → "1,500,000원"
String formatWonWithComma(int amount) {
  final formatted = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  return '$formatted원';
}

/// Extension on int for convenient currency formatting.
extension CurrencyFormatExtension on int {
  /// Formats as Korean Won with 만원 notation.
  String get toKoreanWon => formatKoreanWon(this);

  /// Formats with comma separators.
  String get toWonWithComma => formatWonWithComma(this);
}
