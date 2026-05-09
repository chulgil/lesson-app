// Compact billing plan badge for profile and app bar display.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/billing_plan.dart';
import '../providers/billing_provider.dart';

/// Displays the current billing plan as a compact badge.
///
/// Shows plan name + remaining days for trials/subscriptions.
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
    final (label, color) = switch (status.planType) {
      BillingPlanType.trialPro => (AppStrings.billingTrialBadge, AppColors.paperTrial),
      BillingPlanType.pro => (AppStrings.billingProBadge, AppColors.paperAccent),
      BillingPlanType.studio => (AppStrings.billingStudioBadge, AppColors.profilePurple),
      BillingPlanType.lifetime => (AppStrings.billingLifetimeBadge, AppColors.amber),
      BillingPlanType.free => ('Free', AppColors.inkTertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (status.daysRemaining != null && status.isTrial) ...[
            const SizedBox(width: AppSpacing.space1),
            Text(
              '${status.daysRemaining}일',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
