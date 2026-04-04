import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/subscription.dart';

/// Action box for subscription detail screen — bottom action buttons.
///
/// Shows context-aware actions based on subscription status:
/// - Active: [시간 변경] [취소 요청]
/// - Expired/Depleted: no actions
class SubscriptionActionBox extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  const SubscriptionActionBox({
    super.key,
    required this.subscription,
    this.onReschedule,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // No actions for expired/depleted subscriptions
    if (subscription.isExpired || subscription.isDepleted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Reschedule button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: subscription.canReschedule ? onReschedule : null,
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(
                  subscription.canReschedule
                      ? AppStrings.rescheduleAction
                      : AppStrings.rescheduleDisabled,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: subscription.canReschedule
                        ? AppColors.primary
                        : AppColors.borderLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            // Cancel button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(AppStrings.cancelRequest),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
