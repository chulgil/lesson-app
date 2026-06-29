import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/analytics/domain/entities/analytics_models.dart';
import 'package:lessonaza/features/analytics/presentation/extensions/repertoire_status_visuals.dart';

void main() {
  group('RepertoireStatusVisuals', () {
    test('completed maps to check icon / paperOk / completed label', () {
      expect(RepertoireStatus.completed.icon, Icons.check_circle);
      expect(RepertoireStatus.completed.color, AppColors.paperOk);
      expect(
        RepertoireStatus.completed.label,
        AppStrings.analyticsRepertoireStatusCompleted,
      );
    });

    test('inProgress maps to play icon / paperAccent / inProgress label', () {
      expect(RepertoireStatus.inProgress.icon, Icons.play_circle_outline);
      expect(RepertoireStatus.inProgress.color, AppColors.paperAccent);
      expect(
        RepertoireStatus.inProgress.label,
        AppStrings.analyticsRepertoireStatusInProgress,
      );
    });

    test('planned maps to unchecked icon / inkQuaternary / planned label', () {
      expect(RepertoireStatus.planned.icon, Icons.radio_button_unchecked);
      expect(RepertoireStatus.planned.color, AppColors.inkQuaternary);
      expect(
        RepertoireStatus.planned.label,
        AppStrings.analyticsRepertoireStatusPlanned,
      );
    });

    test('every status resolves non-null visuals (exhaustive)', () {
      for (final status in RepertoireStatus.values) {
        expect(status.label, isNotEmpty);
      }
    });
  });
}
