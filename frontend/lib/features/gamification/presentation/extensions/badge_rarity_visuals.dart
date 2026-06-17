// Presentation-layer visuals for BadgeRarity (Korean tier labels + accent colors).
//
// flutter-architecture rule: domain enums must not have display getters.
// All label/color logic lives here in the presentation layer.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/gamification.dart';

/// Korean tier label and accent color for a badge rarity.
extension BadgeRarityVisuals on BadgeRarity {
  /// Korean tier label shown beneath each trophy glyph (e.g. '일반', '희귀').
  String get tierLabel {
    switch (this) {
      case BadgeRarity.common:
        return AppStrings.badgeTierCommon;
      case BadgeRarity.rare:
        return AppStrings.badgeTierRare;
      case BadgeRarity.epic:
        return AppStrings.badgeTierEpic;
      case BadgeRarity.legendary:
        return AppStrings.badgeTierLegendary;
    }
  }

  /// Accent color matching the tier (presentation only — not stored in domain).
  Color get tierColor {
    switch (this) {
      case BadgeRarity.common:
        return AppColors.inkTertiary;
      case BadgeRarity.rare:
        return AppColors.levelSilverStart;
      case BadgeRarity.epic:
        return AppColors.levelGoldStart;
      case BadgeRarity.legendary:
        return AppColors.paperAccent;
    }
  }
}
