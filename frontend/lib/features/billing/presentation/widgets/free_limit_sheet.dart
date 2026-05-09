// Bottom sheet shown when a free-plan teacher tries to add a 6th student.
// Notebook × Score design — paper bg, ink text, straight edges, no rounded icons.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../providers/billing_provider.dart';

/// Shows a paywall sheet when the free plan student limit is reached.
Future<void> showFreeLimitSheet(BuildContext context) {
  return showNotebookModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _FreeLimitSheetBody(),
  );
}

class _FreeLimitSheetBody extends ConsumerWidget {
  const _FreeLimitSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAsync = ref.watch(billingStatusNotifierProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space5),

            // Title with glyph
            Row(
              children: [
                const NotebookGlyph(
                  NotebookGlyph.starFilled,
                  size: 18,
                  color: AppColors.paperAccent,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  AppStrings.billingFreeLimitTitle,
                  style: NotebookTypography.sectionTitle,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            const ThinRule(),
            const SizedBox(height: AppSpacing.space3),

            // Description
            Text(
              AppStrings.billingFreeLimitDescription,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space5),

            // Trial button
            billingAsync.when(
              data: (status) {
                if (status.isTrial || status.isPaid) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await ref
                          .read(billingStatusNotifierProvider.notifier)
                          .startTrial();
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
                      foregroundColor: AppColors.paper,
                      minimumSize: const Size(
                        double.infinity,
                        AppSpacing.buttonHeight,
                      ),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text(AppStrings.billingStartTrial),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: AppSpacing.buttonHeight,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.space3),

            // View plans button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.billingPlans);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(
                    double.infinity,
                    AppSpacing.buttonHeight,
                  ),
                  side: const BorderSide(color: AppColors.inkQuaternary),
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text(AppStrings.billingViewPlans),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ),
      ),
    );
  }
}
