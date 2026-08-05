// Risk level -> visual presentation (label / color / icon) SSOT.
// #1216 wiring: read-only surfacing of retention_service risk tiers on the
// 월간요약 tab. C3 (§16): status->visuals live in a presentation extension;
// widgets must not inline the risk-level switch.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/analytics_models.dart';

/// Single source of truth for [RiskLevel] label / color / icon.
extension RiskLevelVisuals on RiskLevel {
  String get label => switch (this) {
    RiskLevel.high => AppStrings.analyticsRiskLevelHigh,
    RiskLevel.medium => AppStrings.analyticsRiskLevelMedium,
    RiskLevel.low => AppStrings.analyticsRiskLevelLow,
  };

  Color get color => switch (this) {
    RiskLevel.high => AppColors.paperAccent,
    RiskLevel.medium => AppColors.paperTrial,
    RiskLevel.low => AppColors.paperOk,
  };

  IconData get icon => switch (this) {
    RiskLevel.high => Icons.error_outline,
    RiskLevel.medium => Icons.warning_amber_rounded,
    RiskLevel.low => Icons.info_outline,
  };
}
