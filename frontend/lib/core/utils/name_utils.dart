/// Utilities for displaying names across different cultures.
///
/// Korean names: "박지선" → surname "박", given name "지선"
/// Western names: "John Smith" → given name "John", surname "Smith"
class NameUtils {
  NameUtils._();

  /// Extract the given (first) name from a full name.
  ///
  /// Korean: 2-3 char names → remove first char (surname).
  ///   "박지선" → "지선", "김하은" → "하은"
  /// Korean 2-char: "이준" → "준"
  /// Western: space-separated → first word.
  ///   "John Smith" → "John"
  /// Single name: returned as-is.
  static String givenName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return trimmed;

    // If contains space → Western-style (or multi-word Korean)
    if (trimmed.contains(' ')) {
      return trimmed.split(' ').first;
    }

    // CJK name detection: all characters are CJK unified ideographs or Hangul
    final isCjk = trimmed.runes.every((r) =>
        (r >= 0xAC00 && r <= 0xD7A3) || // Hangul syllables
        (r >= 0x4E00 && r <= 0x9FFF) || // CJK unified
        (r >= 0x3400 && r <= 0x4DBF)); // CJK extension A

    if (isCjk && trimmed.length >= 2 && trimmed.length <= 4) {
      // Remove first character (surname) for CJK names
      return trimmed.substring(1);
    }

    // Fallback: return full name
    return trimmed;
  }
}
