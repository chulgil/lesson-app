// Presentation-only visual variants for `RepertoireHistoryStatus`.
//
// Per `.claude/rules/flutter-architecture.md`, the domain enum stays pure
// (no labels, no colors). All Material/AppStrings binding lives here so
// the timeline widget can render badges without leaking presentation
// dependencies into the entity layer.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/repertoire_history_entry.dart';

/// Display variants for the status badge (§3.4.3 status badge).
extension RepertoireHistoryStatusVisuals on RepertoireHistoryStatus {
  /// Korean badge label rendered next to the repertoire name.
  String get label {
    return switch (this) {
      RepertoireHistoryStatus.inProgress => AppStrings.practiceInProgress,
      RepertoireHistoryStatus.completed => AppStrings.practiceCompletedLabel,
      RepertoireHistoryStatus.archived => AppStrings.archiveButton,
    };
  }

  /// Badge background color.
  Color get badgeBackground {
    return switch (this) {
      RepertoireHistoryStatus.inProgress => AppColors.paperAccentSoft,
      RepertoireHistoryStatus.completed => AppColors.paperOk.withValues(
        alpha: 0.15,
      ),
      RepertoireHistoryStatus.archived => AppColors.inkTertiary.withValues(
        alpha: 0.15,
      ),
    };
  }

  /// Badge text and progress accent color.
  Color get badgeForeground {
    return switch (this) {
      RepertoireHistoryStatus.inProgress => AppColors.paperAccent,
      RepertoireHistoryStatus.completed => AppColors.paperOk,
      RepertoireHistoryStatus.archived => AppColors.inkTertiary,
    };
  }
}
