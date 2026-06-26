// Presentation-layer visuals for Challenge — icons and display strings.
//
// Lives in presentation/extensions so the domain entity stays free of
// Flutter / l10n dependencies (flutter-architecture rule). Icons are Material
// vectors (no emoji — ux-rules C2).

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/challenge.dart';

extension ActivityTypeVisuals on ActivityType {
  /// Material icon representing the activity (replaces the legacy emoji getter).
  IconData get icon => switch (this) {
    ActivityType.practiceDays => Icons.event,
    ActivityType.practiceMinutes => Icons.timer,
    ActivityType.recordings => Icons.mic,
    ActivityType.lessons => Icons.music_note,
    ActivityType.streak => Icons.local_fire_department,
    ActivityType.pointsEarned => Icons.diamond,
  };
}

extension ChallengePeriodVisuals on ChallengePeriod {
  String get displayName => switch (this) {
    ChallengePeriod.weekly => AppStrings.challengePeriodWeekly,
    ChallengePeriod.monthly => AppStrings.challengePeriodMonthly,
  };
}

extension ChallengeVisuals on Challenge {
  /// Target value with its unit (days / minutes / count / points).
  String get targetDisplay => switch (type) {
    ActivityType.practiceDays => AppStrings.dayCount(targetValue),
    ActivityType.practiceMinutes => AppStrings.durationMinutesValue(
      targetValue,
    ),
    ActivityType.recordings => AppStrings.practiceCountTimes(targetValue),
    ActivityType.lessons => AppStrings.practiceCountTimes(targetValue),
    ActivityType.streak => AppStrings.dayCount(targetValue),
    ActivityType.pointsEarned => AppStrings.challengeTargetPoints(targetValue),
  };
}
