// Repertoire status -> visual presentation (icon / color / label) SSOT.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §2.2 Tab 2
// C3 (§16): status->visuals live in a presentation extension; widgets must not
// inline the status switch.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/analytics_models.dart';

/// Single source of truth for [RepertoireStatus] icon / color / label.
extension RepertoireStatusVisuals on RepertoireStatus {
  IconData get icon => switch (this) {
    RepertoireStatus.completed => Icons.check_circle,
    RepertoireStatus.inProgress => Icons.play_circle_outline,
    RepertoireStatus.planned => Icons.radio_button_unchecked,
  };

  Color get color => switch (this) {
    RepertoireStatus.completed => AppColors.paperOk,
    RepertoireStatus.inProgress => AppColors.paperAccent,
    RepertoireStatus.planned => AppColors.inkQuaternary,
  };

  String get label => switch (this) {
    RepertoireStatus.completed => AppStrings.analyticsRepertoireStatusCompleted,
    RepertoireStatus.inProgress =>
      AppStrings.analyticsRepertoireStatusInProgress,
    RepertoireStatus.planned => AppStrings.analyticsRepertoireStatusPlanned,
  };
}
