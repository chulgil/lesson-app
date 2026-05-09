// Compact billing plan badge — Notebook × Score design.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/billing_plan.dart';
import '../providers/billing_provider.dart';

/// Displays the current billing plan as a compact badge.
class BillingPlanBadge extends ConsumerWidget {
  const BillingPlanBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAsync = ref.watch(billingStatusNotifierProvider);

    return billingAsync.when(
      data: (status) {
        if (status.isFree) return const SizedBox.shrink();
        return _Badge(status: status);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Badge extends StatelessWidget {
  final BillingStatus status;
  const _Badge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status.planType) {
      BillingPlanType.trialPro => AppStrings.billingTrialBadge,
      BillingPlanType.pro => AppStrings.billingProBadge,
      BillingPlanType.studio => AppStrings.billingStudioBadge,
      BillingPlanType.lifetime => AppStrings.billingLifetimeBadge,
      BillingPlanType.free => 'Free',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.paperAccent, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (status.daysRemaining != null && status.isTrial) ...[
            const SizedBox(width: AppSpacing.space1),
            Text(
              '${status.daysRemaining}일',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
