import 'package:flutter/material.dart';

import '../domain/value_objects/discipline.dart';
import 'app_colors.dart';

/// A pair of background + accent colors for an expertise tag (instrument /
/// specialty / subject). Discipline-neutral (#967, design doc
/// "36-멀티카테고리-Discipline-플랫폼-설계").
class ExpertiseColorPair {
  final Color background;
  final Color accent;

  const ExpertiseColorPair(this.background, this.accent);
}

/// Discipline-scoped color resolver: maps an expertise [tag] to a color pair,
/// with a palette fallback for tags not in the map. Generalizes the legacy
/// music-only `InstrumentColors` (#967).
///
/// One resolver per discipline, registered in [ExpertiseColorResolverRegistry]
/// by `Discipline.expertiseCatalogId`. Lives in `core/theme` (holds Flutter
/// `Color`), not `core/domain` — flutter-architecture rule.
class ExpertiseColorResolver {
  final String catalogId;
  final Map<String, ExpertiseColorPair> _map;
  final List<ExpertiseColorPair> _fallbackPalette;

  const ExpertiseColorResolver({
    required this.catalogId,
    required Map<String, ExpertiseColorPair> map,
    required List<ExpertiseColorPair> fallbackPalette,
  }) : _map = map,
       _fallbackPalette = fallbackPalette;

  /// Color pair for an expertise [tag]: direct match → partial (substring)
  /// match → hash-cycled palette fallback. Behavior preserved from the legacy
  /// `InstrumentColors.getColor` (regression 0).
  ExpertiseColorPair resolve(String tag) {
    final normalized = tag.trim();

    final direct = _map[normalized];
    if (direct != null) return direct;

    for (final entry in _map.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    final index = normalized.hashCode.abs() % _fallbackPalette.length;
    return _fallbackPalette[index];
  }
}

/// SSOT registry of [ExpertiseColorResolver]s, keyed by
/// `Discipline.expertiseCatalogId` (#967, mirrors `ExpertiseCatalogRegistry`).
///
/// **Lookup by id — never `enum switch`.** Registering a discipline's color
/// map is a data change here. The music resolver (catalogId 'instruments') is
/// the SSOT for instrument colors; `InstrumentColors.getColor` delegates to it.
class ExpertiseColorResolverRegistry {
  const ExpertiseColorResolverRegistry._();

  /// Shared fallback palette (hash-cycled) for unmapped tags / disciplines.
  static const List<ExpertiseColorPair> _fallbackPalette = [
    ExpertiseColorPair(Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
    ExpertiseColorPair(Color(0xFFE8EAF6), Color(0xFF303F9F)),
    ExpertiseColorPair(Color(0xFFFBE9E7), Color(0xFFBF360C)),
    ExpertiseColorPair(Color(0xFFE0F2F1), Color(0xFF00695C)),
    ExpertiseColorPair(Color(0xFFFFF9C4), Color(0xFFF9A825)),
  ];

  /// Music vertical resolver — the instrument color map. SSOT.
  static const ExpertiseColorResolver music = ExpertiseColorResolver(
    catalogId: 'instruments',
    map: {
      // Notebook × Score: 바이올린 = 서명 악기 (paper + Vermillion) §1.1 · §7.104.
      '바이올린': ExpertiseColorPair(AppColors.paper, AppColors.paperAccent),
      '피아노': ExpertiseColorPair(Color(0xFFE3F2FD), Color(0xFF1976D2)),
      '첼로': ExpertiseColorPair(Color(0xFFFFF3E0), Color(0xFFF57C00)),
      '플루트': ExpertiseColorPair(Color(0xFFE8F5E9), Color(0xFF388E3C)),
      '기타': ExpertiseColorPair(Color(0xFFFCE4EC), Color(0xFFC2185B)),
      '성악': ExpertiseColorPair(Color(0xFFFFF8E1), Color(0xFFFFA000)),
      '클라리넷': ExpertiseColorPair(Color(0xFFE0F7FA), Color(0xFF00838F)),
      '드럼': ExpertiseColorPair(Color(0xFFEFEBE9), Color(0xFF5D4037)),
      '타악기': ExpertiseColorPair(Color(0xFFEFEBE9), Color(0xFF5D4037)),
    },
    fallbackPalette: _fallbackPalette,
  );

  /// Fallback resolver for unregistered disciplines — palette-only (empty map,
  /// so every tag is hash-cycled). "미지정 분야 폴백 팔레트" (#967).
  static const ExpertiseColorResolver fallback = ExpertiseColorResolver(
    catalogId: '_fallback',
    map: {},
    fallbackPalette: _fallbackPalette,
  );

  static const List<ExpertiseColorResolver> _registered = [music];

  /// Resolve a resolver by catalog [id]; null if not registered.
  static ExpertiseColorResolver? byId(String id) {
    for (final r in _registered) {
      if (r.catalogId == id) return r;
    }
    return null;
  }

  /// The resolver for [discipline] (via its `expertiseCatalogId`), falling back
  /// to the palette-only [fallback] for unregistered ids.
  static ExpertiseColorResolver forDiscipline(Discipline discipline) =>
      byId(discipline.expertiseCatalogId) ?? fallback;
}
