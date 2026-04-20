import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Chapter 1: Subscription info (type, amount, period, reschedule credits).
class SubscriptionChapterInfo extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionChapterInfo({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.M.d');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Column(
        children: [
          _buildRow(AppStrings.subscriptionType, subscription.typeLabel),
          _buildRow(
            AppStrings.amount,
            '${NumberFormat('#,###').format(subscription.amount)}${AppStrings.wonUnit}',
          ),
          if (subscription.discountAmount != null &&
              subscription.discountAmount! > 0)
            _buildRow(
              AppStrings.discount,
              '-${NumberFormat('#,###').format(subscription.discountAmount)}${AppStrings.wonUnit} (${subscription.discountReason ?? ""})',
              valueColor: AppColors.primary,
            ),
          if (subscription.startDate != null)
            _buildRow(
              AppStrings.startDate,
              dateFormat.format(subscription.startDate!),
            ),
          if (subscription.endDate != null)
            _buildRow(
              AppStrings.endDate,
              dateFormat.format(subscription.endDate!),
            ),
          _buildRow(
            AppStrings.rescheduleDeadlineLabel,
            '${subscription.rescheduleDeadlineHours}${AppStrings.hoursUnit}',
          ),
          _buildRow(
            AppStrings.rescheduleLabel,
            AppStrings.rescheduleCount(
              subscription.remainingReschedule,
              subscription.totalRescheduleAllowance,
            ),
            valueColor:
                subscription.remainingReschedule <= 0
                    ? AppColors.error
                    : subscription.remainingReschedule == 1
                    ? AppColors.warning
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
