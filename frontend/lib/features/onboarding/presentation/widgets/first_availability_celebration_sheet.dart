import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';

/// Shows the celebration sheet after the first availability slot is saved
/// (#422). Per spec §4.3 this is a modal sheet with a single CTA that
/// returns the teacher to the quest board.
Future<void> showFirstAvailabilityCelebrationSheet(BuildContext context) {
  return showNotebookModalBottomSheet<void>(
    context: context,
    builder:
        (sheetContext) => const PopScope(
          canPop: false,
          child: FirstAvailabilityCelebrationSheet(),
        ),
  );
}

/// Sheet content widget — exposed for widget smoke testing.
class FirstAvailabilityCelebrationSheet extends StatelessWidget {
  const FirstAvailabilityCelebrationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.firstAvailabilityCelebrationTitle,
              style: NotebookTypography.pieceTitle.copyWith(
                fontSize: 18,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.firstAvailabilityCelebrationDescription,
              style: NotebookTypography.handMedium.copyWith(
color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.firstAvailabilityCelebrationNext,
              style: NotebookTypography.hand.copyWith(
                fontSize: 13,
                color: AppColors.inkTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: const Text(AppStrings.firstAvailabilityCelebrationAction),
            ),
          ],
        ),
      ),
    );
  }
}
