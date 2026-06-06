import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';

/// Shows the first-availability interstitial dialog (#422).
///
/// Per `docs/specs/onboarding/teacher_first_availability_setup.md` §4.1
/// this modal has no close button and disables back navigation —
/// the teacher must tap "지금 설정하기" to advance to the simple
/// setup screen. The barrier dismiss is also disabled.
Future<void> showFirstAvailabilityInterstitial(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: const FirstAvailabilityInterstitialDialog(),
      );
    },
  );
}

/// The interstitial dialog content widget.
///
/// Exposed publicly for widget smoke testing — production code should
/// use [showFirstAvailabilityInterstitial].
class FirstAvailabilityInterstitialDialog extends StatelessWidget {
  const FirstAvailabilityInterstitialDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space6,
        vertical: AppSpacing.space6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.firstAvailabilityInterstitialTitle,
              style: NotebookTypography.pieceTitle.copyWith(
                fontSize: 18,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.firstAvailabilityInterstitialDescription,
              style: NotebookTypography.hand.copyWith(
                fontSize: 14,
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton(
              onPressed: () {
                // Dismiss the dialog before navigating so the route
                // stack is clean.
                Navigator.of(context).pop();
                context.push(AppRoutes.teacherFirstAvailability);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: const Text(AppStrings.firstAvailabilityInterstitialAction),
            ),
          ],
        ),
      ),
    );
  }
}
