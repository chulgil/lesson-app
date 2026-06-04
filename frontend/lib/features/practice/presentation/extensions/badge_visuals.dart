// Presentation-layer visuals for Badge — labels, icons, color hints.
//
// Lives in presentation/extensions so the domain entity stays free of
// Flutter / l10n dependencies (flutter-architecture rule).

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/badge.dart';

/// Visual descriptor for a [BadgeType].
class BadgeVisual {
  final String name;
  final String description;
  final IconData icon;
  final Color accent;

  const BadgeVisual({
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
  });
}

extension BadgeTypeVisuals on BadgeType {
  BadgeVisual get visual {
    switch (this) {
      case BadgeType.firstPractice:
        return BadgeVisual(
          name: AppStrings.practiceBadgeFirstPracticeName,
          description: AppStrings.practiceBadgeFirstPracticeDesc,
          icon: Icons.music_note,
          accent: AppColors.paperAccent,
        );
      case BadgeType.streak3:
        return BadgeVisual(
          name: AppStrings.practiceBadgeStreak3Name,
          description: AppStrings.practiceBadgeStreak3Desc,
          icon: Icons.local_fire_department_outlined,
          accent: AppColors.paperAccent,
        );
      case BadgeType.streak7:
        return BadgeVisual(
          name: AppStrings.practiceBadgeStreak7Name,
          description: AppStrings.practiceBadgeStreak7Desc,
          icon: Icons.local_fire_department,
          accent: AppColors.paperAccent,
        );
      case BadgeType.streak30:
        return BadgeVisual(
          name: AppStrings.practiceBadgeStreak30Name,
          description: AppStrings.practiceBadgeStreak30Desc,
          icon: Icons.whatshot,
          accent: AppColors.paperAccent,
        );
      case BadgeType.streak100:
        return BadgeVisual(
          name: AppStrings.practiceBadgeStreak100Name,
          description: AppStrings.practiceBadgeStreak100Desc,
          icon: Icons.military_tech,
          accent: AppColors.paperAccent,
        );
      case BadgeType.perfectWeek:
        return BadgeVisual(
          name: AppStrings.practiceBadgePerfectWeekName,
          description: AppStrings.practiceBadgePerfectWeekDesc,
          icon: Icons.event_available,
          accent: AppColors.paperOk,
        );
      case BadgeType.mustMaster:
        return BadgeVisual(
          name: AppStrings.practiceBadgeMustMasterName,
          description: AppStrings.practiceBadgeMustMasterDesc,
          icon: Icons.task_alt,
          accent: AppColors.paperOk,
        );
      case BadgeType.practiceKing:
        return BadgeVisual(
          name: AppStrings.practiceBadgePracticeKingName,
          description: AppStrings.practiceBadgePracticeKingDesc,
          icon: Icons.emoji_events,
          accent: AppColors.paperOk,
        );
      case BadgeType.firstPiece:
        return BadgeVisual(
          name: AppStrings.practiceBadgeFirstPieceName,
          description: AppStrings.practiceBadgeFirstPieceDesc,
          icon: Icons.library_music,
          accent: AppColors.paperTrial,
        );
      case BadgeType.fivePieces:
        return BadgeVisual(
          name: AppStrings.practiceBadgeFivePiecesName,
          description: AppStrings.practiceBadgeFivePiecesDesc,
          icon: Icons.queue_music,
          accent: AppColors.paperTrial,
        );
      case BadgeType.challengeKing:
        return BadgeVisual(
          name: AppStrings.practiceBadgeChallengeKingName,
          description: AppStrings.practiceBadgeChallengeKingDesc,
          icon: Icons.trending_up,
          accent: AppColors.paperTrial,
        );
      case BadgeType.firstLike:
        return BadgeVisual(
          name: AppStrings.practiceBadgeFirstLikeName,
          description: AppStrings.practiceBadgeFirstLikeDesc,
          icon: Icons.favorite_border,
          accent: AppColors.paperMargin,
        );
      case BadgeType.lovedStudent:
        return BadgeVisual(
          name: AppStrings.practiceBadgeLovedStudentName,
          description: AppStrings.practiceBadgeLovedStudentDesc,
          icon: Icons.favorite,
          accent: AppColors.paperMargin,
        );
      case BadgeType.performance:
        return BadgeVisual(
          name: AppStrings.practiceBadgePerformanceName,
          description: AppStrings.practiceBadgePerformanceDesc,
          icon: Icons.star,
          accent: AppColors.paperMargin,
        );
    }
  }
}

extension BadgeCategoryVisuals on BadgeCategory {
  String get label {
    switch (this) {
      case BadgeCategory.consistency:
        return AppStrings.practiceBadgeCategoryConsistency;
      case BadgeCategory.diligence:
        return AppStrings.practiceBadgeCategoryDiligence;
      case BadgeCategory.challenge:
        return AppStrings.practiceBadgeCategoryChallenge;
      case BadgeCategory.special:
        return AppStrings.practiceBadgeCategorySpecial;
    }
  }
}
