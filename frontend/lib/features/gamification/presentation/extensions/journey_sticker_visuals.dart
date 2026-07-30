// Presentation-layer visuals for the journey sticker catalog.
//
// flutter-architecture rule: domain enums must not have display getters —
// label/color/glyph logic lives here.
//
// C8 (design-system HARD-GATE): a screen may show at most 3 semantic colors.
// Tier progression within a family is expressed as an ink-opacity ladder
// (same hue, no new hues) instead of 4 distinct tier colors; the single
// Notebook accent (paperAccent) is reserved for "achieved".

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../domain/entities/journey_sticker.dart';

extension JourneyStickerVisuals on JourneySticker {
  /// Korean section label for [family].
  String get familyLabel {
    switch (family) {
      case StickerFamily.practice:
        return AppStrings.journeyStickerFamilyPractice;
      case StickerFamily.journey:
        return AppStrings.journeyStickerFamilyJourney;
      case StickerFamily.streak:
        return AppStrings.journeyStickerFamilyStreak;
      case StickerFamily.growth:
        return AppStrings.journeyStickerFamilyGrowth;
    }
  }

  /// Notebook glyph representing [family] (signature-area rule: glyphs, not
  /// Material icons or emoji).
  String get glyph {
    switch (family) {
      case StickerFamily.practice:
        return NotebookGlyph.note;
      case StickerFamily.journey:
        return NotebookGlyph.trebleClef;
      case StickerFamily.streak:
        return NotebookGlyph.dotFilled;
      case StickerFamily.growth:
        return NotebookGlyph.starFilled;
    }
  }

  /// Ink-opacity ladder for the unachieved ring — bolder at higher tiers,
  /// no new hues introduced.
  Color get tierInkColor {
    switch (tier) {
      case 1:
        return AppColors.inkQuaternary;
      case 2:
        return AppColors.inkTertiary;
      case 3:
        return AppColors.inkSecondary;
      default:
        return AppColors.ink;
    }
  }

  /// Fill/glyph color — the single Notebook accent once achieved, otherwise
  /// the ink-opacity tier ladder.
  Color get displayColor => achieved ? AppColors.paperAccent : tierInkColor;

  /// Progress text formatted per [unit] (e.g. "12/50h", "18/30일", "2/5개").
  String get progressLabel {
    switch (unit) {
      case StickerUnit.minutes:
        return AppStrings.journeyStickerProgressHoursLabel(
          current ~/ 60,
          target ~/ 60,
        );
      case StickerUnit.days:
        return AppStrings.journeyStickerProgressDaysLabel(current, target);
      case StickerUnit.count:
        return AppStrings.journeyStickerProgressCountLabel(current, target);
    }
  }
}
