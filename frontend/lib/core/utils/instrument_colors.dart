import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Instrument color mapping for schedule views.
/// Each instrument gets a unique background + accent color pair.
class InstrumentColors {
  InstrumentColors._();

  static const _colorMap = <String, InstrumentColorPair>{
    // Notebook × Score: 바이올린 = 서명 악기 (paper + Vermillion) §1.1 · §7.104.
    '바이올린': InstrumentColorPair(AppColors.paper, AppColors.paperAccent),
    '피아노': InstrumentColorPair(Color(0xFFE3F2FD), Color(0xFF1976D2)),
    '첼로': InstrumentColorPair(Color(0xFFFFF3E0), Color(0xFFF57C00)),
    '플루트': InstrumentColorPair(Color(0xFFE8F5E9), Color(0xFF388E3C)),
    '기타': InstrumentColorPair(Color(0xFFFCE4EC), Color(0xFFC2185B)),
    '성악': InstrumentColorPair(Color(0xFFFFF8E1), Color(0xFFFFA000)),
    '클라리넷': InstrumentColorPair(Color(0xFFE0F7FA), Color(0xFF00838F)),
    '드럼': InstrumentColorPair(Color(0xFFEFEBE9), Color(0xFF5D4037)),
    '타악기': InstrumentColorPair(Color(0xFFEFEBE9), Color(0xFF5D4037)),
  };

  // Fallback palette for instruments not in the map (cycles through)
  static const _fallbackPalette = [
    InstrumentColorPair(Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
    InstrumentColorPair(Color(0xFFE8EAF6), Color(0xFF303F9F)),
    InstrumentColorPair(Color(0xFFFBE9E7), Color(0xFFBF360C)),
    InstrumentColorPair(Color(0xFFE0F2F1), Color(0xFF00695C)),
    InstrumentColorPair(Color(0xFFFFF9C4), Color(0xFFF9A825)),
  ];

  /// Get color pair for an instrument name.
  /// Falls back to a palette-cycled color for unknown instruments.
  static InstrumentColorPair getColor(String instrument) {
    final normalized = instrument.trim();

    // Direct match
    if (_colorMap.containsKey(normalized)) {
      return _colorMap[normalized]!;
    }

    // Partial match (e.g., "드럼/타악기" contains "드럼")
    for (final entry in _colorMap.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    // Fallback: hash-based palette cycling
    final index = normalized.hashCode.abs() % _fallbackPalette.length;
    return _fallbackPalette[index];
  }
}

/// A pair of background and accent colors for an instrument.
class InstrumentColorPair {
  final Color background;
  final Color accent;

  const InstrumentColorPair(this.background, this.accent);
}
