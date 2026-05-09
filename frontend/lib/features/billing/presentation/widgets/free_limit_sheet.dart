// Bottom sheet shown when a free-plan teacher tries to add a 6th student.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/billing_provider.dart';

/// Shows a paywall sheet when the free plan student limit is reached.
///
/// Offers two paths:
/// 1. Start 14-day Pro trial (if not already used)
/// 2. View subscription plans
Future<void> showFreeLimitSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLarge),
      ),
    ),
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
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inkQuaternary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.paperAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Title
            Text(
              AppStrings.billingFreeLimitTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space2),

            // Description
            Text(
              AppStrings.billingFreeLimitDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),

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
                      minimumSize: const Size(
                        double.infinity,
                        AppSpacing.buttonHeight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
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
                  // TODO(Phase C): Navigate to subscription plans screen
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    AppSpacing.buttonHeight,
                  ),
                  side: const BorderSide(color: AppColors.inkQuaternary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
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
