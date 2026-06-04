import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Entry point button for the quick-recording (바로 녹음) flow.
///
/// Spec: `docs/specs/practice/practice_master.md` §4.3.4.
/// Tap triggers [onPressed] — the caller is responsible for navigating to
/// the default quick-record section via [QuickRecordingService].
class QuickRecordButton extends StatelessWidget {
  const QuickRecordButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
  });

  final VoidCallback onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.quickRecordTooltip,
      button: true,
      enabled: isEnabled,
      child: Tooltip(
        message: AppStrings.quickRecordTooltip,
        child: FilledButton.icon(
          onPressed: isEnabled ? onPressed : null,
          icon: const Icon(Icons.fiber_manual_record, size: 20),
          label: const Text(AppStrings.quickRecordButton),
          style: FilledButton.styleFrom(
            // Override theme-level minimumSize=Size(∞, h) so the button can
            // sit inside compact layouts (Row/Align/Wrap) without forcing
            // unbounded width — see feedback_theme_minsize_infinity.md.
            minimumSize: const Size(0, AppSpacing.buttonHeight),
            backgroundColor: AppColors.paperAccent,
            foregroundColor: AppColors.paper,
            textStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space5,
              vertical: AppSpacing.space2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }
}
