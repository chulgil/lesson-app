import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../features/onboarding/onboarding_facade.dart';

/// First-home demo guide shown once after teacher onboarding completion.
class DemoDashboardOverlay extends ConsumerWidget {
  const DemoDashboardOverlay({super.key});

  Future<void> _dismissOverlay(WidgetRef ref) {
    return ref
        .read(onboardingProgressStorageProvider.notifier)
        .dismissDemoOverlay();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(onboardingProgressStorageProvider);

    return progressAsync.maybeWhen(
      data: (progress) {
        if (!progress.teacherOnboardingCompleted ||
            progress.demoOverlayDismissed) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space5),
          child: NotebookCard(
            color: AppColors.paper,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.inkBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.demoDashboardOverlayEyebrow,
                    style: NotebookTypography.sectionLabel,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    AppStrings.demoDashboardOverlayTitle,
                    style: NotebookTypography.pieceTitle,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    AppStrings.demoDashboardOverlayDescription,
                    style: NotebookTypography.handLarge.copyWith(
                      color: AppColors.inkSecondary,
),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _dismissOverlay(ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(
                              color: AppColors.inkQuaternary,
                            ),
                            shape: const RoundedRectangleBorder(),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: Text(
                            AppStrings.demoDashboardOverlayNeverShowAgain,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _dismissOverlay(ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: AppColors.paper,
                            shape: const RoundedRectangleBorder(),
                            minimumSize: const Size.fromHeight(44),
                            elevation: 0,
                          ),
                          child: Text(AppStrings.demoDashboardOverlayConfirm),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
